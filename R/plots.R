# Map and chart builders. Each function returns a widget and nothing else.

# ---- Map ------------------------------------------------------------------

# Base map with one marker per site and a legend.
site_map <- function(sites) {
  map <- leaflet::leaflet() |> leaflet::addTiles()
  if (nrow(sites) == 0) {
    return(leaflet::setView(map, FALLBACK_VIEW$lng, FALLBACK_VIEW$lat,
                            FALLBACK_VIEW$zoom))
  }
  palette <- leaflet::colorFactor("viridis", levels = sites$name)
  map |>
    leaflet::addCircleMarkers(
      data = sites, lng = ~longitude, lat = ~latitude,
      layerId = ~thing_id, label = ~name,
      radius = 8, color = ~palette(name),
      fillOpacity = 0.8, weight = 1
    ) |>
    leaflet::addLegend("topright", pal = palette, values = sites$name,
                       title = "Sites", opacity = 0.8)
}

# Draw a ring around the selected site (replaces any earlier ring).
highlight_site <- function(map_proxy, site) {
  map_proxy |>
    leaflet::clearGroup("selected") |>
    leaflet::addCircleMarkers(
      lng = site$longitude, lat = site$latitude, group = "selected",
      radius = 14, color = "#d62728", weight = 3, fill = FALSE,
      options = leaflet::pathOptions(interactive = FALSE)
    )
}

# ---- Time series -----------------------------------------------------------

# Blank chart showing a message in place of the title.
empty_plot <- function(message) {
  plotly::plotly_empty(type = "scatter", mode = "lines") |>
    plotly::layout(title = list(text = message, font = list(size = 14)))
}

# One color per sensor, in a fixed order so colors don't jump around.
sensor_colors <- function(sensors) {
  sensors <- sort(unique(sensors))
  stats::setNames(rep_len(SENSOR_COLORS, length(sensors)), sensors)
}

# Line chart of temperature over time, one line per sensor.
temperature_plot <- function(observations, title) {
  plotly::plot_ly(
    observations, x = ~timestamp, y = ~temperature,
    color = ~sensor, colors = sensor_colors(observations$sensor),
    type = "scattergl", mode = "lines"
  ) |>
    plotly::layout(
      title = list(text = title),
      xaxis = list(title = "Time (UTC)"),
      yaxis = list(title = "Temperature (°C)"),
      legend = list(orientation = "h", y = -0.2, x = 0.5, xanchor = "center"),
      hovermode = "x unified"
    )
}
