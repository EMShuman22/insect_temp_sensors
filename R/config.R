# Settings for the app. Change values here, not inside the code.

API_BASE        <- "https://wyseason.uwyo.edu/sta/v1.1"  # SensorThings API
PROJECT_NAME    <- "Insect Temps"                          # project to display
DEFAULT_DAYS    <- 7    # days of data loaded when a site is clicked
REQUEST_TIMEOUT <- 30   # seconds before an API request gives up
PAGE_SIZE       <- 10000  # observations requested per API page

# Line colors for sensors (reused in order for each site)
SENSOR_COLORS <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
                   "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")

# Map view used when no sites could be loaded (Wyoming)
FALLBACK_VIEW <- list(lng = -107.5, lat = 43, zoom = 6)
