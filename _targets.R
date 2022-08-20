# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Imports ---------------------------------------------------------------------

# Load packages required to define the pipeline
library(targets)

# Load other packages as needed
# library(tarchetypes) 

# Configuration ---------------------------------------------------------------

# Specify the packages that your targets need to run
tar_option_set(
  packages = c(
    "dplyr",
    "httr",
    "jsonlite",
    "lubridate",
    "purrr",
    "readr",
    "stringr",
    "tidyr"), 
  format = "rds" 
)

# tar_make_clustermq() configuration (okay to leave alone)
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone)
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to 
# allow use_targets() to configure tar_make_future() options.

# Load the R scripts with your custom functions
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)

# Source other scripts as needed
# source("other_functions.R") 

# Pipeline --------------------------------------------------------------------

# Replace the target list below with your own
list(
  tar_target(bls_series, fetch_series(), cue = tar_cue(mode = "always")),
  tar_target(bls_files, save_series(bls_series), format = "file")
)