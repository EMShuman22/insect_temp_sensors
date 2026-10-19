# Summary statistics for the Summary Statistics tab.

# One row per sensor: count, min, max, mean, median and standard deviation.
summarise_sensors <- function(observations) {
  observations |>
    dplyr::filter(!is.na(temperature)) |>
    dplyr::group_by(Sensor = sensor) |>
    dplyr::summarise(
      Readings = dplyr::n(),
      From     = format(min(timestamp), "%Y-%m-%d %H:%M"),
      To       = format(max(timestamp), "%Y-%m-%d %H:%M"),
      Min      = min(temperature),
      Max      = max(temperature),
      Mean     = mean(temperature),
      Median   = stats::median(temperature),
      SD       = stats::sd(temperature),
      .groups  = "drop"
    )
}
