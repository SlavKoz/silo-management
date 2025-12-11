# Color System V2 - Summary

## Key Changes

### 1. **Relative Color System for Grain Groups**
- Grain groups store **both** the lightness modifier AND the computed color
- **Lightness Modifier**: A decimal value (0.5 to 1.5) that defines the relationship to the commodity color
  - `1.0` = same as commodity color
  - `> 1.0` = lighter (e.g., 1.2 = 20% lighter)
  - `< 1.0` = darker (e.g., 0.8 = 20% darker)
- **Computed Color**: The actual hex color, calculated and **cached**
- Colors are NOT recalculated on every read - they're stored!
- Only recalculate when commodity color changes: `EXEC sp_RecalculateGrainGroupColours`

### 2. **Variants Use Patterns Only (No Colors)**
- Variants inherit color from their grain group
- Variants only store **Pattern** (e.g., 'solid', 'striped', 'dotted')
- No `BaseColour` or `DefaultColour` fields on variants

### 3. **No Date Tracking on Entity Tables**
- Removed: `CreatedDate`, `ModifiedDate`, `LastSyncDate`
- All sync tracking now goes to the global `SyncLog` table
- Cleaner table structure, easier to maintain

### 4. **Global SyncLog Table**
- Centralized tracking for all sync operations
- Stores: EntityType, Start/End times, Records processed/added/updated/deactivated, Status, Errors
- View: `vw_LatestSyncStatus` shows latest sync for each entity type
- Can be displayed in an info bar in the UI

---

## Table Structure

### **Commodities**
```
Commodities
├─ CommodityID (PK)
├─ CommodityCode (unique)
├─ CommodityName
└─ IsActive

CommodityAttributes
├─ CommodityID (PK, FK)
├─ BaseColour (hex: #DAA520)
├─ ColourName (human-readable)
├─ DisplayOrder
└─ Notes
```

### **GrainGroups**
```
GrainGroups
├─ GrainGroupID (PK)
├─ GrainGroupCode (unique)
├─ GrainGroupName
├─ CommodityID (FK)
└─ IsActive

GrainGroupAttributes
├─ GrainGroupID (PK, FK)
├─ LightnessModifier (0.5-1.5)  ← Relative to commodity
├─ ComputedColour (hex)         ← Cached result
├─ ColourName
├─ DisplayOrder
└─ Notes
```

### **Variants**
```
Variants
├─ VariantID (PK)
├─ VariantNo
├─ GrainGroup
├─ Commodity
└─ IsActive

VariantAttributes
├─ VariantID (PK, FK)
├─ Pattern ('solid', 'striped', etc.)
└─ Notes
```

### **SyncLog**
```
SyncLog
├─ SyncID (PK)
├─ EntityType ('Variants', 'Commodities', etc.)
├─ SyncStartTime
├─ SyncEndTime
├─ RecordsProcessed
├─ RecordsAdded
├─ RecordsUpdated
├─ RecordsDeactivated
├─ Status ('Running', 'Success', 'Failed')
├─ ErrorMessage
└─ SyncedBy
```

---

## How Colors Work

### **Commodity → Grain Group → Variant**

1. **Commodity** has a base color (e.g., Wheat = `#DAA520`)
2. **Grain Group** has:
   - A `LightnessModifier` (e.g., `1.15` for GP1M = 15% lighter)
   - A `ComputedColour` (e.g., `#E8B84D` - calculated and cached)
3. **Variant** inherits the grain group's `ComputedColour`

### **Changing Commodity Colors**

When you change a commodity's base color:

```sql
-- 1. Update the commodity color
UPDATE dbo.CommodityAttributes
SET BaseColour = '#NEW_COLOR'
WHERE CommodityID = @CommodityID;

-- 2. Recalculate all grain group colors for this commodity
EXEC dbo.sp_RecalculateGrainGroupColours @CommodityID = @CommodityID;

-- Or recalculate all:
EXEC dbo.sp_RecalculateGrainGroupColours;
```

The stored procedure:
- Reads the new commodity color
- Multiplies by each grain group's `LightnessModifier`
- Updates the `ComputedColour` field
- Done! Variants automatically see the new colors via the view

