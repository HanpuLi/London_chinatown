# Clean and Merge Food Data - Restaurant/Bar/Fast Food Only
library(dplyr)

cat("=== Cleaning and Merging Food Data ===\n")

# Read all OSM raw data
data <- read.csv("london_chinatown_all_osm_rawdata.csv", stringsAsFactors = FALSE)
cat("All OSM raw data loaded:", nrow(data), "records\n")

# 1. Filter for food-related businesses only
food_amenities <- c("restaurant", "cafe", "bar", "pub", "fast_food", "ice_cream")
food_shops <- c("bakery", "confectionery", "pastry", "food")  # Food-related shops only

cat("Filtering for food-related businesses only...\n")
food_data <- data %>%
  filter(
    (amenity %in% food_amenities) | 
    (shop %in% food_shops)
  )

cat("Food-related businesses:", nrow(food_data), "records\n")

# 2. Merge food types into one category
food_data$business_type <- "Food & Beverage"

# 3. Clean and merge cuisine classifications
cat("Cleaning and merging cuisine classifications...\n")

# Function to clean cuisine
clean_cuisine <- function(cuisine) {
  if (is.na(cuisine) || cuisine == "") {
    return(NA)
  }
  
  cuisine_lower <- tolower(cuisine)
  
  # Merge Chinese-related cuisines
  chinese_cuisines <- c("chinese", "taiwanese", "bubble_tea", "dumplings", "chinese;buffet", "sichuan")
  if (cuisine_lower %in% chinese_cuisines) {
    return("chinese")
  }
  
  # Keep other cuisines as is
  return(cuisine)
}

# Apply cuisine cleaning
food_data$cuisine_cleaned <- sapply(food_data$cuisine, clean_cuisine)

# 4. Infer cuisine from names for NA entries
cat("Inferring cuisine from names for NA entries...\n")

infer_cuisine_from_name <- function(name, name_zh = NULL) {
  name_lower <- tolower(name %||% "")
  name_zh_lower <- tolower(name_zh %||% "")
  
  # Chinese cuisine patterns
  chinese_patterns <- c(
    # Chinese characters
    "中", "华", "国", "京", "川", "粤", "湘", "鲁", "闽", "苏", "浙", "徽", "豫", "鄂", "赣", "桂", "琼", "贵", "云", "藏", "陕", "甘", "青", "宁", "新", "蒙", "黑", "吉", "辽", 
    "茶", "面", "饺", "包", "饼", "糕", "糖", "果", "菜", "饭", "粥", "汤", "酒", "店", "馆", "楼", "园", "轩", "阁", "居", "堂", "厅", "坊", "庄", "院", "府", "宫", "殿",
    # Chinese restaurant names
    "chinese", "china", "dim sum", "wonton", "dumpling", "noodle", "tea", "bubble tea", "boba", 
    "hot pot", "hotpot", "szechuan", "sichuan", "cantonese", "mandarin", "kowloon", "loon fung", 
    "new loon fung", "kung fu", "shaxian", "delicacies", "baiwei", "jinli", "wan chai", 
    "new china", "shanghai modern", "bar shu", "tonkotsu", "buffet chinese", "mw buffet", 
    "gold mine", "qiang brothers", "ying", "baozi inn", "nusadua", "little ku", "ku bar",
    "brothers", "inn", "dragon", "golden", "imperial", "taiwan", "taiwanese", "taipei", 
    "formosa", "old tree", "daiwan", "bee", "chen cheng ku", "young cheng", "tai chung wah", 
    "yg holiday", "ever travel", "pop mart", "miniso", "tsujiri", "sakurado", "reiwatakiya"
  )
  
  # Other Asian cuisine patterns
  asian_patterns <- c(
    "japanese", "korean", "thai", "vietnamese", "indian", "malaysian", "singaporean", 
    "filipino", "indonesian", "ramen", "sushi", "tempura", "kimchi", "bulgogi", 
    "pad thai", "curry", "pho", "banh mi", "satay", "nasi", "rendang", 
    "japan", "korea", "thailand", "vietnam", "india", "malaysia", "singapore", 
    "philippines", "indonesia", "singapulah", "kiln", "taro", "rosa's thai", 
    "viet pho", "pho & bun", "shibuya", "hankki", "misato", "sushi joy", 
    "ichibuns", "olle korean barbecue", "wasabi", "thai tho", "speedboat bar", 
    "c & r restaurant", "candy cafe", "mochi mochi"
  )
  
  # Check Chinese cuisine FIRST
  for (pattern in chinese_patterns) {
    if (grepl(pattern, name_lower, ignore.case = TRUE) || 
        grepl(pattern, name_zh_lower, ignore.case = TRUE)) {
      return("chinese")
    }
  }
  
  # Check other Asian cuisines
  for (pattern in asian_patterns) {
    if (grepl(pattern, name_lower, ignore.case = TRUE)) {
      if (grepl("japanese|sushi|ramen|tempura", pattern, ignore.case = TRUE)) return("japanese")
      if (grepl("korean|kimchi|bulgogi", pattern, ignore.case = TRUE)) return("korean")
      if (grepl("thai|pad thai", pattern, ignore.case = TRUE)) return("thai")
      if (grepl("vietnamese|pho|banh mi", pattern, ignore.case = TRUE)) return("vietnamese")
      if (grepl("indian|curry", pattern, ignore.case = TRUE)) return("indian")
      if (grepl("malaysian|singaporean|nasi|rendang", pattern, ignore.case = TRUE)) return("malaysian")
      if (grepl("indonesian", pattern, ignore.case = TRUE)) return("indonesian")
      return("asian")
    }
  }
  
  # Check other cuisines
  if (grepl("italian|pizza|pasta", name_lower, ignore.case = TRUE)) return("italian")
  if (grepl("french|bistro", name_lower, ignore.case = TRUE)) return("french")
  if (grepl("spanish|tapas", name_lower, ignore.case = TRUE)) return("spanish")
  if (grepl("mexican|taco", name_lower, ignore.case = TRUE)) return("mexican")
  if (grepl("american|burger|steak", name_lower, ignore.case = TRUE)) return("american")
  if (grepl("british|fish|chips", name_lower, ignore.case = TRUE)) return("british")
  if (grepl("brazilian", name_lower, ignore.case = TRUE)) return("brazilian")
  if (grepl("peruvian", name_lower, ignore.case = TRUE)) return("peruvian")
  
  return(NA)
}

