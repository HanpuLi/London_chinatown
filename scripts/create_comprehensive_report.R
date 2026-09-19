# Create Comprehensive London Chinatown Food Analysis Report
library(dplyr)
library(ggplot2)
library(leaflet)
library(htmlwidgets)
library(gridExtra)
library(RColorBrewer)
library(sf)
library(knitr)
library(rmarkdown)

cat("=== Creating Comprehensive London Chinatown Food Analysis Report ===\n")

build_dir <- Sys.getenv("LONDON_CHINATOWN_BUILD_DIR", unset = "build")
report_folder <- file.path(build_dir, "report")
dir.create(report_folder, recursive = TRUE, showWarnings = FALSE)

# Read the classified data produced by the first two pipeline stages.
data <- read.csv(file.path(build_dir, "food_data.csv"), stringsAsFactors = FALSE)
cat("Fixed food data loaded:", nrow(data), "records\n")

# Read the versioned geographic boundaries.
kml_buffer <- st_read("geographic/kml_50m_buffer.geojson", quiet = TRUE)
kml_original <- st_read("geographic/kml_original.geojson", quiet = TRUE)

# Define colors
colors <- c("Chinese/Chinese Heritage" = "#FF6B6B", "Other Asian" = "#4ECDC4", "Other" = "#45B7D1")
data$color <- colors[data$culture_fixed]

# 1. Create Enhanced Pie Chart
create_enhanced_pie_chart <- function() {
  culture_counts <- table(data$culture_fixed)
  culture_percentages <- round(prop.table(culture_counts) * 100, 1)
  
  culture_data <- data.frame(
    culture = names(culture_counts),
    count = as.numeric(culture_counts),
    percentage = culture_percentages
  )
  
  pie_chart <- ggplot(culture_data, aes(x = "", y = count, fill = culture)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    theme_void() +
    labs(title = "Cultural Background Distribution - London Chinatown Food & Beverage",
         subtitle = paste("Analysis of", nrow(data), "food & beverage establishments within KML polygon + 50m buffer"),
         fill = "Cultural Background") +
    scale_fill_manual(values = colors) +
    theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 14),
          legend.position = "bottom",
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 14, face = "bold")) +
    geom_text(aes(label = paste(culture, "\n", count, "establishments\n(", round(count/sum(count)*100, 1), "%)")), 
              position = position_stack(vjust = 0.5), size = 4.5, color = "white", fontface = "bold")
  
  return(pie_chart)
}

# 2. Create Enhanced Cuisine Bar Chart
create_enhanced_cuisine_bar <- function() {
  cuisine_counts <- table(data$cuisine_fixed, useNA = 'ifany')
  cuisine_percentages <- round(prop.table(cuisine_counts) * 100, 1)
  
  cuisine_data <- data.frame(
    cuisine = names(cuisine_counts),
    count = as.numeric(cuisine_counts),
    percentage = cuisine_percentages
  )
  
  # Remove NA for better visualization
  cuisine_data <- cuisine_data[!is.na(cuisine_data$cuisine), ]
  
  # Create color palette
  n_cuisines <- nrow(cuisine_data)
  cuisine_colors <- colorRampPalette(c("#FF6B6B", "#4ECDC4", "#45B7D1", "#98D8C8", "#87CEEB"))(n_cuisines)
  
  bar_chart <- ggplot(cuisine_data, aes(x = reorder(cuisine, count), y = count, fill = cuisine)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    labs(title = "Cuisine Distribution - London Chinatown Food & Beverage",
         subtitle = paste("Analysis of", nrow(data), "establishments with cleaned and merged cuisine classifications"),
         x = "Cuisine Type", y = "Number of Establishments") +
    scale_fill_manual(values = cuisine_colors) +
    theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 14),
          legend.position = "none",
          axis.text.y = element_text(size = 12),
          axis.text.x = element_text(size = 12),
          axis.title = element_text(size = 14, face = "bold")) +
    geom_text(aes(label = paste(count, "establishments\n(", round(count/sum(count)*100, 1), "%)")), 
              hjust = -0.1, size = 3.5, fontface = "bold")
  
  return(bar_chart)
}

