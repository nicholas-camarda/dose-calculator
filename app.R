library(shiny)
library(tidyverse)
library(DT)
library(openxlsx)

ui <- fluidPage(
    titlePanel("Vehicle and Treatment Dosage Calculator"),
    sidebarLayout(
        sidebarPanel(
            textInput("project_name", "Project Name"),
            dateRangeInput("date_range", "Date Range"),
            numericInput("num_vehicle_mice", "Number of Vehicle Mice", value = 0),
            numericInput("volume_per_mouse", "Volume per Mouse (mL)", value = 0.2),
            numericInput("days_treatment", "Days of Treatment", value = 0),
            numericInput("vehicleDMSO", "DMSO (%)", value = 10),
            numericInput("vehiclePEG", "PEG-300 (%)", value = 40),
            numericInput("vehicleTween", "Tween-20 (%)", value = 5),
            numericInput("vehicleSaline", "Saline (0.9%) (%)", value = 45),
            actionButton("add_group", "Add Treatment Group"),
            actionButton("remove_group", "Remove Treatment Group"),
            div(id = "treatment_groups"),
            downloadButton("download_data", "Download Data")
        ),
        mainPanel(
            DTOutput("vehicleResults"),
            DTOutput("treatmentResults")
        )
    )
)

server <- function(input, output, session) {
    treatment_groups <- reactiveValues(groups = list())

    observeEvent(input$add_group, {
        group_id <- paste0("group", input$add_group)
        treatment_groups$groups[[group_id]] <- group_id

        insertUI(
            selector = "#treatment_groups",
            where = "beforeEnd",
            ui = div(
                id = group_id,
                textInput(paste0("name_", group_id), "Group Name"),
                numericInput(paste0("num_mice_", group_id), "Number of mice", value = 0),
                numericInput(paste0("avg_weight_", group_id), "Average weight (kg)", value = 0),
                numericInput(paste0("desired_dose_", group_id), "Desired dose (mg/kg)", value = 0)
            )
        )
    })

    observeEvent(input$remove_group, {
        if (length(treatment_groups$groups) > 0) {
            last_group <- tail(names(treatment_groups$groups), 1)
            treatment_groups$groups <- treatment_groups$groups[-length(treatment_groups$groups)]
            removeUI(selector = paste0("#", last_group))
        }
    })

    vehicleData <- reactive({
        error_factor <- 2
        total_volume_vehicle <- input$num_vehicle_mice * input$volume_per_mouse * input$days_treatment * error_factor

        data.frame(
            Component = c("DMSO", "PEG-300", "Tween-20", "Saline"),
            Volume = round(total_volume_vehicle * c(input$vehicleDMSO, input$vehiclePEG, input$vehicleTween, input$vehicleSaline) / 100, 2)
        )
    })

    output$vehicleResults <- renderDataTable(
        {
            vehicleData()
        },
        options = list(pageLength = 5, searching = FALSE)
    )

    output$treatmentResults <- renderDataTable(
        {
            results <- lapply(names(treatment_groups$groups), function(group_id) {
                num_mice <- input[[paste0("num_mice_", group_id)]]
                avg_weight <- input[[paste0("avg_weight_", group_id)]]
                desired_dose <- input[[paste0("desired_dose_", group_id)]]
                group_name <- input[[paste0("name_", group_id)]]

                error_factor <- 2
                total_volume <- num_mice * input$volume_per_mouse * input$days_treatment * error_factor
                total_dose_mg <- num_mice * avg_weight * desired_dose * input$days_treatment * error_factor
                dose_ml <- total_dose_mg / total_volume

                data.frame(
                    Group = group_name,
                    "Total Volume (mL)" = round(total_volume, 2),
                    "Total mg required" = round(total_dose_mg, 2),
                    "mg/mL" = round(dose_ml, 2)
                )
            })

            do.call(rbind, results)
        },
        options = list(pageLength = 5, searching = FALSE)
    )

    output$download_data <- downloadHandler(
        filename = function() {
            paste(input$project_name, format(input$date_range[1]), format(input$date_range[2]), ".xlsx", sep = "_")
        },
        content = function(file) {
            wb <- createWorkbook()
            addWorksheet(wb, "Vehicle Components")
            writeData(wb, "Vehicle Components", vehicleData())

            treatment_data <- output$treatmentResults()$data
            addWorksheet(wb, "Treatment Results")
            writeData(wb, "Treatment Results", treatment_data)

            saveWorkbook(wb, file, overwrite = TRUE)
        }
    )
}

shinyApp(ui = ui, server = server)
