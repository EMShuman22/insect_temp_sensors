# Insect Sensor Temperatures — Shiny app entry point.
#
# Shiny automatically loads every file in the R/ folder before this file
# runs, so the functions used below are already defined.

library(shiny)

# Load sites and sensors once at startup. If the API can't be reached the
# app still opens, just without any sites on the map.
startup <- load_startup_data()

shinyApp(
  ui = app_ui(),
  server = make_server(
    sites = startup$sites,
    datastreams = startup$datastreams,
    api_ok = startup$ok
  )
)
