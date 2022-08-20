# Pipeline functions
 
# Replace the contents of this file with your own pipeline functions and then
# update the pipeline in _targets.R.

# Imports ---------------------------------------------------------------------

# Package imports are included in this file for development and testing, but 
# should be commented out when the pipeline is run with tar_make. Every package 
# that is used within scripts in the R directory should be specified with 
# tar_options_set in _targets.R. This ensures the packages are loaded during a 
# pipeline run.

# library("dplyr")
# library("httr")
# library("jsonlite")
# library("lubridate")
# library("purrr")
# library("readr")
# library("stringr")
# library("tidyr")

# Constants -------------------------------------------------------------------

BLS_API_URL <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"
SERIES_DATA_FILE <- file.path("data", "series-data.csv")

# Functions -------------------------------------------------------------------

load_series_data <- function() {
  read_csv(
    SERIES_DATA_FILE,
    col_types = cols(
      series_id = col_character(),
      series_name = col_character(),
      description = col_character()))
}

get_series_ids <- function(series_json) {
  map_chr(series_json, function(s) s$seriesID)
}

get_series_tibble <- function(series_json) {
  series_id <- series_json$seriesID
  map_dfr(series_json$data, function(data) {
    tibble(
      series_id = series_id,
      year = as.double(data$year),
      period = data$period,
      period_name = data$periodName,
      date = ym(str_glue("{year} {period_name}")),
      value = data$value,
      created_at = as_datetime(format_ISO8601(Sys.time())))
  })
}

# Target functions ------------------------------------------------------------

fetch_series <- function() {
  
  # Load series data
  series_data <- load_series_data()
  
  # Set request parameters
  headers <- add_headers("Content-Type" = "application/json")
  
  body <- list(
    seriesid = series_data$series_id, 
    startyear = "2019",
    endyear = "2022",
    catalog = FALSE,
    calculations = FALSE,
    annualaverage = FALSE,
    aspects = FALSE,
    registrationkey = Sys.getenv("BLS_API_KEY"))
  
  # Send request
  tryCatch({
    response <- POST(
      BLS_API_URL,
      headers,
      body = body,
      encode = "json",
      timeout = 60)},
    error = function(c) {
      stop("Could not connect to api")
    })
  
  # Get response text
  response_text <- content(
    response, 
    as = "text", 
    encoding = "utf-8")

  # Check the response
  if (response$status_code != 200) {
    stop(str_glue(
      "The server responded with the error message: {response_text}"))
  }  

  # Convert JSON
  response <- fromJSON(response_text, simplifyVector = FALSE)
  
  # Extract series ids as tibbles
  series_ids <- get_series_ids(response$Results$series)
  
  # Extract series as tibbles
  bls_series <- map(response$Results$series, function(series) {
    get_series_tibble(series) |> 
      left_join(series_data, by = "series_id") |> 
      select(
        series_id, 
        series_name, 
        description,
        year,
        period,
        period_name,
        date,
        value,
        created_at) |> 
      arrange(date)
  }) |> set_names(series_ids)
  
  # Return series as a named list
  bls_series
}

save_series <- function(bls_series) {
  
  # Save each series
  bls_files <- imap_chr(bls_series, function(series, series_name) {
    filename <- str_glue("{series_name}.csv")
    filepath <- file.path("dist", filename)
    write_csv(series, filepath)
    filepath
  })
  
  # Return the filepaths
  bls_files
}