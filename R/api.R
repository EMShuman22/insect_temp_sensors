# Talking to the SensorThings API. These functions only fetch raw JSON;
# turning it into tables happens in tidy.R.

# Send one GET request and return the parsed JSON as nested lists.
sta_get <- function(url, query = list()) {
  response <- httr::GET(url, query = query, httr::timeout(REQUEST_TIMEOUT))
  httr::stop_for_status(response, task = paste("fetch", url))
  text <- httr::content(response, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

# Fetch every page of a collection by following @iot.nextLink.
sta_get_all <- function(url, query = list()) {
  pages <- list()
  page <- sta_get(url, query)
  pages[[1]] <- page$value

  while (!is.null(page[["@iot.nextLink"]])) {
    page <- sta_get(page[["@iot.nextLink"]])
    pages[[length(pages) + 1]] <- page$value
  }
  do.call(c, pages)
}

# Find a project's ID from its name.
fetch_project_id <- function(project_name) {
  projects <- sta_get_all(paste0(API_BASE, "/Projects"))
  names <- vapply(projects, function(p) p$name, character(1))
  match <- projects[names == project_name]
  if (length(match) == 0) stop("Project not found: ", project_name)
  match[[1]][["@iot.id"]]
}

# Fetch a project's Things with their Locations and Datastreams included.
fetch_project_things <- function(project_name) {
  project_id <- fetch_project_id(project_name)
  url <- sprintf("%s/Projects(%s)/Things", API_BASE, project_id)
  sta_get_all(url, query = list(`$expand` = "Locations,Datastreams"))
}

# Fetch one datastream's observations between two dates (end date inclusive).
fetch_observations <- function(datastream_id, start_date, end_date) {
  url <- sprintf("%s/Datastreams(%s)/Observations", API_BASE, datastream_id)
  query <- list(
    `$select`  = "phenomenonTime,result",
    `$filter`  = sprintf("phenomenonTime ge %s and phenomenonTime lt %s",
                         format_api_time(start_date),
                         format_api_time(end_date + 1)),
    `$orderby` = "phenomenonTime asc",
    `$top`     = PAGE_SIZE
  )
  sta_get_all(url, query)
}

# Format a date as the timestamp the API expects, e.g. 2025-03-18T00:00:00Z
format_api_time <- function(date) {
  format(as.POSIXct(as.Date(date), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}