---

## Color Computation Algorithm

```
If LightnessModifier > 1.0 (lighten):
    NewR = R + (255 - R) * (Modifier - 1.0)
    NewG = G + (255 - G) * (Modifier - 1.0)
    NewB = B + (255 - B) * (Modifier - 1.0)

If LightnessModifier < 1.0 (darken):
    NewR = R * Modifier
    NewG = G * Modifier
    NewB = B * Modifier
```

Example:
- Commodity: Wheat `#DAA520` (218, 165, 32)
- Modifier: `1.15` (15% lighter)
- Result: `#E8B84D` (232, 184, 77)

---

## Installation

### **Option 1: Master Script (Recommended)**
```sql
-- Run this single script to set up everything:
C:\...\sql\MASTER_setup_color_system.sql
```

### **Option 2: Individual Scripts**
```sql
-- 1. Create sync tracking
C:\...\sql\create_sync_log_table.sql

-- 2. Create commodities with colors
C:\...\sql\create_commodities_tables_v2.sql

-- 3. Create grain groups with relative colors
C:\...\sql\create_graingroups_tables_v2.sql

-- 4. Populate grain groups (all 100+)
C:\...\sql\create_graingroups_tables.sql

-- 5. Populate grain group modifiers and compute colors
C:\...\sql\populate_graingroup_colors.sql

-- 6. Update variants table
C:\...\sql\update_variants_remove_colors.sql
```

---

## Usage Examples

### **View Commodity Colors**
```sql
SELECT * FROM vw_Commodities
ORDER BY DisplayOrder;
```

### **View Grain Group Colors (with modifiers)**
```sql
SELECT
    GrainGroupCode,
    GrainGroupName,
    CommodityCode,
    LightnessModifier,
    CommodityBaseColour,
    BaseColour AS ComputedColour,
    ColourName
FROM vw_GrainGroups
WHERE CommodityCode = 'WHT'
ORDER BY DisplayOrder;
```

### **View Variants with Inherited Colors**
```sql
SELECT
    VariantNo,
    GrainGroup,
    Commodity,
    Pattern,
    GrainGroupColour AS InheritedColor,
    EffectiveColour
FROM vw_Variants
WHERE Commodity = 'WHT'
ORDER BY GrainGroup, VariantNo;
```

### **Check Latest Sync Status**
```sql
SELECT * FROM vw_LatestSyncStatus;
```

---

## Benefits

✅ **No color recalculation overhead** - colors are cached
✅ **Easy to change commodity colors** - one procedure updates all related grain groups
✅ **Cleaner tables** - no date fields cluttering entity tables
✅ **Centralized sync tracking** - all sync info in one place
✅ **Variants inherit colors** - no redundant color storage
✅ **Flexible pattern system** - unlimited visual differentiation for variants

---

## Pattern Types for Variants

Suggested pattern values:
- `solid` - No pattern (default)
- `striped` - Horizontal stripes
- `v-striped` - Vertical stripes
- `dotted` - Dots/stippling
- `checkered` - Grid pattern
- `diagonal` - Diagonal lines
- `crosshatch` - Crossed lines
- `wavy` - Wavy lines
- `zigzag` - Zigzag pattern
- `herringbone` - V-shaped pattern
- `brick` - Brick offset pattern
- `honeycomb` - Hexagonal pattern

A `PatternTypes` reference table is created for UI dropdowns.

---

## R Query Updates

Update your R query functions to match the new structure:

```r
# Variants no longer have base_colour parameter
update_variant_attributes <- function(variant_id, pattern = NULL, notes = NULL, pool)

# List variants can filter by missing_pattern instead of missing_base_colour
list_variants(..., missing_pattern = NULL, ...)

# New function for counting missing patterns
count_variants_missing_pattern(pool)
```

---

## Notes

- Lightness modifiers are typically in the range `0.75` to `1.25`
- Extreme values (`< 0.5` or `> 1.5`) may produce poor results
- All colors are uppercase hex codes (e.g., `#DAA520`)
- The computation function uses simple RGB math (not HSL), which works well for lightness adjustments
- For more sophisticated color manipulation, the function can be enhanced to use HSL color space

