library(shiny)
library(tidyverse)
library(lubridate)
library(DT) # Ensure this is installed using install.packages("DT")

ui <- fluidPage(
    titlePanel("Vehicle and Treatment Dosage Calculator"),
    sidebarLayout(
        sidebarPanel(
            textInput("project_name", "Project Name"),
            dateRangeInput("experiment_date", "Experiment Date Range"),
            numericInput("total_treatment_days", "Vehicle Treatment Days", value = 1, min = 1),
            numericInput("vehicle_num_mice", "Number of mice in Vehicle Group", value = 10),
            numericInput("vehicle_volume_per_mouse", "Volume per mouse in Vehicle Group (mL)", value = 0.2),
            numericInput("error_term", "Error Term", value = 2, min = 1), # Input for the error term
            numericInput("vehicleDMSO", "DMSO (%)", value = 10),
            numericInput("vehiclePEG", "PEG-300 (%)", value = 40),
            numericInput("vehicleTween", "Tween-20 (%)", value = 5),
            numericInput("vehicleSaline", "Saline (0.9%) (%)", value = 45),
            actionButton("add_group", "Add Treatment Group"),
            actionButton("remove_group", "Remove Treatment Group"),
            div(id = "treatment_groups"),
            downloadButton("downloadData", "Download Data")
        ),
        mainPanel(
            tableOutput("project_info"),
            dataTableOutput("vehicleResults"),
            dataTableOutput("treatmentDoses") # The new table output for treatment doses
        )
    )
)

