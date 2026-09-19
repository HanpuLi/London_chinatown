# London Chinatown Food & Beverage Analysis

## 🍜 Project Overview

This comprehensive analysis examines the cultural diversity of food and beverage establishments in London's Chinatown area. The study provides detailed insights into the culinary landscape, cultural distribution, and business patterns within a precisely defined geographic boundary using KML coordinates with a 50-meter buffer.

## 📊 Key Statistics

- **Total Establishments:** 146 food & beverage businesses
- **Chinese/Chinese Heritage:** 77 establishments (52.7%)
- **Other Asian:** 19 establishments (13.0%)
- **Other:** 50 establishments (34.2%)
- **Cultural Simpson Diversity Index:** 0.588
- **Cultural Shannon Diversity Index:** 0.97

## 🎯 Key Findings

### Cultural Diversity
- **Strong Chinese Identity:** 52.7% of establishments are Chinese/Chinese Heritage
- **Asian Diversity:** 13% represent other Asian cuisines (Japanese, Korean, Thai, Vietnamese, etc.)
- **International Mix:** 34.2% are non-Asian international establishments

### Business Types
- **Restaurants:** 97 establishments (66.4%)
- **Cafes:** 13 establishments (8.9%)
- **Fast Food:** 11 establishments (7.5%)
- **Bars & Pubs:** 13 establishments (8.9%)
- **Other:** 12 establishments (8.2%)

## 📁 Repository Structure

```
London_chinatown/
├── README.md                           # This file
├── reports/comprehensive_analysis_report.html  # Main HTML report
├── reports/interactive_map.html               # Interactive map
├── interactive_map_files/             # Map support files
├── data/
│   ├── food_data.csv                  # Main dataset (146 records)
│   ├── all_osm_rawdata.csv           # All OSM raw data (259 records)
│   └── map_summary_for_ppt.csv       # Summary data for PPT
├── visualizations/
│   ├── cultural_background_distribution.png
│   ├── cuisine_distribution.png
│   ├── business_type_distribution.png
│   ├── london_chinatown_static_map_ppt.png
│   └── cultural_distribution_pie.png
├── scripts/
│   ├── data_cleaning_script.R
│   ├── cuisine_fix_script.R
│   ├── visualization_script.R
│   └── create_comprehensive_report.R
├── geographic/
│   ├── kml_original.geojson
│   └── kml_50m_buffer.geojson
└── documentation/
    ├── powerpoint_integration_guide.md
    ├── ppt_alternative_solutions.md
    ├── qr_code_instructions.md
    └── embed_map_in_ppt_guide.md
```

## 🚀 Getting Started

### 1. View the Report
Open `reports/comprehensive_analysis_report.html` in your web browser to see the complete analysis with interactive visualizations.

### 2. Explore the Data
- **Main Dataset:** `data/food_data.csv` contains 146 cleaned food & beverage establishments
- **Raw Data:** `data/all_osm_rawdata.csv` contains all 259 OpenStreetMap records

### 3. Reproduce the Analysis
Run the R scripts in the `scripts/` folder in this order:
1. `data_cleaning_script.R` - Clean and filter the data
2. `cuisine_fix_script.R` - Fix cuisine classifications
3. `visualization_script.R` - Create visualizations
4. `create_comprehensive_report.R` - Generate complete report

## 📊 Data Description

### Main Dataset (`data/food_data.csv`)
- **146 records** of food & beverage establishments
- **Key columns:**
  - `name` - Business name
  - `name.zh` - Chinese name (if available)
  - `amenity` - OSM amenity type
  - `shop` - OSM shop type
  - `cuisine_fixed` - Cleaned cuisine classification
  - `culture_fixed` - Cultural background classification
  - `lat`, `lng` - Real OSM coordinates
  - `business_type` - Merged business category

### Cultural Classifications
- **Chinese/Chinese Heritage:** Businesses with Chinese cultural background
- **Other Asian:** Japanese, Korean, Thai, Vietnamese, etc.
- **Other:** Non-Asian international cuisines

