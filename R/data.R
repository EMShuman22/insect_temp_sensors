# Loading the data the app needs. Combines api.R (fetching) and tidy.R
# (reshaping), and makes sure the app still starts if the API is down.

# Load all sites and sensors once, when the app starts.
# Returns list(ok, sites, datastreams); on failure ok is FALSE and the
# tables are empty, so the interface still opens.
load_startup_data <- function(project_name = PROJECT_NAME) {
  tryCatch({
    things <- fetch_project_things(project_name)
    list(ok = TRUE,
         sites = things_to_sites(things),
         datastreams = things_to_datastreams(things))
  }, error = function(e) {
    message("Could not load sites from the API: ", conditionMessage(e))
    list(ok = FALSE, sites = empty_sites(), datastreams = empty_datastreams())
  })
}

# Load observations for one sensor; returns an empty table on failure.
load_one_stream <- function(datastream, start_date, end_date) {
  tryCatch({
    raw <- fetch_observations(datastream$datastream_id, start_date, end_date)
    observations_to_df(raw, datastream)
  }, error = function(e) {
    message("Could not load datastream ", datastream$datastream_id, ": ",
            conditionMessage(e))
    empty_observations()
  })
}

# Load observations for several sensors and stack them into one table.
load_observations <- function(datastreams, start_date, end_date) {
  if (nrow(datastreams) == 0) return(empty_observations())
  rows <- split(datastreams, seq_len(nrow(datastreams)))
  do.call(rbind, lapply(rows, load_one_stream, start_date, end_date))
}

# Date range for a site: the full span of its data, with the last
# `days` days selected by default.
default_date_range <- function(datastreams, days = DEFAULT_DAYS) {
  first <- suppressWarnings(min(as.Date(datastreams$first_time), na.rm = TRUE))
  last  <- suppressWarnings(max(as.Date(datastreams$last_time), na.rm = TRUE))
  if (!is.finite(first) || !is.finite(last)) {
    last <- Sys.Date()
    first <- last - days
  }
  list(min = first, max = last, start = max(first, last - days), end = last)
}

# Named vector for the sensor picker: labels shown, datastream IDs as values.
sensor_choices <- function(datastreams) {
  stats::setNames(datastreams$datastream_id, datastreams$sensor)
}
