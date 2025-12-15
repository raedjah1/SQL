# Daily Inventory Summary Report Specification (2.3)

## Report Overview
**Report Name**: Daily Inventory Summary Report  
**Report Number**: 2.3  
**Purpose**: Provide current inventory levels by part number and location for production planning  
**Frequency**: Daily, prior to start of production  
**Recipients**: Production planning, inventory management, operations team  

## Data Structure

### Required Columns
| Column | Description | Example | Business Purpose |
|--------|-------------|---------|------------------|
| **Program** | Business program identifier | FWD | Identifies Excess Centralization program |
| **SKU** | Stock Keeping Unit | 2GIG-LTEA-A-GC2 | Unique part identifier |
| **Manufacturer** | Part manufacturer | Nortek | Who makes the part |
| **Description** | Part description | ATT Cat-1 4G LTE Cell Radio | What the part is |
| **Exception Code** | Special handling code | (blank) | Any special conditions |
| **Notes** | Additional information | (blank) | Extra details about the part |
| **Sub Inventory Locator** | Sub-location identifier | INM | Specific storage area |
| **Facility** | Facility code | ATL | Which facility (Atlanta) |
| **Location** | Specific storage location | F07H | Exact bin/shelf location |
| **Location Type** | Location category | MAIN/ALT | Primary or alternative storage |
| **Quantity** | Current stock at location | 200 | How many units at this location |
| **Total Quantity** | Sum across all locations | 438 | Total units for this SKU |

## Business Logic

### Location Hierarchy
- **Facility**: ATL (Atlanta)
- **Location Types**: 
  - MAIN = Primary storage locations
  - ALT = Alternative/overflow storage locations
- **Sub Inventory**: INM = Inventory Management

### Quantity Calculations
- **Quantity**: Stock at specific location
- **Total Quantity**: Sum of all quantities for same SKU across all locations
- **Example**: 2GIG-LTEA-A-GC2 has 200 at F07H (MAIN) + 238 at I87A (ALT) = 438 Total

### Part Categories
- **Security Equipment**: Keypads, cameras, sensors, control panels
- **Communication**: LTE radios, WiFi extenders, cellular communicators
- **Accessories**: Keyfobs, thermostats, doorbell cameras
- **Refurbished Items**: Marked as "Refurbished" in description

## Report Requirements

### Data Sources
- Inventory management system
- Location tracking system
- Part master data

### Filtering
- **Program**: FWD only (Excess Centralization)
- **Active Inventory**: Only parts with quantity > 0
- **Current Date**: As of report generation time

### Sorting
- Primary: SKU (alphabetical)
- Secondary: Location Type (MAIN first, then ALT)
- Tertiary: Location (alphabetical)

### Formatting
- **Quantities**: Whole numbers only
- **Descriptions**: Full manufacturer descriptions
- **Location Codes**: Standard facility location codes

## Sample Output Structure
```
Program | SKU | Manufacturer | Description | Facility | Location | Location Type | Quantity | Total Quantity
FWD | 2GIG-LTEA-A-GC2 | Nortek | ATT Cat-1 4G LTE Cell Radio | ATL | F07H | MAIN | 200 | 438
FWD | 2GIG-LTEA-A-GC2 | Nortek | ATT Cat-1 4G LTE Cell Radio | ATL | I87A | ALT | 238 | 438
```

## Key Business Insights

### Inventory Distribution
- **Main Locations**: Primary storage for high-volume parts
- **Alternative Locations**: Overflow storage for excess inventory
- **Location Utilization**: Shows how inventory is distributed across facility

### Production Planning
- **Total Availability**: Total Quantity shows what's available for production
- **Location Access**: MAIN locations are easier to access than ALT
- **Part Mix**: Variety of security, communication, and accessory parts

### Operational Efficiency
- **Location Management**: Helps optimize picking and staging
- **Space Utilization**: Shows which locations are being used
- **Inventory Levels**: Identifies high-volume vs. low-volume parts

## Technical Implementation

### Database Tables
- Inventory master table
- Location master table
- Part location table
- Program assignment table

### Key Fields
- SKU (primary key)
- Location (primary key)
- Quantity (calculated)
- Total Quantity (aggregated)

### Performance Considerations
- Index on SKU and Location
- Pre-calculate Total Quantity for performance
- Consider materialized view for large datasets

## Success Criteria
- **Accuracy**: Quantities match physical inventory
- **Completeness**: All FWD parts included
- **Timeliness**: Generated before production start
- **Usability**: Clear location and quantity information for planning
