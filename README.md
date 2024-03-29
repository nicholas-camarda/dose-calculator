# Vehicle and Treatment Dosage Calculator

This Shiny application provides a user-friendly interface for calculating the volumes/dosages of vehicle and treatments for animal experiments. It allows the inclusion of two drugs within a single treatment group, considering the average weight of the animals, the desired dose, the total number of days of each treatment group, and an error term to account for solution loss during preparation.

## Features

- **Dynamic Input for Treatment Groups:** Users can add multiple treatment groups and specify details for each, including the number of mice, the volume per mouse, average weight, and desired dose for up to two drugs. The user can also change the relative amounts of the elments of the vehicle that are incorporated into the final solution. 
- **Error Term Adjustment:** A global error term can be set to scale up the volume calculations to compensate for any losses during the preparation of the solutions.
- **Treatment Days Configuration:** Each treatment group can have a different number of treatment days set independently.
- **Excel Export:** The calculated dosages, along with the treatment group details, can be downloaded as an Excel file for further analysis or record-keeping.

## Usage

Click the URL to access the App here: 

https://nicholas-camarda.shinyapps.io/dose-calculator/

Then, to use the calculator, follow these steps:

1. **Set General Information:**
   - Input the `Project Name`.
   - Choose the `Experiment Date Range`.
   - Enter the `Vehicle Treatment Days` for the vehicle group.

2. **Configure Vehicle Solution:**
   - Specify the number of mice, volume of solution per mouse, and percentages of DMSO, PEG-300, Tween-20, and Saline (0.9%) that make up the vehicle solution.

3. **Adjust Error Term:**
   - Input the `Error Term` to adjust for any losses during solution preparation.

4. **Add Treatment Groups:**
   - Click the "Add Treatment Group" button to create a new group.
   - Fill in the details for each treatment group, including the number of days, number of mice, volume of solution per mouse, average weight of the group, and the desired dose for both drugs (if applicable).

5. **Remove Treatment Groups:**
   - Click the "Remove Treatment Group" button to remove the last added treatment group.

6. **Download Data:**
   - Click the "Download Data" button to save the calculated results as an Excel file.

## Results Display

The application will dynamically display the following information:

- **Project Information Table:** Shows details about the project name, experiment date range, and treatment days.
- **Vehicle Results Table:** Lists the calculated volumes of each component in the vehicle solution for all groups.
- **Treatment Doses Table:** Displays the total milligrams required and the concentration (mg/mL) for each drug in each treatment group.

## Download

The results can be downloaded by clicking on the "Download Data" button, which generates an Excel file with separate sheets for vehicle results and treatment doses.

## License

This project is open-source and available for use and modification as per the project's license.
