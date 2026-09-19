# Create Final Food-Only Visualization
library(dplyr)
library(ggplot2)
library(leaflet)
library(htmlwidgets)
library(gridExtra)
library(RColorBrewer)
library(sf)

cat("=== Creating Final Food-Only Visualization ===\n")

build_dir <- Sys.getenv("LONDON_CHINATOWN_BUILD_DIR", unset = "build")
visual_dir <- file.path(build_dir, "visualizations")
dir.create(visual_dir, recursive = TRUE, showWarnings = FALSE)

# Read the classified data produced by the first two pipeline stages.
data <- read.csv(file.path(build_dir, "food_data.csv"), stringsAsFactors = FALSE)
cat("Cleaned food data loaded successfully,", nrow(data), "records\n")

# Read the versioned geographic boundaries.
kml_buffer <- st_read("geographic/kml_50m_buffer.geojson", quiet = TRUE)
kml_original <- st_read("geographic/kml_original.geojson", quiet = TRUE)

# Define colors
colors <- c("Chinese/Chinese Heritage" = "#FF6B6B", "Other Asian" = "#4ECDC4", "Other" = "#45B7D1")
data$color <- colors[data$culture]

# 1. Cultural Background Distribution Pie Chart
create_culture_pie <- function() {
  culture_counts <- table(data$culture)
  culture_percentages <- round(prop.table(culture_counts) * 100, 1)
  
  culture_data <- data.frame(
    culture = names(culture_counts),
    count = as.numeric(culture_counts),
    percentage = culture_percentages
  )
  
  # Custom colors
  colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1")
  
  pie_chart <- ggplot(culture_data, aes(x = "", y = count, fill = culture)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    theme_void() +
    labs(title = "Cultural Background Distribution - Food & Beverage Only",
         subtitle = paste("Total", nrow(data), "food & beverage establishments within KML polygon + 50m buffer"),
         fill = "Cultural Background") +
    scale_fill_manual(values = colors) +
    theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 12),
          legend.position = "bottom") +
    geom_text(aes(label = paste(culture, "\n", count, "establishments\n(", round(count/sum(count)*100, 1), "%)")), 
              position = position_stack(vjust = 0.5), size = 4, color = "white", fontface = "bold")
  
  return(pie_chart)
}

# 2. Cuisine Distribution Bar Chart
create_cuisine_bar <- function() {
  cuisine_counts <- table(data$cuisine_inferred, useNA = 'ifany')
  cuisine_percentages <- round(prop.table(cuisine_counts) * 100, 1)
  
  cuisine_data <- data.frame(
    cuisine = names(cuisine_counts),
    count = as.numeric(cuisine_counts),
    percentage = cuisine_percentages
  )
  
  # Remove NA for better visualization
  cuisine_data <- cuisine_data[!is.na(cuisine_data$cuisine), ]
  
  bar_chart <- ggplot(cuisine_data, aes(x = reorder(cuisine, count), y = count, fill = cuisine)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    labs(title = "Cuisine Distribution - Food & Beverage Only",
         subtitle = paste("Total", nrow(data), "food & beverage establishments (cleaned and merged cuisine classifications)"),
         x = "Cuisine Type", y = "Number of Establishments") +
    scale_fill_manual(values = c("#FF6B6B", "#4ECDC4", "#45B7D1", "#98D8C8", "#87CEEB", "#DDA0DD", "#F0E68C", "#D2B48C", "#BC8F8F", "#A0522D", "#8B4513", "#654321", "#2F4F4F", "#696969", "#808080", "#A9A9A9", "#C0C0C0", "#D3D3D3", "#DCDCDC", "#F5F5F5", "#FFFAFA", "#F0F8FF", "#F8F8FF", "#F5FFFA", "#F0FFF0", "#FFF8DC", "#FFEBCD", "#FFE4B5", "#FFDAB9", "#FFC0CB", "#FFB6C1", "#FFA07A", "#FF7F50", "#FF6347", "#FF4500", "#FF1493", "#FF69B4", "#FFB6C1", "#FFC0CB", "#FFDAB9", "#FFE4B5", "#FFEBCD", "#FFF8DC", "#F0FFF0", "#F5FFFA", "#F8F8FF", "#F0F8FF", "#FFFAFA", "#F5F5F5", "#DCDCDC", "#D3D3D3", "#C0C0C0", "#A9A9A9", "#808080", "#696969", "#2F4F4F", "#654321", "#8B4513", "#A0522D", "#BC8F8F", "#D2B48C", "#F0E68C", "#DDA0DD", "#87CEEB", "#98D8C8", "#FFA07A")) +
    theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 12),
          legend.position = "none") +
    geom_text(aes(label = paste(count, "establishments\n(", round(count/sum(count)*100, 1), "%)")), 
              hjust = -0.1, size = 3, fontface = "bold")
  
  return(bar_chart)
}