# Apply cuisine inference for NA entries
food_data$cuisine_inferred <- sapply(1:nrow(food_data), function(i) {
  if (is.na(food_data$cuisine_cleaned[i]) || food_data$cuisine_cleaned[i] == "") {
    return(infer_cuisine_from_name(food_data$name[i], food_data$name.zh[i]))
  } else {
    return(food_data$cuisine_cleaned[i])
  }
})

# 5. Cultural classification
classify_culture <- function(name, cuisine, name_zh = NULL) {
  name_lower <- tolower(name %||% "")
  cuisine_lower <- tolower(cuisine %||% "")
  name_zh_lower <- tolower(name_zh %||% "")
  
  # Check for Chinese characters first
  if (!is.na(name_zh) && name_zh != "" && grepl("[\u4e00-\u9fff]", name_zh)) {
    return("Chinese/Chinese Heritage")
  }
  
  if (grepl("[\u4e00-\u9fff]", name)) {
    return("Chinese/Chinese Heritage")
  }
  
  # Check Chinese cuisine
  if (!is.na(cuisine_lower) && cuisine_lower == "chinese") {
    return("Chinese/Chinese Heritage")
  }
  
  # Check Chinese keywords
  chinese_keywords <- c(
    "chinese", "china", "dim sum", "wonton", "dumpling", "noodle", "bubble tea", "boba", 
    "hot pot", "hotpot", "szechuan", "sichuan", "cantonese", "mandarin", "kowloon", "loon fung", 
    "new loon fung", "kung fu", "shaxian", "delicacies", "baiwei", "jinli", "wan chai", 
    "new china", "shanghai modern", "bar shu", "tonkotsu", "buffet chinese", "mw buffet", 
    "gold mine", "qiang brothers", "ying", "baozi inn", "nusadua", "little ku", "ku bar",
    "brothers", "inn", "dragon", "golden", "imperial", "taiwan", "taiwanese", "taipei", 
    "formosa", "old tree", "daiwan", "bee", "chen cheng ku", "young cheng", "tai chung wah", 
    "yg holiday", "ever travel", "pop mart", "miniso", "tsujiri", "sakurado", "reiwatakiya"
  )
  
  for (keyword in chinese_keywords) {
    if (grepl(keyword, name_lower, ignore.case = TRUE) || 
        grepl(keyword, name_zh_lower, ignore.case = TRUE)) {
      return("Chinese/Chinese Heritage")
    }
  }
  
  # Check other Asian cuisines
  asian_cuisines <- c("japanese", "korean", "thai", "vietnamese", "indian", "malaysian", "indonesian", "asian")
  if (!is.na(cuisine_lower) && cuisine_lower %in% asian_cuisines) {
    return("Other Asian")
  }
  
  # Check other Asian keywords
  asian_keywords <- c(
    "japanese", "korean", "thai", "vietnamese", "indian", "malaysian", "singaporean", 
    "filipino", "indonesian", "ramen", "sushi", "tempura", "kimchi", "bulgogi", 
    "pad thai", "curry", "pho", "banh mi", "satay", "nasi", "rendang", 
    "japan", "korea", "thailand", "vietnam", "india", "malaysia", "singapore", 
    "philippines", "indonesia", "singapulah", "kiln", "taro", "rosa's thai", 
    "viet pho", "pho & bun", "shibuya", "hankki", "misato", "sushi joy", 
    "ichibuns", "olle korean barbecue", "wasabi", "thai tho", "speedboat bar", 
    "c & r restaurant", "candy cafe", "mochi mochi"
  )
  
  for (keyword in asian_keywords) {
    if (grepl(keyword, name_lower, ignore.case = TRUE)) {
      return("Other Asian")
    }
  }
  
  return("Other")
}

