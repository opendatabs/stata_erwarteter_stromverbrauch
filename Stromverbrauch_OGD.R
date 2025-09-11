library(knitr)
library(data.table)
library(httr)

if (file.exists("Stromverbrauch_productive.R")) {
  #Delete file if it exists
  file.remove("Stromverbrauch_productive.R")
}

knitr::purl("Stromverbrauch_productive.Rmd", output = "Stromverbrauch_productive.R")

original_script <- readLines("Stromverbrauch_productive.R")

modified_script <- gsub("100245_Strom_Wetter.csv", "data/export/100245_Strom_Wetter.csv", original_script, fixed=TRUE)
modified_script <- gsub("renv::snapshot()", "", modified_script, fixed=TRUE)

writeLines(modified_script, "Stromverbrauch_productive.R")

source("Stromverbrauch_productive.R")