server <- function(input, output, session) {
    treatment_groups <- reactiveValues(groups = list(), group_names = list())

    observeEvent(input$add_group, {
        group_id <- paste0("group", input$add_group)
        group_name_id <- paste0("group_name_", group_id)
        num_days_id <- paste0("num_days_", group_id)
        treatment_groups$groups[[group_id]] <- TRUE

        insertUI(
            selector = "#treatment_groups",
            where = "beforeEnd",
            ui = div(
                id = group_id,
                textInput(group_name_id, "Treatment Group Name"),
                numericInput(paste0("num_days_", group_id), "Number of Days", value = input$total_treatment_days, min = 1),
                numericInput(paste0("num_mice_", group_id), "Number of Mice", value = 10),
                numericInput(paste0("volume_per_mouse_", group_id), "Volume per Mouse (mL)", value = 0.2),
                numericInput(paste0("avg_weight_", group_id), "Average Weight (kg)", value = 0.025),
                numericInput(paste0("drug1_dose_", group_id), "Drug 1 Desired Dose (mg/kg)", value = 5),
                numericInput(paste0("drug2_dose_", group_id), "Drug 2 Desired Dose (mg/kg)", NA, min = 0), # Optional second drug
                hr(),
                tags$hr()
            )
        )

        treatment_groups$group_names[[group_id]] <- reactive(input[[group_name_id]])
    })

    observeEvent(input$remove_group, {
        if (length(treatment_groups$groups) > 0) {
            last_group <- tail(names(treatment_groups$groups), 1)
            treatment_groups$groups <- treatment_groups$groups[-length(treatment_groups$groups)]
            treatment_groups$group_names <- treatment_groups$group_names[-length(treatment_groups$group_names)]
            removeUI(selector = paste0("#", last_group))
        }
    })

    output$vehicleResults <- renderDataTable({
        volumes <- c(Vehicle = input$vehicle_num_mice * input$vehicle_volume_per_mouse * input$total_treatment_days * input$error_term)
        group_names <- c("Vehicle")

        for (group_id in names(treatment_groups$groups)) {
            num_mice <- input[[paste0("num_mice_", group_id)]] %>%
                na.omit() %>%
                sum()
            volume_per_mouse <- input[[paste0("volume_per_mouse_", group_id)]] %>%
                na.omit() %>%
                sum()
            volumes[group_id] <- num_mice * volume_per_mouse * input$total_treatment_days
            group_names <- c(group_names, treatment_groups$group_names[[group_id]]())
        }

        data_frame <- data.frame(
            Group = group_names,
            DMSO = round(volumes * input$vehicleDMSO / 100, 2),
            PEG300 = round(volumes * input$vehiclePEG / 100, 2),
            Tween20 = round(volumes * input$vehicleTween / 100, 2),
            Saline = round(volumes * input$vehicleSaline / 100, 2)
        )

        DT::datatable(data_frame, options = list(pageLength = 5), rownames = FALSE)
    })

    output$project_info <- renderTable(
        {
            baseline_end <- as.character(format(input$experiment_date[2] - as.integer(input$total_treatment_days) - 1))
            exp_start <- as.character(format(input$experiment_date[2] - as.integer(input$total_treatment_days)))

            data.frame(
                Detail = c("Project Name", "Baseline Date Range", "Experiment Date Range", "Total Treatment Days", "Experiment Days (including harvest day)", "Harvest Day"),
                Value = c(
                    as.character(input$project_name),
                    paste(as.character(format(input$experiment_date[1])), "to", baseline_end),
                    paste(exp_start, "to", format(input$experiment_date[2])),
                    as.character(input$total_treatment_days),
                    as.character(as.integer(difftime(input$experiment_date[2], input$experiment_date[1], units = "days"))),
                    as.character(format(input$experiment_date[2]))
                )
            )
        },
        rownames = FALSE
    )

    output$treatmentDoses <- renderDataTable(
        {
            # Initialize an empty data frame to store the results
            doses_data <- data.frame(
                Group = character(),
                Drug1_Total_mg_required = numeric(),
                Drug2_Total_mg_required = numeric(),
                Total_volume_mL = numeric(),
                stringsAsFactors = FALSE
            )

            # Loop through each treatment group to calculate doses
            for (group_id in names(treatment_groups$groups)) {
                if (group_id != "Vehicle") {
                    group_name <- treatment_groups$group_names[[group_id]]()
                    num_days <- input[[paste0("num_days_", group_id)]]
                    num_mice <- input[[paste0("num_mice_", group_id)]]
                    avg_weight <- input[[paste0("avg_weight_", group_id)]]
                    volume_per_mouse <- input[[paste0("volume_per_mouse_", group_id)]]
                    drug1_dose <- input[[paste0("drug1_dose_", group_id)]]
                    drug2_dose <- input[[paste0("drug2_dose_", group_id)]] %>% replace_na(0)

                    total_volume <- round(num_mice * num_days * volume_per_mouse * input$error_term, 2)
                    drug1_total_mg <- round(drug1_dose * avg_weight * num_mice * num_days * input$error_term, 2)
                    drug2_total_mg <- round(ifelse(is.na(drug2_dose), 0, drug2_dose * avg_weight * num_mice * num_days * input$error_term), 2)

                    doses_data <- rbind(doses_data, data.frame(
                        Group = group_name,
                        Drug1_Total_mg_required = drug1_total_mg,
                        Drug1_mg_mL = drug1_dose * avg_weight / volume_per_mouse,
                        Drug2_Total_mg_required = drug2_total_mg,
                        Drug2_mg_mL = drug2_dose * avg_weight / volume_per_mouse,
                        Total_volume_mL = total_volume
                    ))
                }
            }

            doses_data
        },
        options = list(pageLength = 5),
        rownames = FALSE
    )

    output$downloadData <- downloadHandler(
        filename = function() {
            paste("treatment_data-", Sys.Date(), ".xlsx", sep = "")
        },
        content = function(file) {
            wb <- createWorkbook()
            # Add a sheet with vehicle results
            addWorksheet(wb, "Vehicle Results")
            writeData(wb, "Vehicle Results", x = DT::datatable(isolate(output$vehicleResults())))

            # Add a sheet with treatment doses
            addWorksheet(wb, "Treatment Doses")
            writeData(wb, "Treatment Doses", x = DT::datatable(isolate(output$treatmentDoses())))

            # Save the workbook to the specified file
            saveWorkbook(wb, file, overwrite = TRUE)
        }
    )
}

shinyApp(ui = ui, server = server)