# 3. Create Interactive Map
create_food_interactive_map <- function() {
  cat("Creating food-only interactive map...\n")
  
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
      data = data[data$culture == "Chinese/Chinese Heritage", ],
      lng = ~lng, lat = ~lat,
      radius = 15,
      color = "#FF6B6B",
      fillColor = "#FF6B6B",
      fillOpacity = 0.9,
      stroke = TRUE,
      weight = 3,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 320px;'>",
        "<h3 style='color: #FF6B6B; margin: 0 0 10px 0;'>🏮 ", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #FF6B6B; font-weight: bold;'>", culture, "</span></p>",
        ifelse(!is.na(cuisine_inferred) & cuisine_inferred != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_inferred, "</p>"), ""),
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
      data = data[data$culture == "Other Asian", ],
      lng = ~lng, lat = ~lat,
      radius = 12,
      color = "#4ECDC4",
      fillColor = "#4ECDC4",
      fillOpacity = 0.8,
      stroke = TRUE,
      weight = 2,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 320px;'>",
        "<h3 style='color: #4ECDC4; margin: 0 0 10px 0;'>🍜 ", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #4ECDC4; font-weight: bold;'>", culture, "</span></p>",
        ifelse(!is.na(cuisine_inferred) & cuisine_inferred != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_inferred, "</p>"), ""),
        "<p><strong>Coordinates:</strong> ", round(lat, 6), ", ", round(lng, 6), "</p>",
        "</div>"
      )
    ) %>%
    
    # Add Other businesses (smaller markers)
    addCircleMarkers(
      data = data[data$culture == "Other", ],
      lng = ~lng, lat = ~lat,
      radius = 8,
      color = "#45B7D1",
      fillColor = "#45B7D1",
      fillOpacity = 0.7,
      stroke = TRUE,
      weight = 2,
      popup = ~paste0(
        "<div style='font-family: Arial; width: 320px;'>",
        "<h3 style='color: #45B7D1; margin: 0 0 10px 0;'>", name, "</h3>",
        "<p><strong>Type:</strong> ", ifelse(!is.na(amenity) & amenity != "", amenity, ifelse(!is.na(shop) & shop != "", shop, "Food & Beverage")), "</p>",
        "<p><strong>Cultural Background:</strong> <span style='color: #45B7D1; font-weight: bold;'>", culture, "</span></p>",
        ifelse(!is.na(cuisine_inferred) & cuisine_inferred != "", 
               paste0("<p><strong>Cuisine:</strong> ", cuisine_inferred, "</p>"), ""),
        "<p><strong>Coordinates:</strong> ", round(lat, 6), ", ", round(lng, 6), "</p>",
        "</div>"
      )
    ) %>%
    
    # Add legend
    addLegend(
      position = "bottomright",
      colors = colors,
      labels = c(paste("Chinese/Chinese Heritage (", sum(data$culture == "Chinese/Chinese Heritage"), ")"),
                 paste("Other Asian (", sum(data$culture == "Other Asian"), ")"),
                 paste("Other (", sum(data$culture == "Other"), ")")),
      title = "Cultural Background Distribution",
      opacity = 0.8
    ) %>%
    
    # Add title and control panel
    addControl(
      html = paste0("<div style='background: white; padding: 15px; border-radius: 8px; box-shadow: 0 3px 10px rgba(0,0,0,0.3); max-width: 350px;'>
                <h2 style='margin: 0 0 10px 0; color: #FF6B6B; text-align: center;'>🍜 London Chinatown</h2>
                <p style='margin: 5px 0; text-align: center; color: #333;'><strong>Food & Beverage Analysis</strong></p>
                <hr style='margin: 10px 0;'>
                <p style='margin: 5px 0; font-size: 14px;'><strong>Total:</strong> ", nrow(data), " food & beverage establishments</p>
                <p style='margin: 5px 0; font-size: 14px; color: #FF6B6B;'><strong>Chinese/Chinese Heritage:</strong> ", sum(data$culture == 'Chinese/Chinese Heritage'), " (", round(prop.table(table(data$culture))['Chinese/Chinese Heritage'] * 100, 1), "%)</p>
                <p style='margin: 5px 0; font-size: 14px; color: #4ECDC4;'><strong>Other Asian:</strong> ", sum(data$culture == 'Other Asian'), " (", round(prop.table(table(data$culture))['Other Asian'] * 100, 1), "%)</p>
                <p style='margin: 5px 0; font-size: 14px; color: #45B7D1;'><strong>Other:</strong> ", sum(data$culture == 'Other'), " (", round(prop.table(table(data$culture))['Other'] * 100, 1), "%)</p>
                <hr style='margin: 10px 0;'>
                <p style='margin: 5px 0; font-size: 12px; color: #666;'>Boundary: KML coordinates + 50m buffer | Real OSM coordinates | Food & beverage only | Analysis Date: October 10, 2025</p>
              </div>"),
      position = "topleft"
    ) %>%
    
    # Set view to Chinatown area
    setView(lng = -0.1305, lat = 51.5115, zoom = 17)
  
  return(map)
}

