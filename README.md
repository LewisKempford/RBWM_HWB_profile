# RBWM Health and Wellbeing profile

This profile has been created to provide insights of the health and wellbeing of RBWM's residents. This is a simple profile, using publicly available data.

Git has been used for version control with the repository being hosted here on GitHub. The code has been made public for others to recreate or use code for their own repositories, projects, and/or pieces of work. 

No support will be provided for getting this running. Always happy to collaborate, receive suggestions and answer some questions but direct support is not possible.

Project can be forked for local use. Not accepting contributions for this project, though if you have discovered a major bug or mistake, please feel free to raise this as an issue.

<img width="640" height="360" alt="image" src="https://github.com/user-attachments/assets/306ba1bb-bd68-4c4d-b020-1606a6da15b1" />

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for local use and development.

### Prerequisites

What things you need to have your own version up and running:

* R
* Ideally an Integrated Development Environment for R (such as RStudio).
* Microsoft PowerPoint.
* Data sources you'd like to use.
* phiTools package. The version used is available as part of this repository.
* [phutils](https://github.com/daudi/phutils).
* [fingertipsR](https://github.com/ropensci/fingertipsR)
* [fingertipscharts](https://github.com/dhsc-govuk/fingertipscharts)

### Process

1. Data Collection

Indicators sourced from public datasets such as Fingertips (Office for Health Improvement and Disparities), Department for Transport, and NHS England. Can also include indicators from local data files, sources such as Hospital Episode Statistics and PCMD, etc.
Data types include mostly standard Public Health intelligence statistics including proportions, rates, etc.

2. Data Processing

I tend to individually downloaded and preprocess datasets. This allows for use across multiple projects, rather than holding all datasets in a single project and having to replicate this across different projects.

Data from source is downloaded locally and usually processed into an Rds file or csv file. This sits in a folder named Datasets on SharePoint, but could exist on a OneDrive or a network drive, etc. As long as R can access the location. Using SharePoint, I decided to sync the SharePoint folders to my OneDrive so that I can easily throw R a file path to read files in.

The data.R script preps all indicators to be used and saves in an accessible location to be read in by create_ppt.Rmd. Why? So that the final data frame created can be easily used for any adhoc projects and easily checked for accuracy. 

The process would look something like this for all indicators:
Download data from source to local location -> minimal processing of data (usually no aggregation at this point) -> save as local Rds file -> read Rds into data.R -> do any additional processing/ aggregating -> add to master dataframe (this is created in data.R and will contain all indicators to be used in the profile) -> read into Rmd file -> run data through necessary functions, including plots -> output slide for indicator -> compile all indicator slides -> output PowerPoint slide deck.

3. Profile Compilation

Indicators are grouped thematically in the create_ppt.Rmd script. Comparisons are made against national benchmarks (e.g. England averages). The script takes an empty .pptx file that contains master slides for any slide created in the script. Example .pptx file available in this respository. Slides are created for each indicator and a .pptx is created at the end of the script.

Disclaimer: R markdown (Rmd) file is used for the process of creating the slide deck but it does not actually make much use of an Rmd file. This could be done in an R script but the chunking feature in the Rmd makes for a nice easy layout to use when building in each indicator.

4. Output and Sharing

Final output is a PowerPoint presentation.

### Using the scripts

Project can be forked to local machine using Git or downloaded to local machine via GitHub.

#### data.R

This script processes all data and indicators to be used in the profile. The way I tend to use datasets allows for use across multiple projects, rather than holding all datasets in a single project.

To run this script you will need to go through it changing geography codes and file location paths.

Script is separated using sections for data required to process indicators and a section for each indicator. 

Creates Rds in the specified path location. This Rds is used in the create_ppt.Rmd script.

#### create_ppt.Rmd

File is used to process Rds create in data.R to output slide deck. Contains a settings chunk and then chunks for each slide created.

File also reads in lookups and shape files for different geography levels.

## Built With

* R
  
## Contributing

Not accepting contributions.

## Authors

* **Lewis Kempford** - [CoderLew](https://github.com/CoderLew)

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

* Medway Public Health Intelligence Team (basically a like for like copy of their [profiles](https://www.medway.gov.uk/info/200591/medway_s_joint_strategic_needs_assessment_jsna/1590/area_profiles)
* [Dr Natalie Goldring](https://github.com/NatalieGoldring)

## Further development

Will continue developing phiTools and if an update is asked for this profile I will likely need to make changes in alignment with any development of phiTools. Will also think about having a settings script of some sort for file paths, etc to help with reproduceability outside of RBWM.
