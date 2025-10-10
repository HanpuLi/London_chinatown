# Fix Cuisine Classification - Merge All Chinese Variants
library(dplyr)

cat("=== Fixing Cuisine Classification ===\n")

# Read the current food data
data <- read.csv("london_chinatown_food_only_cleaned.csv", stringsAsFactors = FALSE)
cat("Current food data loaded:", nrow(data), "records\n")

# Show current cuisine distribution
cat("\nCurrent cuisine distribution:\n")
print(table(data$cuisine_inferred, useNA = 'ifany'))

# Function to properly merge all Chinese cuisine variants
fix_chinese_cuisine <- function(cuisine) {
  if (is.na(cuisine) || cuisine == "") {
    return(NA)
  }
  
  cuisine_lower <- tolower(cuisine)
  
  # All Chinese-related cuisines should be merged to "chinese"
  chinese_variants <- c(
    "chinese", "taiwanese", "bubble_tea", "dumplings", "chinese;buffet", 
    "sichuan", "szechuan", "cantonese", "hunan", "beijing", "shanghai",
    "chinese;buffet", "buffet chinese", "mw buffet", "chinese buffet"
  )
  
  if (cuisine_lower %in% chinese_variants) {
    return("chinese")
  }
  
  # Keep other cuisines as is
  return(cuisine)
}

# Apply the fix
data$cuisine_fixed <- sapply(data$cuisine_inferred, fix_chinese_cuisine)

# Show fixed cuisine distribution
cat("\nFixed cuisine distribution:\n")
print(table(data$cuisine_fixed, useNA = 'ifany'))

# Update cultural classification based on fixed cuisine
classify_culture_fixed <- function(name, cuisine, name_zh = NULL) {
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

# Apply fixed cultural classification
data$culture_fixed <- sapply(1:nrow(data), function(i) {
  classify_culture_fixed(
    data$name[i], 
    data$cuisine_fixed[i], 
    data$name.zh[i]
  )
})

# Show results
cat("\n=== Fixed Classification Results ===\n")
cat("Total food businesses:", nrow(data), "\n")

# Cultural distribution
cat("\nCultural distribution (fixed):\n")
culture_counts <- table(data$culture_fixed)
culture_percentages <- round(prop.table(culture_counts) * 100, 1)
for (i in 1:length(culture_counts)) {
  cat(names(culture_counts)[i], ":", culture_counts[i], "(", culture_percentages[i], "%)\n")
}

# Show Chinese/Chinese Heritage businesses
chinese_businesses <- data[data$culture_fixed == "Chinese/Chinese Heritage", ]
cat("\n=== Chinese/Chinese Heritage Food Businesses (Fixed) ===\n")
cat("Total:", nrow(chinese_businesses), "businesses\n")
for (i in 1:min(20, nrow(chinese_businesses))) {
  cat(i, ":", chinese_businesses$name[i], " - ", chinese_businesses$amenity[i], "/", chinese_businesses$shop[i])
  if (!is.na(chinese_businesses$cuisine_fixed[i]) && chinese_businesses$cuisine_fixed[i] != "") {
    cat(" - ", chinese_businesses$cuisine_fixed[i])
  }
  if (!is.na(chinese_businesses$name.zh[i]) && chinese_businesses$name.zh[i] != "") {
    cat(" (", chinese_businesses$name.zh[i], ")")
  }
  cat("\n")
}

# Save fixed data
write.csv(data, "london_chinatown_food_cuisine_fixed.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\nFixed cuisine data saved to: london_chinatown_food_cuisine_fixed.csv\n")

cat("\n=== Key Fixes Applied ===\n")
cat("1. Merged all Chinese cuisine variants to 'chinese':\n")
cat("   - taiwanese → chinese\n")
cat("   - sichuan → chinese\n")
cat("   - chinese;buffet → chinese\n")
cat("   - bubble_tea → chinese\n")
cat("   - dumplings → chinese\n")
cat("   - szechuan → chinese\n")
cat("   - cantonese → chinese\n")
cat("   - hunan → chinese\n")
cat("   - beijing → chinese\n")
cat("   - shanghai → chinese\n")
cat("2. Updated cultural classification based on fixed cuisine\n")
cat("3. Maintained other cuisines as separate categories\n")

return(data)
