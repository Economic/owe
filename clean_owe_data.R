library(tidyverse)
library(googlesheets4)

gs4_deauth()
owe_sheet <- "1-uBymldLhp5IsG-qiRmUGDy883ij8vjYdx6YpbHAing"

calculate_owe <- function(.data, x) {
  .data %>% 
    mutate(
      "{{x}}_b" := emp_b / wage_b,
      "{{x}}_se" := sqrt(
        (emp_se^2 / wage_b^2) + 0 + (emp_b^2 * wage_se^2 / wage_b^4)
      )
    )
}

dube_original <- read_sheet(owe_sheet, "dube_original") %>% 
  rename_with(tolower) %>% 
  filter(!is.na(study)) %>% 
  rename(owe_b = coefficient, owe_se = `standard error`) %>% 
  select(study, owe_b, owe_se, country, group) %>% 
  mutate(source = "dube_original")

ns_review <- read_sheet(owe_sheet, "ns_included_excluded") %>% 
  rename_with(tolower) %>% 
  filter(admissible == "Y") %>% 
  mutate(study = paste(author, year)) %>% 
  calculate_owe(owe_new) %>% 
  mutate(
    owe_b = if_else(is.na(owe_b), owe_new_b, owe_b),
    owe_se = if_else(is.na(owe_se), owe_new_se, owe_se)
  ) %>% 
  select(study, owe_b, owe_se, country, group) %>% 
  mutate(source = "ns_review")

new_additions <- read_sheet(owe_sheet, "new_additions") %>% 
  rename_with(tolower) %>% 
  filter(admissible == "Y") %>% 
  mutate(study = paste(author, year)) %>% 
  calculate_owe(owe_new) %>% 
  mutate(
    owe_b = if_else(is.na(owe_b), owe_new_b, owe_b),
    owe_se = if_else(is.na(owe_se), owe_new_se, owe_se)
  ) %>% 
  select(study, owe_b, owe_se, country, group) %>% 
  mutate(source = "new_additions")

owe_database <- bind_rows(dube_original, ns_review, new_additions) %>% 
  mutate(
    owe_ub = owe_b + 1.96 * owe_se,
    owe_lb = owe_b - 1.96 * owe_se
  )

write_csv(owe_database, "mw_owe_database.csv")
  