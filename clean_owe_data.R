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
# note when emp_b non zero, the above is equal to
# emp_b^2 / wage_b^2 * (emp_se^2 / emp_b^2 + wage_se^2 / wage_b^2)

# bibliography prep
bib_data <- read_sheet(owe_sheet, "papers") %>% 
  select(
    study_id, matches("author_"), year, 
    title, journal, volume, number, pages, url, country
  ) %>% 
  # identify author last names
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
  select(-country) %>% 
  df2bib("mw_owe_studies.bib")  

# csv bibliography
bib_data %>% 
  select(-study_id) %>% 
  relocate(author_id) %>% 
  write_csv("mw_owe_studies.csv")

owe_data_initial <- read_sheet(owe_sheet, "estimates") %>% 
  # use primary, valid estimates only
  mutate(primary = as.character(primary)) %>% 
  filter(primary == "1") %>% 
  # calculate new owe
  calculate_owe(owe_new) %>% 
  # if owe b or se was originally missing, use new calculated owe
  # otherwise stick with spreadsheet owe
  mutate(
    owe_b = if_else(is.na(owe_b), owe_new_b, owe_b),
    owe_se = if_else(is.na(owe_se), owe_new_se, owe_se)
  ) %>% 
  mutate(
    owe_ub = owe_b + 1.96 * owe_se,
    owe_lb = owe_b - 1.96 * owe_se
  ) 

owe_data_refined <- owe_data_initial %>% 
  inner_join(bib_data, by = "study_id") %>% 
  mutate(
    authors = paste(
      author_1, 
      author_2, 
      author_3, 
      author_4, 
      author_5, 
      author_6, 
      sep = ", "
    ),
    authors = str_replace_all(authors, ", NA", ""),
    authors = stringi::stri_replace_last_fixed(authors, ",", " and")
  ) %>% 
  mutate(published = if_else(str_detect(study_id, "_wp$"), 1, 0)) %>% 
  select(
    study = author_id,
    journal,
    owe_b, 
    owe_se, 
    owe_lb, 
    owe_ub,
    group,
    overall,
    country,
    published,
    authors,
    title,
    url,
    source
  ) %>% 
  arrange(study)

write_csv(owe_data_refined, "mw_owe_database.csv")

owe_data_refined

owe_data_refined %>% 
  skimr::skim(owe_b)

owe_data_refined %>% 
  filter(country == "US") %>% 
  skimr::skim(owe_b)

owe_data_refined %>% 
  filter(country == "US", journal != "Working Paper") %>% 
  skimr::skim(owe_b)


# suggested filters
# group of workers: Any group, Overall workforce, Teenagers, Restaurant workers
# country: All countries, US
# study: All studies, published, working paper


