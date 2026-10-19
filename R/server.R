# App behaviour. Each block below does one job; the heavy lifting lives in
# data.R, plots.R and stats.R.

# Build the server function around the sites and sensors loaded at startup.
make_server <- function(sites, datastreams, api_ok) {
  function(input, output, session) {

    if (!api_ok) {
      showNotification("Couldn't reach the sensor API, so no sites are shown.",
                       type = "warning", duration = NULL)
    }

    # ---- Selection -------------------------------------------------------

    selected_id <- reactiveVal(NULL)

    observeEvent(input$map_marker_click, {
      selected_id(input$map_marker_click$id)
    })

    selected_site <- reactive({
      req(selected_id())
      sites[sites$thing_id == selected_id(), ]
    })

    site_streams <- reactive({
      req(selected_id())
      datastreams[datastreams$thing_id == selected_id(), ]
    })

    # ---- Reset controls when a new site is clicked -----------------------

    observeEvent(site_streams(), {
      streams <- site_streams()
      range <- default_date_range(streams)

      # Freeze so data isn't loaded with the previous site's settings
      freezeReactiveValue(input, "dates")
      freezeReactiveValue(input, "sensors")

      updateDateRangeInput(session, "dates", start = range$start,
                           end = range$end, min = range$min, max = range$max)
      updateSelectInput(session, "sensors", choices = sensor_choices(streams),
                        selected = streams$datastream_id)
    })

    # ---- Data --------------------------------------------------------------

    dates <- debounce(reactive(input$dates), 800)

    # Readings for every sensor at the site, cached per site and date range
    site_observations <- reactive({
      req(dates())
      withProgress(message = "Loading sensor data...", {
        load_observations(site_streams(), dates()[1], dates()[2])
      })
    }) |> bindCache(selected_id(), dates())

    # Readings for just the chosen sensors
    selected_observations <- reactive({
      if (is.null(selected_id())) return(empty_observations())
      obs <- site_observations()
      obs[obs$datastream_id %in% input$sensors, ]
    })

    # ---- Map ---------------------------------------------------------------

    output$map <- leaflet::renderLeaflet(site_map(sites))

    observeEvent(selected_site(), {
      highlight_site(leaflet::leafletProxy("map"), selected_site())
    })

    # ---- Location info -------------------------------------------------------

    output$site_info <- renderTable({
      validate(need(selected_id(), "Click a site on the map."))
      site <- selected_site()
      data.frame(
        Field = c("Name", "Habitat", "Longitude", "Latitude", "Elevation (m)"),
        Value = c(site$name, site$habitat, round(site$longitude, 5),
                  round(site$latitude, 5), site$elevation_m)
      )
    })

    # ---- Chart ---------------------------------------------------------------

    output$ts_plot <- plotly::renderPlotly({
      if (is.null(selected_id())) {
        return(empty_plot("Click a site on the map to view data"))
      }
      obs <- selected_observations()
      if (nrow(obs) == 0) {
        return(empty_plot("No readings for these sensors and dates"))
      }
      title <- paste0(selected_site()$name, "<br><sup>",
                      dates()[1], " to ", dates()[2], "</sup>")
      temperature_plot(obs, title)
    })

    # ---- Readings table and download -----------------------------------------

    output$readings_table <- DT::renderDT({
      obs <- selected_observations()
      obs$timestamp <- format(obs$timestamp, "%Y-%m-%d %H:%M")
      DT::datatable(obs[, c("sensor", "timestamp", "temperature")],
                    rownames = FALSE,
                    colnames = c("Sensor", "Time (UTC)", "Temperature (°C)"),
                    options = list(pageLength = 10, scrollX = TRUE))
    })

    output$download <- downloadHandler(
      filename = function() {
        site <- if (is.null(selected_id())) "no_site" else selected_site()$name
        paste0(gsub(" ", "_", site), "_", dates()[1], "_to_", dates()[2], ".csv")
      },
      content = function(file) {
        obs <- selected_observations()
        obs$timestamp <- format(obs$timestamp, "%Y-%m-%d %H:%M:%S", tz = "UTC")
        utils::write.csv(obs, file, row.names = FALSE)
      }
    )

    # ---- Summary statistics tab ----------------------------------------------

    output$summary_table <- DT::renderDT({
      obs <- selected_observations()
      validate(need(nrow(obs) > 0,
                    "Select a site and sensors on the Map tab first."))
      DT::datatable(summarise_sensors(obs), rownames = FALSE,
                    options = list(dom = "t", scrollX = TRUE)) |>
        DT::formatRound(c("Min", "Max", "Mean", "Median", "SD"), digits = 2)
    })

    observeEvent(input$goto_summary, {
      shinydashboard::updateTabItems(session, "tabs", selected = "summary")
    })

    # ---- Sites tab ----------------------------------------------------------

    output$sites_table <- DT::renderDT({
      DT::datatable(sites, rownames = FALSE, options = list(pageLength = 25))
    })
  }
}
