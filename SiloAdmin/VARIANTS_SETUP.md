# Variants Browser Setup

## Overview
This setup allows you to manage Franklin variants (430 items) with custom attributes that can't be stored in Franklin. The structure follows: **Variant → Grain Group → Commodity**.

## What Was Created

### 1. SQL Database Structure (`sql/create_variants_tables.sql`)

**Tables:**
- `Variants` - Synced from Franklin, stores:
  - VariantNo (from Franklin)
  - GrainGroup (from Franklin Default Dimension)
  - Commodity (from Franklin Default Dimension)
  - LastSyncDate, IsActive

- `VariantAttributes` - Custom attributes stored in SiloOps:
  - BaseColour (your custom attribute)
  - Notes (general notes)
  - Links to Variants via VariantID

**Stored Procedure:**
- `sp_SyncVariantsFromFranklin` - Syncs all 430 variants from Franklin to SiloOps
  - Pulls variant numbers from Franklin Items table
  - Fetches Grain Group and Commodity from Default Dimensions
  - Merges into SiloOps.Variants (upsert logic)
  - Marks missing variants as inactive
  - Creates attribute records for new variants

**View:**
- `vw_Variants` - Convenient view joining Variants + VariantAttributes

### 2. R Query Functions (`R/db/variants_queries.R`)

- `list_variants()` - List variants with filtering by commodity, grain group, variant number
- `get_variant()` - Get single variant by ID
- `update_variant_attributes()` - Update BaseColour and Notes
- `list_commodities()` - Get unique commodities for filter dropdown
- `list_grain_groups()` - Get unique grain groups for filter dropdown
- `list_grain_groups_for_commodity()` - Get grain groups for specific commodity
- `sync_variants_from_franklin()` - Trigger sync from R

### 3. Variants Browser (`R/browsers/f_browser_variants.R`)

Following the same pattern as `f_browser_silos`:
- Left panel (33%):
  - Commodity filter dropdown
  - Grain Group filter dropdown (cascading - updates based on commodity)
  - Compact list of variants with search
- Right panel (66%):
  - Read-only fields: Variant Number, Commodity, Grain Group (from Franklin)
  - Editable fields: Base Colour, Notes (SiloOps custom attributes)
  - Save button (no delete - variants come from Franklin)

## Setup Steps

### 1. Run SQL Setup
```sql
-- In SiloOps database, run:
-- C:\Users\slawomirkozielec\OneDrive - Camgrain\Documents\MyRProjects\Silo\sql\create_variants_tables.sql

-- After tables are created, run initial sync:
EXEC dbo.sp_SyncVariantsFromFranklin;

-- Verify data:
SELECT COUNT(*) FROM dbo.Variants;  -- Should be ~430
SELECT * FROM dbo.vw_Variants ORDER BY Commodity, GrainGroup, VariantNo;
```

### 2. Add Route to App

In `R/f_app_server.R`, add to route_map:
```r
"variants" = list(
  title = "Variants",
  ui    = function() {
    if (exists("f_browser_variants_ui")) f_browser_variants_ui("variants")
    else div(class = "p-3", h3("Variants"), p("Placeholder: Variants browser will go here."))
  },
  server = function() {
    if (exists("f_browser_variants_server")) f_browser_variants_server("variants", pool, route = current)
  }
)
```

In sidebar_structure, add:
```r
list(key = "variants@single", title = "Variants", items = c("variants"))
```

In icon_map, add:
```r
"variants" = "tags"
```

### 3. Add to Search Registry

In `R/f_search_registry.R`, add to SEARCH_FORMS:
```r
list(id = "variants", label = "Variants", category = "forms", route = "#/variants")
```

Add to `f_get_search_items()` in the all_categories list:
```r
all_categories <- c("containers", "shapes", "siloes", "sites", "areas", "operations", "layouts", "variants")
```