### Cuisine Classifications
- **Chinese:** All Chinese-related cuisines (Taiwanese, Sichuan, Cantonese, etc.)
- **Japanese:** Sushi, ramen, Japanese cuisine
- **Korean:** Korean barbecue, Korean cuisine
- **Thai:** Thai restaurants and cuisine
- **Vietnamese:** Pho, Vietnamese cuisine
- **Other:** Italian, American, Brazilian, etc.

## 🎨 Visualizations

### Interactive Map
- **Color Coding:** Red (Chinese/Chinese Heritage), Teal (Other Asian), Blue (Other)
- **Marker Sizes:** Proportional to cultural category
- **Popups:** Detailed business information
- **Boundary Display:** Original KML and 50m buffer zones

### Static Charts
- **Pie Chart:** Cultural background distribution
- **Bar Charts:** Cuisine and business type distributions
- **High Resolution:** 300 DPI PNG files for publication

## 🔧 Technical Details

### Data Source
- **OpenStreetMap (OSM)** via Overpass API
- **Boundary Definition:** User-provided KML coordinates
- **Data Collection Date:** October 10, 2025

### Methodology
1. **Data Collection:** OSM query within KML boundary + 50m buffer
2. **Filtering:** Food & beverage establishments only
3. **Cleaning:** Remove non-business amenities and incomplete records
4. **Classification:** Multi-dimensional cultural and cuisine classification
5. **Analysis:** Diversity indices and statistical analysis
6. **Visualization:** Interactive maps and charts

### Quality Control
- **Duplicate Removal:** Eliminated duplicate OSM entries
- **Coordinate Validation:** Ensured all locations within boundary
- **Classification Review:** Manual review of cultural classifications
- **Data Integrity:** Cross-validation of amenity and shop types

## 📊 Diversity Metrics

### Simpson Diversity Index
- **Cultural:** 0.588 (moderate diversity)
- **Cuisine:** 0.599 (moderate diversity)

### Shannon Diversity Index
- **Cultural:** 0.97 (high diversity)
- **Cuisine:** 1.86 (very high diversity)

## 🎯 PowerPoint Integration

### Static Images
- Use PNG files from `visualizations/` folder
- Insert directly into PowerPoint
- High resolution (300 DPI) for printing

### Interactive Elements
- Generate QR code linking to `reports/interactive_map.html`
- Insert QR code into PowerPoint
- Audience scans to view interactive map

### Data Charts
- Use `data/map_summary_for_ppt.csv` for PPT-native charts
- Create pie charts and bar charts in PowerPoint
- Use provided color scheme

## 📝 Usage Notes

### For Researchers
- Use `data/food_data.csv` for statistical analysis
- Reference `data/all_osm_rawdata.csv` for complete OSM data
- R scripts provide reproducible methodology

### For Policy Makers
- Interactive map shows spatial distribution
- Cultural diversity metrics inform planning decisions
- Business type analysis supports economic development

### For General Public
- HTML report provides accessible overview
- Interactive map enables exploration
- Visualizations show cultural richness

## 🔍 Limitations

1. **Temporal Snapshot:** Data represents specific point in time
2. **OSM Dependency:** Quality depends on OpenStreetMap completeness
3. **Classification Subjectivity:** Some cultural classifications may require local knowledge
4. **Missing Data:** Some establishments may have incomplete OSM entries

## 📄 License

This analysis is based on OpenStreetMap data, which is licensed under the Open Database License (ODbL). The analysis results and visualizations are provided for research and educational purposes.

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📞 Contact

For questions about this analysis or to request additional data processing, please open an issue in this repository.

---

**Generated:** October 10, 2025  
**Data Source:** OpenStreetMap  
**Analysis Tool:** R Statistical Software  
**Boundary:** KML Coordinates + 50m Buffer  
**Total Records:** 146 Food & Beverage Establishments# London_chinatown