# 3. Create Business Type Distribution Chart
create_business_type_chart <- function() {
  # Combine amenity and shop data
  business_types <- c()
  for (i in 1:nrow(data)) {
    if (!is.na(data$amenity[i]) && data$amenity[i] != "") {
      business_types <- c(business_types, data$amenity[i])
    } else if (!is.na(data$shop[i]) && data$shop[i] != "") {
      business_types <- c(business_types, data$shop[i])
    } else {
      business_types <- c(business_types, "Food & Beverage")
    }
  }
  
  type_counts <- table(business_types)
  type_percentages <- round(prop.table(type_counts) * 100, 1)
  
  type_data <- data.frame(
    type = names(type_counts),
    count = as.numeric(type_counts),
    percentage = type_percentages
  )
  
  # Create color palette
  n_types <- nrow(type_data)
  type_colors <- colorRampPalette(c("#FF6B6B", "#4ECDC4", "#45B7D1", "#98D8C8", "#87CEEB", "#DDA0DD"))(n_types)
  
  type_chart <- ggplot(type_data, aes(x = reorder(type, count), y = count, fill = type)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    labs(title = "Business Type Distribution - London Chinatown Food & Beverage",
         subtitle = paste("Analysis of", nrow(data), "establishments by business type"),
         x = "Business Type", y = "Number of Establishments") +
    scale_fill_manual(values = type_colors) +
    theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 14),
          legend.position = "none",
          axis.text.y = element_text(size = 12),
          axis.text.x = element_text(size = 12),
          axis.title = element_text(size = 14, face = "bold")) +
    geom_text(aes(label = paste(count, "establishments\n(", round(count/sum(count)*100, 1), "%)")), 
              hjust = -0.1, size = 3.5, fontface = "bold")
  
  return(type_chart)
}

