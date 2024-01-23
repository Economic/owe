## Load your packages, e.g. library(targets).
source("packages.R")

## Globals
citation_authors <- "Arindrajit Dube and Ben Zipperer"
citation_year <- 2024
citation_title <- "Minimum wage own-wage elasticity repository"
citation_url <- "https://economic.github.io/owe"
data_version <- "0.10.0"
owe_sheet <- "1-uBymldLhp5IsG-qiRmUGDy883ij8vjYdx6YpbHAing"

## Functions
lapply(list.files("R", full.names = TRUE), source)

tar_plan(
  citation_full_md = make_qmd_citation_full(
    citation_authors,
    citation_year,
    citation_title,
    citation_url,
    data_version
  ),
  
  # csv versions of the key google sheets
  tar_file(
    sheet_papers_csv, 
    download_sheet(owe_sheet, "papers", "sheet_papers.csv", data_version)
  ),
  tar_file(
    sheet_estimates_csv, 
    download_sheet(owe_sheet, "estimates", "sheet_estimates.csv", data_version)
  ),
  tar_file(
    sheet_calculations_csv, 
    download_sheet(
      owe_sheet, 
      "detailed_calculations", 
      "sheet_calculations.csv", 
      data_version
    )
  ),
  
  # cleaned bib and owe data
  bib_data = make_bib(sheet_papers_csv),
  owe_data = make_owe_data(sheet_estimates_csv, bib_data, data_version),

  # output files
  tar_file(bib_bibtex_file, make_bib_bibtex(bib_data)),
  tar_file(bib_csv_file, make_bib_csv(bib_data)),
  tar_file(owe_csv_file, make_owe_csv(owe_data)),
  tar_file(owe_csv_tidy_file, make_owe_csv_tidy(owe_data)),

  # website
  tar_quarto(website, execute_params = list(data_version = data_version))
)


