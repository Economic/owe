calculate_owe <- function(.data, x) {
  .data %>% 
    mutate(
      "{{x}}_b" := emp_b / wage_b,
      "{{x}}_se" := sqrt(
        (emp_se^2 / wage_b^2) + 0 + (emp_b^2 * wage_se^2 / wage_b^4)
      )
    )
  # note when emp_b non zero, the above is equal to
  # emp_b^2 / wage_b^2 * (emp_se^2 / emp_b^2 + wage_se^2 / wage_b^2)
}

# grab papers
make_bib <- function(owe_sheet, data_version) {
  gs4_deauth()
  read_sheet(owe_sheet, "papers") %>% 
    select(
      study_id, matches("author_"), year, 
      title, journal, volume, number, pages, url, country
    ) %>% 
    # create published indicator
    mutate(published = if_else(str_detect(study_id, "_wp$"), 0, 1)) %>% 
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
}

# bibtex bibliography
make_bib_bibtex <- function(bib_data) {
  file <- "mw_owe_studies.bib"
  
  bib_data %>% 
    mutate(
      author = paste(author_1, author_2, author_3, author_4, author_5, author_6, sep = ","),
      author = str_replace_all(author, ",NA", ""),
      author = str_split(author, ",")
    ) %>% 
    select(-matches("author_")) %>% 
    mutate(category = if_else(published == 1, "ARTICLE", "TECHREPORT")) %>%
    mutate(type = if_else(published == 0, journal, NA)) %>% 
    rename(CATEGORY = category, BIBTEXKEY = study_id) %>% 
    rename_with(
      toupper, 
      author|year|title|journal|volume|number|pages|url|type
    ) %>% 
    select(-country, -published) %>% 
    df2bib(file)
  
  file
}

# csv bibliography
make_bib_csv <- function(bib_data) {
  file <- "mw_owe_studies.csv"
  
  bib_data %>% 
    select(-study_id) %>% 
    relocate(author_id) %>% 
    write_csv(file)
  
  file
}

make_owe_data <- function(owe_sheet, bib_data, data_version) {
  gs4_deauth()
  
  read_sheet(owe_sheet, "estimates") %>% 
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
    ) %>% 
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
    mutate(data_version = data_version) %>% 
    mutate(across(starts_with("owe_"), ~ round(.x, digits = 3))) %>% 
    mutate(owe_magnitude = case_when(
      owe_b < -0.8 ~ 'Large negative',
      owe_b >= -0.8 & owe_b < -0.4 ~ 'Medium negative',
      owe_b >= -0.4 & owe_b < 0 ~ 'Small negative',
      owe_b >= 0 ~ 'Positive'
    )) %>% 
    mutate(
      group_lower = str_to_lower(group),
      teens = str_detect(group_lower, "teens"),
      restaurants_retail = str_detect(group_lower, "restaurant|retail|grocer")
    ) %>% 
    mutate(across(where(is.logical), as.integer)) %>% 
    select(
      study = author_id,
      study_id,
      owe_b, 
      owe_se, 
      owe_lb, 
      owe_ub,
      owe_magnitude,
      group,
      overall,
      teens,
      restaurants_retail,
      country,
      averaged,
      owe_reported,
      published,
      authors,
      year,
      title,
      journal,
      url,
      source,
      data_version
    ) %>% 
    arrange(study)
}


make_owe_csv <- function(owe_data) {
  file <- "mw_owe_database.csv"
  
  write_csv(owe_data, file)
  
  file
}

make_owe_csv_tidy <- function(owe_data) {
  file <- "mw_owe_database_tidy.csv"
  
  owe_data %>% 
    mutate(across(everything(), as.character)) %>% 
    pivot_longer(-study_id) %>% 
    write_csv(file)
  
  file
}