# 4. Create Enhanced Interactive Map
create_enhanced_interactive_map <- function() {
  cat("Creating enhanced interactive map...\n")
  
  map <- leaflet(data) %>%
    addTiles() %>%
    
    # Add the original KML polygon (thin line)
    addPolygons(
      data = kml_original,
      fillColor = "transparent",
      color = "#FF6B6B",
      weight = 3,
      opacity = 1,
      fillOpacity = 0,
      popup = "Original KML Polygon"
    ) %>%
    
    # Add the 50m buffered polygon (thick line with fill)
    addPolygons(
      data = kml_buffer,
      fillColor = "transparent",
      color = "#FF6B6B",
      weight = 5,
      opacity = 1,
      fillOpacity = 0.05,
      popup = "50m Buffer Zone"
    ) %>%
    
    # Add Chinese/Chinese Heritage businesses (larger markers)
    addCircleMarkers(
      data = data[data$culture_fixed == "Chinese/Chinese Heritage", ],
      lng = ~lng, lat = ~lat,
      radius = 15,
      color = "#FF6B6B",
      fillColor = "#FF6B6B",
      fillOpacity = 0.9,
      stroke = TRUE,
      weight = 3,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 350px;'>",
        "<h3 style='color: #FF6B6B; margin: 0 0 10px 0;'>🏮 ", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #FF6B6B; font-weight: bold;'>", culture_fixed, "</span></p>",
        ifelse(!is.na(cuisine_fixed) & cuisine_fixed != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_fixed, "</p>"), ""),
        ifelse(!is.na(name.zh) & name.zh != "", 
               paste0("<p><strong>Chinese Name:</strong> ", name.zh, "</p>"), ""),
        ifelse(!is.na(brand) & brand != "", 
               paste0("<p><strong>Brand:</strong> ", brand, "</p>"), ""),
        "<p><strong>Coordinates:</strong> ", round(lat, 6), ", ", round(lng, 6), "</p>",
        "</div>"
      )
    ) %>%
    
    # Add Other Asian businesses (medium markers)
    addCircleMarkers(
      data = data[data$culture_fixed == "Other Asian", ],
      lng = ~lng, lat = ~lat,
      radius = 12,
      color = "#4ECDC4",
      fillColor = "#4ECDC4",
      fillOpacity = 0.8,
      stroke = TRUE,
      weight = 2,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 350px;'>",
        "<h3 style='color: #4ECDC4; margin: 0 0 10px 0;'>🍜 ", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #4ECDC4; font-weight: bold;'>", culture_fixed, "</span></p>",
        ifelse(!is.na(cuisine_fixed) & cuisine_fixed != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_fixed, "</p>"), ""),
        "<p><strong>Coordinates:</strong> ", round(lat, 6), ", ", round(lng, 6), "</p>",
        "</div>"
      )
    ) %>%
    
    # Add Other businesses (smaller markers)
    addCircleMarkers(
      data = data[data$culture_fixed == "Other", ],
      lng = ~lng, lat = ~lat,
      radius = 8,
      color = "#45B7D1",
      fillColor = "#45B7D1",
      fillOpacity = 0.7,
      stroke = TRUE,
      weight = 2,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 350px;'>",
        "<h3 style='color: #45B7D1; margin: 0 0 10px 0;'>", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #45B7D1; font-weight: bold;'>", culture_fixed, "</span></p>",
        ifelse(!is.na(cuisine_fixed) & cuisine_fixed != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_fixed, "</p>"), ""),
        "<p><strong>Coordinates:</strong> ", round(lat, 6), ", ", round(lng, 6), "</p>",
        "</div>"
      )
    ) %>%
    
    # Add legend
    addLegend(
      position = "bottomright",
      colors = colors,
      labels = c(paste("Chinese/Chinese Heritage (", sum(data$culture_fixed == "Chinese/Chinese Heritage"), ")"),
                 paste("Other Asian (", sum(data$culture_fixed == "Other Asian"), ")"),
                 paste("Other (", sum(data$culture_fixed == "Other"), ")")),
      title = "Cultural Background Distribution",
      opacity = 0.8
    ) %>%
    
    # Add title and control panel
    addControl(
      html = paste0("<div style='background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.3); max-width: 400px;'>
                <h2 style='margin: 0 0 15px 0; color: #FF6B6B; text-align: center;'>🍜 London Chinatown</h2>
                <p style='margin: 5px 0; text-align: center; color: #333; font-size: 16px;'><strong>Food & Beverage Analysis</strong></p>
                <hr style='margin: 15px 0;'>
                <p style='margin: 8px 0; font-size: 15px;'><strong>Total:</strong> ", nrow(data), " food & beverage establishments</p>
                <p style='margin: 8px 0; font-size: 15px; color: #FF6B6B;'><strong>Chinese/Chinese Heritage:</strong> ", sum(data$culture_fixed == 'Chinese/Chinese Heritage'), " (", round(prop.table(table(data$culture_fixed))['Chinese/Chinese Heritage'] * 100, 1), "%)</p>
                <p style='margin: 8px 0; font-size: 15px; color: #4ECDC4;'><strong>Other Asian:</strong> ", sum(data$culture_fixed == 'Other Asian'), " (", round(prop.table(table(data$culture_fixed))['Other Asian'] * 100, 1), "%)</p>
                <p style='margin: 8px 0; font-size: 15px; color: #45B7D1;'><strong>Other:</strong> ", sum(data$culture_fixed == 'Other'), " (", round(prop.table(table(data$culture_fixed))['Other'] * 100, 1), "%)</p>
                <hr style='margin: 15px 0;'>
                <p style='margin: 5px 0; font-size: 12px; color: #666;'>Boundary: KML coordinates + 50m buffer | Real OSM coordinates | Food & beverage only | Analysis Date: October 10, 2025</p>
              </div>"),
      position = "topleft"
    ) %>%
    
    # Set view to Chinatown area
    setView(lng = -0.1305, lat = 51.5115, zoom = 17)
  
  return(map)
}

# 5. Calculate Diversity Indices
calculate_diversity_indices <- function() {
  calculate_simpson_diversity <- function(categories) {
    if (length(categories) == 0) return(0)
    category_counts <- table(categories)
    total <- sum(category_counts)
    if (total == 0) return(0)
    simpson_index <- 1 - sum((category_counts / total)^2)
    return(simpson_index)
  }
  
  calculate_shannon_diversity <- function(categories) {
    if (length(categories) == 0) return(0)
    category_counts <- table(categories)
    total <- sum(category_counts)
    if (total == 0) return(0)
    proportions <- category_counts / total
    shannon_index <- -sum(proportions * log(proportions))
    return(shannon_index)
  }
  
  culture_simpson <- calculate_simpson_diversity(data$culture_fixed)
  culture_shannon <- calculate_shannon_diversity(data$culture_fixed)
  cuisine_simpson <- calculate_simpson_diversity(data$cuisine_fixed[!is.na(data$cuisine_fixed)])
  cuisine_shannon <- calculate_shannon_diversity(data$cuisine_fixed[!is.na(data$cuisine_fixed)])
  
  return(list(
    culture_simpson = culture_simpson,
    culture_shannon = culture_shannon,
    cuisine_simpson = cuisine_simpson,
    cuisine_shannon = cuisine_shannon
  ))
}

