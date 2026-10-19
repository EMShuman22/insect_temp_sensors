# Page layout. No logic here; every output is filled in by server.R.

app_ui <- function() {
  shinydashboard::dashboardPage(
    skin = "red",
    shinydashboard::dashboardHeader(title = "Insect Sensor Temperatures"),
    shinydashboard::dashboardSidebar(sidebar_menu()),
    shinydashboard::dashboardBody(
      shinydashboard::tabItems(
        map_tab(),
        summary_tab(),
        sites_tab(),
        about_tab()
      )
    )
  )
}

sidebar_menu <- function() {
  shinydashboard::sidebarMenu(
    id = "tabs",
    shinydashboard::menuItem("Map", tabName = "map", icon = icon("map")),
    shinydashboard::menuItem("Summary Statistics", tabName = "summary",
                             icon = icon("chart-simple")),
    shinydashboard::menuItem("Data", tabName = "sites", icon = icon("table")),
    shinydashboard::menuItem("About", tabName = "about", icon = icon("circle-info"))
  )
}

# ---- Map tab: map, controls, chart and readings table ------------------

map_tab <- function() {
  shinydashboard::tabItem(
    tabName = "map",
    fluidRow(
      shinydashboard::box(title = "Map", width = 12,
                          leaflet::leafletOutput("map", height = 500))
    ),
    fluidRow(
      shinydashboard::box(title = "Location Info", width = 4,
                          tableOutput("site_info")),
      shinydashboard::box(title = "Time frame", width = 4,
                          dateRangeInput("dates", "Select date range:",
                                         start = Sys.Date() - DEFAULT_DAYS,
                                         end = Sys.Date(), width = "100%")),
      shinydashboard::box(title = "Plot Configuration", width = 4,
                          selectInput("sensors", "Select sensors:",
                                      choices = NULL, multiple = TRUE,
                                      width = "100%"))
    ),
    fluidRow(
      shinydashboard::box(title = plot_box_title(), width = 12,
                          plotly::plotlyOutput("ts_plot", height = 400))
    ),
    fluidRow(
      shinydashboard::box(
        title = "Data", width = 12,
        downloadButton("download", "Export selected sensor data"),
        br(), br(),
        DT::DTOutput("readings_table")
      )
    )
  )
}

# Chart title with a button that jumps to the Summary Statistics tab.
plot_box_title <- function() {
  tagList(
    span("Temperature Time Series Plot"),
    actionButton("goto_summary", label = NULL, icon = icon("chart-simple"),
                 title = "Go to Summary Statistics",
                 style = "float: right; margin-top: -5px;")
  )
}

# ---- Other tabs -----------------------------------------------------------

summary_tab <- function() {
  shinydashboard::tabItem(
    tabName = "summary",
    h1("Summary Statistics"),
    p("For the site, sensors and dates selected on the Map tab."),
    DT::DTOutput("summary_table")
  )
}

sites_tab <- function() {
  shinydashboard::tabItem(
    tabName = "sites",
    h1("Location Data"),
    DT::DTOutput("sites_table")
  )
}

about_tab <- function() {
  shinydashboard::tabItem(
    tabName = "about",
    h1("About"),
    p("This app shows insect temperature sensor data from the University of",
      "Wyoming's Insect Temps project. Click a site on the map to load its",
      "sensors, then choose sensors and a date range."),
    p("Data come from the public WYSEaSON SensorThings API:",
      a(API_BASE, href = API_BASE, target = "_blank")),
    p("The project's data policy asks that data be cited with a reference to",
      "the project.")
  )
}
