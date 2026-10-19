# Turning raw API lists into tidy data frames.

# Return `x`, or `default` when `x` is NULL.
value_or <- function(x, default) {
  if (is.null(x)) default else x
}

# Parse API timestamps like "2025-03-25T13:01:00Z" (fractional seconds allowed).
parse_api_time <- function(x) {
  as.POSIXct(sub("Z$", "", x), format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
}

# Extract the number from a site name like "Red Buttes Plot 10".
plot_number <- function(name) {
  suppressWarnings(as.numeric(sub(".*Plot (\\d+).*", "\\1", name)))
}

# ---- Sites -------------------------------------------------------------

empty_sites <- function() {
  data.frame(thing_id = integer(), name = character(), habitat = character(),
             longitude = numeric(), latitude = numeric(),
             elevation_m = numeric())
}

# One row describing a Thing and its (first) Location.
thing_to_site <- function(thing) {
  location <- thing$Locations[[1]]
  coords <- unlist(location$location$coordinates)
  data.frame(
    thing_id    = thing[["@iot.id"]],
    name        = thing$name,
    habitat     = value_or(location$description, NA_character_),
    longitude   = coords[1],
    latitude    = coords[2],
    elevation_m = value_or(location$properties$elevation, NA_real_)
  )
}

# All Things that have a location, ordered by plot number.
things_to_sites <- function(things) {
  located <- Filter(function(t) length(t$Locations) > 0, things)
  if (length(located) == 0) return(empty_sites())
  sites <- do.call(rbind, lapply(located, thing_to_site))
  sites <- sites[order(plot_number(sites$name), sites$name), ]
  rownames(sites) <- NULL
  sites
}

# ---- Datastreams (one per sensor) ---------------------------------------

empty_datastreams <- function() {
  data.frame(thing_id = integer(), datastream_id = integer(),
             sensor = character(), unit = character(),
             first_time = as.POSIXct(character(), tz = "UTC"),
             last_time = as.POSIXct(character(), tz = "UTC"))
}

# Split a phenomenonTime period "start/end" into two timestamps.
parse_period <- function(period) {
  if (is.null(period)) return(as.POSIXct(c(NA, NA), tz = "UTC"))
  parse_api_time(strsplit(period, "/", fixed = TRUE)[[1]][1:2])
}

# One row describing a Datastream.
datastream_to_row <- function(datastream, thing_id) {
  period <- parse_period(datastream$phenomenonTime)
  data.frame(
    thing_id      = thing_id,
    datastream_id = datastream[["@iot.id"]],
    sensor        = value_or(datastream$properties$alias, datastream$name),
    unit          = value_or(datastream$unitOfMeasurement$symbol, ""),
    first_time    = period[1],
    last_time     = period[2]
  )
}

# All Datastreams for one Thing.
thing_to_datastreams <- function(thing) {
  rows <- lapply(thing$Datastreams, datastream_to_row,
                 thing_id = thing[["@iot.id"]])
  do.call(rbind, rows)
}

# All Datastreams for all Things.
things_to_datastreams <- function(things) {
  rows <- lapply(things, thing_to_datastreams)
  streams <- do.call(rbind, rows)
  if (is.null(streams)) empty_datastreams() else streams
}

# ---- Observations -------------------------------------------------------

empty_observations <- function() {
  data.frame(datastream_id = integer(), sensor = character(),
             timestamp = as.POSIXct(character(), tz = "UTC"),
             temperature = numeric())
}

# Convert raw observations for one datastream into a data frame.
observations_to_df <- function(observations, datastream) {
  if (length(observations) == 0) return(empty_observations())
  times   <- vapply(observations, function(o) o$phenomenonTime, character(1))
  results <- vapply(observations, function(o) as.character(value_or(o$result, NA)),
                    character(1))
  data.frame(
    datastream_id = datastream$datastream_id,
    sensor        = datastream$sensor,
    timestamp     = parse_api_time(times),
    temperature   = suppressWarnings(as.numeric(results))
  )
}