Add variant search case:
```r
else if (category == "variants") {
  # Fetch variants
  if (nzchar(query)) {
    safe_query <- gsub("'", "''", query)
    sql <- sprintf(
      "SELECT TOP %d VariantID, VariantNo, GrainGroup, Commodity
       FROM SiloOps.dbo.vw_Variants
       WHERE VariantNo LIKE '%%%s%%'
          OR GrainGroup LIKE '%%%s%%'
          OR Commodity LIKE '%%%s%%'",
      limit, safe_query, safe_query, safe_query
    )
  } else {
    sql <- sprintf(
      "SELECT TOP %d VariantID, VariantNo, GrainGroup, Commodity
       FROM SiloOps.dbo.vw_Variants
       ORDER BY Commodity, GrainGroup, VariantNo",
      limit
    )
  }
  df <- DBI::dbGetQuery(pool, sql)

  if (nrow(df) > 0) {
    items <- lapply(1:nrow(df), function(i) {
      label <- df$VariantNo[i]
      if (!is.na(df$GrainGroup[i])) {
        label <- paste0(label, " (", df$GrainGroup[i], ")")
      }
      list(
        id = df$VariantID[i],
        label = label,
        category = "variants",
        route = paste0("#/variants/", df$VariantID[i])
      )
    })
  }
}
```

## Usage

1. **Browse all variants**: Navigate to #/variants
2. **Filter by commodity**: Select commodity from dropdown → grain groups filter updates automatically
3. **Filter by grain group**: Select grain group from dropdown
4. **Search**: Type in search box to filter by variant number
5. **Edit attributes**: Click variant → edit Base Colour and Notes → Save
6. **Sync from Franklin**: Run `EXEC dbo.sp_SyncVariantsFromFranklin;` in SQL or call `sync_variants_from_franklin()` from R

## Database Maintenance

**Regular sync** (recommended weekly):
```sql
EXEC dbo.sp_SyncVariantsFromFranklin;
```

Or schedule as SQL Agent job:
```sql
USE [msdb]
GO
EXEC msdb.dbo.sp_add_job
    @job_name = N'Sync Variants from Franklin',
    @enabled = 1;
GO

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Sync Variants from Franklin',
    @step_name = N'Run Sync',
    @subsystem = N'TSQL',
    @database_name = N'SiloOps',
    @command = N'EXEC dbo.sp_SyncVariantsFromFranklin;';
GO

-- Schedule to run weekly on Sunday at 2 AM
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Weekly Sunday 2AM',
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,  -- Sunday
    @active_start_time = 020000;  -- 2:00 AM
GO

EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Sync Variants from Franklin',
    @schedule_name = N'Weekly Sunday 2AM';
GO
```

## Adding More Custom Attributes

To add more custom attributes (e.g., "StorageTemp"):

1. **Add column to VariantAttributes table**:
```sql
ALTER TABLE dbo.VariantAttributes
ADD StorageTemp NVARCHAR(50);
```

2. **Update view** (recreate view to include new column)

3. **Add to schema in R** (`f_browser_variants.R`):
```r
StorageTemp = list(
  type = "text",
  label = "Storage Temperature",
  placeholder = "e.g., Cool, Ambient",
  required = FALSE
)
```

4. **Update `update_variant_attributes()`** to handle new field

## Hierarchy Verification

The relationship Variant → Grain Group → Commodity should always be consistent. To verify:

```sql
-- Check for variants with same grain group but different commodities
SELECT GrainGroup, COUNT(DISTINCT Commodity) AS CommodityCount
FROM dbo.Variants
WHERE GrainGroup IS NOT NULL
GROUP BY GrainGroup
HAVING COUNT(DISTINCT Commodity) > 1;

-- Should return 0 rows if hierarchy is clean
```

## Notes

- Variants are **read-only** from Franklin (VariantNo, GrainGroup, Commodity)
- Only custom attributes (BaseColour, Notes, etc.) can be edited
- No "Add New" button - all variants come from Franklin sync
- No "Delete" button - variants are marked as inactive during sync
- Search includes variant number, grain group, and commodity
- Filters cascade: selecting commodity updates grain group options