# Execute visualizations
cat("Starting to create food-only visualizations...\n")

# 1. Save individual charts
pie_chart <- create_culture_pie()
ggsave(file.path(visual_dir, "cultural_background_distribution.png"), pie_chart, width = 10, height = 8, dpi = 300)

bar_chart <- create_cuisine_bar()
ggsave(file.path(visual_dir, "cuisine_distribution.png"), bar_chart, width = 12, height = 8, dpi = 300)

# 2. Create interactive map
map <- create_food_interactive_map()
saveWidget(map, file.path(visual_dir, "interactive_map.html"), selfcontained = FALSE)

cat("\n=== Food-Only Visualizations Created Successfully ===\n")
cat("Generated files in", visual_dir, ":\n")
cat("- cultural_background_distribution.png - Food-only cultural background distribution pie chart\n")
cat("- cuisine_distribution.png - Food-only cuisine distribution bar chart\n")
cat("- interactive_map.html - Food-only interactive map\n")

# Calculate diversity indices
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

culture_simpson <- calculate_simpson_diversity(data$culture)
culture_shannon <- calculate_shannon_diversity(data$culture)
cuisine_simpson <- calculate_simpson_diversity(data$cuisine_inferred[!is.na(data$cuisine_inferred)])
cuisine_shannon <- calculate_shannon_diversity(data$cuisine_inferred[!is.na(data$cuisine_inferred)])

cat("\n=== Final Food-Only Analysis Results ===\n")
cat("Total food & beverage establishments:", nrow(data), "\n")
cat("Chinese/Chinese Heritage:", sum(data$culture == "Chinese/Chinese Heritage"), "(", round(prop.table(table(data$culture))["Chinese/Chinese Heritage"] * 100, 1), "%)\n")
cat("Other Asian:", sum(data$culture == "Other Asian"), "(", round(prop.table(table(data$culture))["Other Asian"] * 100, 1), "%)\n")
cat("Other:", sum(data$culture == "Other"), "(", round(prop.table(table(data$culture))["Other"] * 100, 1), "%)\n")
cat("Cultural Simpson Diversity Index:", round(culture_simpson, 3), "\n")
cat("Cultural Shannon Diversity Index:", round(culture_shannon, 3), "\n")
cat("Cuisine Simpson Diversity Index:", round(cuisine_simpson, 3), "\n")
cat("Cuisine Shannon Diversity Index:", round(cuisine_shannon, 3), "\n")

# Show key findings
cat("\n=== Key Findings - Food & Beverage Analysis ===\n")
cat("1. Focused on food & beverage establishments only (restaurant, cafe, bar, pub, fast_food, ice_cream, bakery, confectionery, pastry, food)\n")
cat("2. Merged Chinese-related cuisines: taiwanese, bubble_tea, dumplings, chinese;buffet, sichuan → chinese\n")
cat("3. Inferred cuisine from names for NA entries\n")
cat("4. Chinese/Chinese Heritage businesses represent", round(prop.table(table(data$culture))["Chinese/Chinese Heritage"] * 100, 1), "% of food & beverage establishments\n")
cat("5. This provides a focused view of Chinatown's culinary landscape\n")
cat("6. All coordinates are real OSM coordinates within precise KML boundary\n")

invisible(list(
  pie_chart = pie_chart,
  bar_chart = bar_chart,
  map = map,
  data = data
))
