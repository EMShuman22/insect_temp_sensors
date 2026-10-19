# Installs the packages this app needs (only the ones you don't have yet).
# Run once:  source("install.R")

packages <- c("shiny", "shinydashboard", "leaflet", "plotly", "DT",
              "dplyr", "httr", "jsonlite")

missing <- setdiff(packages, rownames(installed.packages()))

if (length(missing) > 0) {
  install.packages(missing)
} else {
  message("All packages are already installed.")
}
