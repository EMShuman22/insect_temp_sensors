# Insect Sensor Temperatures

A Shiny dashboard for the University of Wyoming **Insect Temps** sensor
network. Click a site on the map to see its temperature sensors, pick sensors
and a date range, and view the readings as a chart, a table, and summary
statistics. Data come live from the public
[WYSEaSON SensorThings API](https://wyseason.uwyo.edu/sta/v1.1); no login is
needed.

## Requirements

- R 4.1 or newer
- Internet access to `wyseason.uwyo.edu`

## Running it

1. Open R (or RStudio) in this folder.
2. Install the packages (first time only):

   ```r
   source("install.R")
   ```

3. Start the app:

   ```r
   shiny::runApp()
   ```

   In RStudio you can also open `app.R` and click **Run App**.

The app opens in your browser. If the API can't be reached, the app still
starts and shows a warning, with an empty map.

## Using it

1. **Map tab:** click a site. The last 7 days of its data load, and all its
   sensors are selected.
2. Change the **Time frame** or **Sensors** to update the chart and table.
3. **Export selected sensor data** downloads what's in the table as a CSV.
4. The chart button (top right of the plot) jumps to **Summary Statistics**.
5. The **Data** tab lists every site and its coordinates.

Sensors record every minute, so long date ranges take a while to load.
Ranges you've already loaded are cached and reappear instantly.

## Project layout

```
app.R          Starts the app: loads sites, then builds the UI and server
install.R      Installs required packages
R/config.R     Settings (API address, project name, default days, colors)
R/api.R        Fetches raw JSON from the SensorThings API
R/tidy.R       Turns raw JSON into data frames (sites, sensors, readings)
R/data.R       Loads data for the app, with fallbacks if the API is down
R/stats.R      Summary statistics table
R/plots.R      Map and chart builders
R/ui.R         Page layout
R/server.R     App behaviour (selection, loading, outputs)
```

Shiny loads everything in `R/` automatically before `app.R` runs.

## Changing settings

Edit `R/config.R`. For example, set `DEFAULT_DAYS <- 30` to load a month of
data when a site is clicked, or change `PROJECT_NAME` to display another
WYSEaSON project.

## Data citation

The project's data policy asks that data be cited with a reference to the
project.