# Execute all visualizations
cat("Creating all visualizations...\n")

# Create charts
pie_chart <- create_enhanced_pie_chart()
bar_chart <- create_enhanced_cuisine_bar()
type_chart <- create_business_type_chart()
map <- create_enhanced_interactive_map()

# Calculate diversity indices
diversity <- calculate_diversity_indices()

# Save all files to the report folder created at startup.
# Save charts
ggsave(file.path(report_folder, "cultural_background_distribution.png"), pie_chart, width = 12, height = 10, dpi = 300)
ggsave(file.path(report_folder, "cuisine_distribution.png"), bar_chart, width = 14, height = 10, dpi = 300)
ggsave(file.path(report_folder, "business_type_distribution.png"), type_chart, width = 14, height = 10, dpi = 300)

# Save interactive map
saveWidget(map, file.path(report_folder, "interactive_map.html"), selfcontained = FALSE)

# Copy versioned data and current pipeline sources into the generated report.
file.copy(file.path(build_dir, "food_data.csv"), file.path(report_folder, "food_data.csv"), overwrite = TRUE)
file.copy("data/all_osm_rawdata.csv", file.path(report_folder, "all_osm_rawdata.csv"), overwrite = TRUE)

file.copy("scripts/data_cleaning_script.R", file.path(report_folder, "data_cleaning_script.R"), overwrite = TRUE)
file.copy("scripts/cuisine_fix_script.R", file.path(report_folder, "cuisine_fix_script.R"), overwrite = TRUE)
file.copy("scripts/visualization_script.R", file.path(report_folder, "visualization_script.R"), overwrite = TRUE)

file.copy("geographic/kml_original.geojson", file.path(report_folder, "kml_original.geojson"), overwrite = TRUE)
file.copy("geographic/kml_50m_buffer.geojson", file.path(report_folder, "kml_50m_buffer.geojson"), overwrite = TRUE)

cat("\n=== Comprehensive Report Created Successfully ===\n")
cat("Report folder:", report_folder, "\n")
cat("Generated files:\n")
cat("- cultural_background_distribution.png - Cultural background pie chart\n")
cat("- cuisine_distribution.png - Cuisine distribution bar chart\n")
cat("- business_type_distribution.png - Business type distribution chart\n")
cat("- interactive_map.html - Interactive map with all establishments\n")
cat("- food_data.csv - Cleaned food & beverage data\n")
cat("- all_osm_rawdata.csv - All OSM raw data\n")
cat("- data_cleaning_script.R - Data cleaning R script\n")
cat("- cuisine_fix_script.R - Cuisine classification fix script\n")
cat("- visualization_script.R - Visualization creation script\n")
cat("- kml_original.geojson - Original KML boundary\n")
cat("- kml_50m_buffer.geojson - 50m buffered KML boundary\n")

# Print summary statistics
cat("\n=== Final Analysis Summary ===\n")
cat("Total food & beverage establishments:", nrow(data), "\n")
cat("Chinese/Chinese Heritage:", sum(data$culture_fixed == "Chinese/Chinese Heritage"), "(", round(prop.table(table(data$culture_fixed))["Chinese/Chinese Heritage"] * 100, 1), "%)\n")
cat("Other Asian:", sum(data$culture_fixed == "Other Asian"), "(", round(prop.table(table(data$culture_fixed))["Other Asian"] * 100, 1), "%)\n")
cat("Other:", sum(data$culture_fixed == "Other"), "(", round(prop.table(table(data$culture_fixed))["Other"] * 100, 1), "%)\n")
cat("Cultural Simpson Diversity Index:", round(diversity$culture_simpson, 3), "\n")
cat("Cultural Shannon Diversity Index:", round(diversity$culture_shannon, 3), "\n")
cat("Cuisine Simpson Diversity Index:", round(diversity$cuisine_simpson, 3), "\n")
cat("Cuisine Shannon Diversity Index:", round(diversity$cuisine_shannon, 3), "\n")

invisible(list(
  pie_chart = pie_chart,
  bar_chart = bar_chart,
  type_chart = type_chart,
  map = map,
  data = data,
  diversity = diversity
))
