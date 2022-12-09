library(tidyverse)
library(googlesheets4)
library(bib2df)

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
  ) %>% 
  select(study, group, country, owe_b, owe_se, owe_lb, owe_ub) %>% 
  arrange(study)

write_csv(owe_database, "mw_owe_database.csv")


# new data version
# bibliography prep
bib_data <- read_sheet(owe_sheet, "papers") %>% 
  select(
    study_id, matches("author_"), year, 
    title, journal, volume, number, pages, url
  ) %>% 
  mutate(across(
    matches("author_"), 
    ~str_replace(.x, ".* ", ""), 
    .names = "{.col}_l"
  )) %>% 
  mutate(
    author = paste(author_1_l, author_2_l, author_3_l, author_4_l, author_5_l, author_6_l),
    author = str_replace_all(author, " NA", ""),
    author = if_else(
      !is.na(author_1) & !is.na(author_2) & is.na(author_3) & is.na(author_4) & is.na(author_5) & is.na(author_6),
      paste(author_1_l, "and", author_2_l),
      author
    ),
    author = paste(author, year)
  ) %>% 
  add_count(author) %>% 
  arrange(author, title) %>% 
  group_by(author) %>% 
  mutate(author = if_else(n == 2, paste0(author, letters[row_number()]), author)) %>%
  ungroup() %>% 
  select(-matches("_l"), -n) %>% 
  rename(author_id = author)
  
# bibtex bibliography
bib_data %>% 
  mutate(
    author = paste(author_1, author_2, author_3, author_4, author_5, author_6, sep = ","),
    author = str_replace_all(author, ",NA", ""),
    author = str_split(author, ",")
  ) %>% 
  select(-matches("author_")) %>% 
  mutate(category = "ARTICLE") %>% 
  rename(CATEGORY = category, BIBTEXKEY = study_id) %>% 
  rename_with(toupper, author|year|title|journal|volume|number|pages|url) %>% 
  df2bib("mw_owe_studies.bib")  

# csv bibliography
bib_data %>% 
  select(-study_id) %>% 
  relocate(author_id) %>% 
  write_csv("mw_owe_studies.csv")

owe_data <- read_sheet(owe_sheet, "estimates") %>% 
  filter(primary == 1) %>% 
  full_join(bib_data, by = "study_id")
  
