make_qmd_citation_full <- function(authors, year, title, url, version) {
  paste0(
    authors,
    ". ",
    year,
    ". *",
    title,
    "*, Version ",
    version,
    ". <",
    url,
    ">"
  )
}
