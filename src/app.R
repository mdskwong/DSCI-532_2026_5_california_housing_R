library(shiny)
library(bslib)
library(tidyverse)
library(leaflet)
library(sf)
library(scales)

# 1. Data Processing & Global Setup ----------------------------------------
processed_data <- read_csv("../data/processed/housing_with_county.csv") |>
  mutate(median_income_usd = median_income * 10000)

counties_geojson <- st_read("../data/raw/cal_counties.geojson")

# Helper for Map Coloring
house_value_pal <- colorBin(
  palette = c("#2166ac", "#74add1", "#fee090", "#f46d43", "#d73027"),
  domain = processed_data$median_house_value,
  bins = c(0, 100000, 150000, 200000, 300000, Inf)
)

# 2. UI Definition ---------------------------------------------------------
ui <- page_fluid(
  theme = bs_theme(version = 5),
  titlePanel("California Housing Dashboard"),
  
  layout_sidebar(
    sidebar = sidebar(
      width = 300,
      actionButton("reset_button", "Reset All Filters"),
      accordion(
        accordion_panel(
          "House Properties",
          sliderInput("house_val_slider", "Median house value:", 
                      min(processed_data$median_house_value), max(processed_data$median_house_value),
                      value = range(processed_data$median_house_value)),
          sliderInput("age_slider", "House age:", 
                      min(processed_data$housing_median_age), max(processed_data$housing_median_age),
                      value = range(processed_data$housing_median_age)),
          checkboxGroupInput("ocean_checkbox", "Ocean Proximity:",
                             choices = c("<1hr Ocean" = "<1H OCEAN", "Near Ocean" = "NEAR OCEAN", 
                                         "Near Bay" = "NEAR BAY", "Island" = "ISLAND", "Inland" = "INLAND"),
                             selected = c("<1H OCEAN", "NEAR OCEAN", "NEAR BAY")),
          selectizeInput("county_select", "County:", 
                         choices = sort(unique(processed_data$county)), 
                         multiple = TRUE)
        )
      )
    ),
    
    # Main Dashboard Area
    layout_columns(
      col_widths = c(8, 4),
      
      # Column 1: Value Boxes and Map
      layout_columns(
        col_widths = 12,
        row_heights = c("150px", "1fr"),
        layout_column_wrap(
          width = 1/2,
          value_box(
            title = "Median House Value",
            value = textOutput("median_house_val"),
            showcase = bsicons::bs_icon("house")
          ),
          value_box(
            title = "Median Income",
            value = textOutput("median_income_val"),
            showcase = bsicons::bs_icon("cash")
          )
        ),
        card(
          full_screen = TRUE,
          leafletOutput("map", height = "600px")
        )
      ),
      
      # Column 2: Distribution Plots
      layout_column_wrap(
        width = 1,
        card(
          card_header("Distribution"),
          selectInput("dist_var", NULL, choices = c("median_house_value", "median_income_usd")),
          plotOutput("dist_plot", height = "250px")
        )
      )
    )
  )
)

# 3. Server Logic ----------------------------------------------------------
server <- function(input, output, session) {
  
  # Reactive Reset
  observeEvent(input$reset_button, {
    # 1. Reset House Value Slider (Full Range)
    updateSliderInput(session, "house_val_slider", 
                      value = range(processed_data$median_house_value))
    
    # 2. Reset House Age Slider (Full Range)
    updateSliderInput(session, "age_slider", 
                      value = range(processed_data$housing_median_age))
    
    # 3. Reset Ocean Proximity (Original 3 selections)
    updateCheckboxGroupInput(session, "ocean_checkbox", 
                             selected = c("<1H OCEAN", "NEAR OCEAN", "NEAR BAY"))
    
    # 4. Reset County Selection (Clear all)
    updateSelectizeInput(session, "county_select", 
                         selected = character(0))
  })
  
  # Reactive Data Filtering
  filtered_df <- reactive({
    data <- processed_data |>
      filter(
        median_house_value >= input$house_val_slider[1],
        median_house_value <= input$house_val_slider[2],
        ocean_proximity %in% input$ocean_checkbox
      )
    
    if (length(input$county_select) > 0) {
      data <- data |> filter(county %in% input$county_select)
    }
    data
  })
  
  # Map Rendering
  output$map <- renderLeaflet({
    leaflet() |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addProviderTiles(providers$OpenStreetMap, group = "Street Map") |>
      addPolygons(data = counties_geojson, color = "#444", weight = 1, fillOpacity = 0.1) |>
      addLayersControl(baseGroups = c("Street Map", "Satellite"))
  })
  
  observe({
    df <- filtered_df()
    leafletProxy("map", data = df) |>
      clearMarkerClusters() |>
      addCircleMarkers(
        lng = ~longitude, lat = ~latitude,
        radius = 4, color = ~house_value_pal(median_house_value),
        fillOpacity = 0.7, stroke = FALSE,
        clusterOptions = markerClusterOptions(),
        popup = ~paste0("<b>County:</b> ", county, "<br><b>Value:</b> $", comma(median_house_value))
      )
  })
  
  # Distribution Plot (Density Comparison)
  output$dist_plot <- renderPlot({
    ggplot() +
      geom_density(data = processed_data, aes(x = .data[[input$dist_var]]), fill = "#8e6bbd", alpha = 0.2) +
      geom_density(data = filtered_df(), aes(x = .data[[input$dist_var]]), fill = "#9acb5b", alpha = 0.4) +
      theme_minimal() +
      scale_x_continuous(labels = label_dollar(scale = 1e-3, suffix = "k")) +
      labs(x = NULL, y = "Density")
  })
  
  # Value Box Outputs
  output$median_house_val <- renderText({
    df <- filtered_df()
    
    # Handle empty datasets gracefully
    validate(
      need(nrow(df) > 0, "No data")
    )
    
    val <- median(df$median_house_value, na.rm = TRUE)
    paste0("$", comma(round(val)))
  })
  
  output$median_income_val <- renderText({
    df <- filtered_df()
    
    validate(
      need(nrow(df) > 0, "No data")
    )
    
    # Using the median_income_usd column created in global setup
    val_inc <- median(df$median_income_usd, na.rm = TRUE)
    paste0("$", comma(round(val_inc)))
  })
}

shinyApp(ui, server)