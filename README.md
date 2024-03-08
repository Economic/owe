# Minimum Wage OWE Repository

The Minimum Wage Own-Wage Elasticity Repository contains a representative estimate of the 
OWE of employment from minimum wage research studies.

This code repository creates the [website](https://economic.github.io/owe/) for the OWE repository, 
where you can [explore](https://economic.github.io/owe/table.html) a table of all the studies, 
[view](https://economic.github.io/owe/documentation.html) the documentation, or 
[download](https://economic.github.io/owe/download.html) the underlying data.

## Archived data

The [website](https://github.com/economic/owe) contains the latest version of the data. 

The main data products are also available in the root of this repository:
* [mw_owe_database.csv](https://github.com/Economic/owe/blob/main/mw_owe_studies.csv) (the OWE repository estimates)
* [mw_owe_studies.bib](https://github.com/Economic/owe/blob/main/mw_owe_studies.bib)
or [mw_owe_studies.csv](https://github.com/Economic/owe/blob/main/mw_owe_studies.csv) (bibliography of studies)

For archived versions of the data, see the Github [releases](https://github.com/Economic/owe/releases) 
and associated [changelog](https://economic.github.io/owe/news.html).

## Building the data and website
If you simply want to use the data and documenation, visit the [website](https://economic.github.io/owe/).

To build the data and website, you will need to use the R package `targets` and quarto.
