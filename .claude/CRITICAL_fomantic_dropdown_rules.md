# 🚨 CRITICAL: Fomantic UI Dropdown Rules 🚨

**PRIORITY: ALWAYS READ THIS BEFORE TOUCHING dropdown_input CODE**

## ✅ CORRECT FORMAT (TESTED & CONFIRMED WORKING)

### Use Separate `choices` and `choices_value` Parameters

**KEY INSIGHT:** Fomantic `dropdown_input` requires TWO separate vectors, NOT a named vector or list.

```r
shiny.semantic::dropdown_input(
  input_id      = "my_dropdown",
  choices       = c("Display Text 1", "Display Text 2", "Display Text 3"),  # Labels shown to user
  choices_value = c(1, 2, 3),                                                # IDs sent to server
  value         = 1,                                                         # Default selection (by ID)
  type          = "selection"
)
```

**Parameters:**
- **choices** = Vector of display text (what user SEES)
- **choices_value** = Vector of IDs/values (what server RECEIVES)
- Must be same length, same order
- **value** = Default selection using ID from choices_value
- **type** = "selection" or "selection fluid"

### Complete Working Example:

```r
# UI
shiny.semantic::dropdown_input(
  ns("layout_id"),
  choices       = c("Overview", "DDD", "gggg"),
  choices_value = c(1, 2, 3),
  value         = 1,
  type          = "selection fluid"
)
```

**Result:**
- User sees: "Overview", "DDD", "gggg" ✅
- User selects: "Overview"
- Server receives: `"1"` (as character) ✅
- Convert with: `as.integer(input$layout_id)` ✅

## 🔧 Implementation with Real Database Data

### Populating Choices (in observe block):

```r
# For layouts dropdown:
observe({
  req(route)
  req(length(route()) > 0 && route()[1] == "placements")

  layouts <- layouts_data()

  if (nrow(layouts) > 0) {
    current_id <- isolate(current_layout_id())

    shiny.semantic::update_dropdown_input(
      session,
      input_id = "layout_id",
      choices = layouts$LayoutName,        # Display names
      choices_value = layouts$LayoutID,    # Return IDs
      value = current_id                   # Pre-select current
    )
  }
})

# For sites dropdown:
observe({
  req(route)
  req(length(route()) > 0 && route()[1] == "placements")

  sites <- sites_data()

  if (nrow(sites) > 0) {
    site_labels <- paste0(sites$SiteCode, " - ", sites$SiteName)

    shiny.semantic::update_dropdown_input(
      session,
      input_id = "layout_site_id",
      choices = site_labels,           # Display labels
      choices_value = sites$SiteID     # Return IDs
      # No value = shows placeholder
    )
  }
})
```

### Updating Selection (cascade behavior):

```r
# When layout changes, update site selection:
observe({
  layout <- current_layout()

  # Convert NULL/NA to empty string for Fomantic
  site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) {
    ""
  } else {
    as.character(layout$SiteID)
  }

  # Update just the value, not the choices
  shiny.semantic::update_dropdown_input(
    session,
    input_id = "layout_site_id",
    value = site_id
  )
})

```

## 🎯 Handling NULL/Empty Values

### Empty String for NULL Values:
```r
# Convert NULL/NA to empty string
site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) {
  ""
} else {
  as.character(layout$SiteID)
}

# Empty string shows placeholder text in dropdown
update_dropdown_input(session, "layout_site_id", value = "")
```

**Important:**
- Empty string `""` is valid for `value` parameter
- Shows placeholder text when value is `""`
- No need for "(None)" option in choices
- DO NOT use `c("" = "(None)")` - causes "zero-length variable name" error

### Reading Input Values:
```r
# Input returns as CHARACTER, always convert to integer if needed
observeEvent(input$layout_id, {
  selected_value <- input$layout_id
  # selected_value is "1", "2", "3" etc (character)

  layout_id <- as.integer(selected_value)  # Convert to integer
  current_layout_id(layout_id)
})
```

## ❌ Common Mistakes to AVOID

### 1. Using Named Vectors (WRONG):
```r
# ❌ DOES NOT WORK
choices <- c("Overview" = 1, "DDD" = 2)
# ❌ DOES NOT WORK
choices <- setNames(layouts$LayoutID, layouts$LayoutName)
```

### 2. Using Lists (WRONG):
```r
# ❌ DOES NOT WORK
choices <- list("Overview" = 1, "DDD" = 2)
```

### 3. Empty String in Named Vector (SYNTAX ERROR):
```r
# ❌ SYNTAX ERROR - zero-length variable name
choices <- c("" = "(None)")
# Use empty string in choices_value instead:
choices <- c("(None)")
choices_value <- c("")
```

### 4. Forgetting to Convert to Integer:
```r
# ❌ Returns character, causes coercion warnings
layout_id <- input$layout_id  # "1" not 1

# ✅ Correct
layout_id <- as.integer(input$layout_id)
```

## ✅ Summary

**What Works:**
- ✅ Separate `choices` and `choices_value` vectors
- ✅ Empty string `""` for NULL values
- ✅ Returns character, convert with `as.integer()`
- ✅ Cascading updates using just `value` parameter

**What Doesn't Work:**
- ❌ Named vectors `c("Name" = value)`
- ❌ Named lists `list("Name" = value)`
- ❌ `setNames()` approach
- ❌ Empty string as name in c() syntax

**Tested & Confirmed:**
- Populates correctly ✅
- Displays names correctly ✅
- Returns IDs correctly ✅
- Cascades with NULL values ✅