# Apply cultural classification
food_data$culture <- sapply(1:nrow(food_data), function(i) {
  classify_culture(
    food_data$name[i], 
    food_data$cuisine_inferred[i], 
    food_data$name.zh[i]
  )
})

# 6. Show results
cat("\n=== Cleaned Food Data Results ===\n")
cat("Total food businesses:", nrow(food_data), "\n")

# Cuisine distribution
cat("\nCuisine distribution (cleaned and inferred):\n")
cuisine_counts <- table(food_data$cuisine_inferred, useNA = 'ifany')
cuisine_counts <- sort(cuisine_counts, decreasing = TRUE)
print(cuisine_counts)

# Cultural distribution
cat("\nCultural distribution:\n")
culture_counts <- table(food_data$culture)
culture_percentages <- round(prop.table(culture_counts) * 100, 1)
for (i in 1:length(culture_counts)) {
  cat(names(culture_counts)[i], ":", culture_counts[i], "(", culture_percentages[i], "%)\n")
}

# Show Chinese/Chinese Heritage businesses
chinese_businesses <- food_data[food_data$culture == "Chinese/Chinese Heritage", ]
cat("\n=== Chinese/Chinese Heritage Food Businesses ===\n")
cat("Total:", nrow(chinese_businesses), "businesses\n")
for (i in 1:nrow(chinese_businesses)) {
  cat(i, ":", chinese_businesses$name[i], " - ", chinese_businesses$amenity[i], "/", chinese_businesses$shop[i])
  if (!is.na(chinese_businesses$cuisine_inferred[i]) && chinese_businesses$cuisine_inferred[i] != "") {
    cat(" - ", chinese_businesses$cuisine_inferred[i])
  }
  if (!is.na(chinese_businesses$name.zh[i]) && chinese_businesses$name.zh[i] != "") {
    cat(" (", chinese_businesses$name.zh[i], ")")
  }
  cat("\n")
}

# Show Other Asian businesses
asian_businesses <- food_data[food_data$culture == "Other Asian", ]
cat("\n=== Other Asian Food Businesses ===\n")
cat("Total:", nrow(asian_businesses), "businesses\n")
for (i in 1:nrow(asian_businesses)) {
  cat(i, ":", asian_businesses$name[i], " - ", asian_businesses$amenity[i], "/", asian_businesses$shop[i])
  if (!is.na(asian_businesses$cuisine_inferred[i]) && asian_businesses$cuisine_inferred[i] != "") {
    cat(" - ", asian_businesses$cuisine_inferred[i])
  }
  cat("\n")
}

# Show Other businesses
other_businesses <- food_data[food_data$culture == "Other", ]
cat("\n=== Other Food Businesses ===\n")
cat("Total:", nrow(other_businesses), "businesses\n")
for (i in 1:nrow(other_businesses)) {
  cat(i, ":", other_businesses$name[i], " - ", other_businesses$amenity[i], "/", other_businesses$shop[i])
  if (!is.na(other_businesses$cuisine_inferred[i]) && other_businesses$cuisine_inferred[i] != "") {
    cat(" - ", other_businesses$cuisine_inferred[i])
  }
  cat("\n")
}

# Save cleaned food data
write.csv(food_data, "london_chinatown_food_only_cleaned.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\nCleaned food data saved to: london_chinatown_food_only_cleaned.csv\n")

cat("\n=== Key Changes Made ===\n")
cat("1. Filtered for food-related businesses only (restaurant, cafe, bar, pub, fast_food, ice_cream, bakery, confectionery, pastry, food)\n")
cat("2. Merged all food types into 'Food & Beverage' category\n")
cat("3. Cleaned cuisine classifications:\n")
cat("   - Merged taiwanese, bubble_tea, dumplings, chinese;buffet, sichuan into 'chinese'\n")
cat("   - Kept other cuisines as is\n")
cat("4. Inferred cuisine from names for NA entries\n")
cat("5. Applied cultural classification based on cleaned cuisine and names\n")

return(food_data)
