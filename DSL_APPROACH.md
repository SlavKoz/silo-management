# 2-Column Form - DSL Approach ✓

## What This Is

This is the **correct approach** using the react_table DSL (Domain Specific Language) that's already in your codebase. The DSL makes it easy to create forms without manually writing JSON schemas.

## Key Insight

The react_table folder contains its own form-building system:
- **react_table_dsl.R** - `field()` and `group()` functions
- **react_table_auto.R** - `rjsf_auto_compile()` function
- **react_table_helpers.R** - data conversion helpers
- **mod_react_table.R** - UI/server functions

These tools generate the schema/uiSchema that's sent to the JavaScript renderer.

## The Pattern (from f_browser_containers.R)

### 1. Define Fields with DSL

```r
auto <- rjsf_auto_compile(
  fields = list(
    # Left column fields
    field("ItemName", "text", title = "Name"),
    field("Quantity", "number", title = "Qty", min = 0),
    field("Category", "select", title = "Category", enum = c("A", "B", "C")),

    # Right column - grouped
    field("Width",  "number", title = "Width",  group = "Specs"),
    field("Height", "number", title = "Height", group = "Specs"),

    field("CreatedAt", "text", title = "Created", group = "Meta")
  ),
  groups = list(
    group("Specs", title = "Specifications", collapsible = TRUE, column = 2),
    group("Meta", title = "Metadata", collapsible = TRUE, column = 2)
  ),
  columns = 2  # KEY: 2-column layout
)
```

### 2. Prepare Form Data

```r
formData <- rjsf_auto_formdata(
  df_row = your_dataframe,
  nest = list(
    Specs = c("Width", "Height"),
    Meta = c("CreatedAt")
  ),
  drop_root = TRUE
)
```

### 3. Send to React

```r
session$sendCustomMessage("react-table-props", list(
  elId = ns("form-root"),
  schema = auto$schema,
  uiSchema = auto$uiSchema,
  formData = formData
))
```

### 4. Protect Fonts with CSS

```r
tags$style(HTML(sprintf("
  #%s .react-table-root,
  #%s .react-table-root input,
  #%s .react-table-root select,
  #%s .react-table-root .form-control {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif !important;
    font-size: 14px !important;
  }
", ns("form"), ns("form"), ns("form"), ns("form"))))
```

This CSS is **critical** - it prevents the main app's styling from overriding form fonts.

## Test Files Created

### R/test_2col_dsl.R
- Clean 2-column form test
- Uses DSL approach (like f_browser_containers.R)
- Includes font protection CSS
- Left: 3 text/number + 1 select
- Right: 2 collapsible groups

### run_test_dsl.R
- Test runner with checks
- Loads all react_table modules
- Verifies files exist

## How to Run

```r
source("run_test_dsl.R")
```

Or directly:
```r
source("R/test_2col_dsl.R")
run_test_2col_dsl()
```

## Expected Result

### Layout
**Left Column:**
- Item Name (text)
- Item Code (text)
- Quantity (number, 0-1000)
- Category (select dropdown: Type A/B/C)

**Right Column:**
- **Specifications** (collapsible, expanded)
  - Width (cm)
  - Height (cm)
  - Weight (kg)
- **Metadata** (collapsible, expanded)
  - Created By (text)
  - Created At (read-only)
  - Updated At (read-only)

### Font Styling
- 14px for inputs/selects
- 12px for textareas
- System font (not overridden by main app)
- **Protected** by scoped CSS

## DSL Field Types

```r
field(name, type, ...)
```

Supported types:
- `"text"` - single line text
- `"textarea"` - multi-line text
- `"number"` / `"integer"` - numeric input
- `"select"` - dropdown (needs `enum` parameter)
- `"color"` - color picker
- `"date"` - date picker
- `"boolean"` / `"checkbox"` - checkbox
- `"switch"` / `"toggle"` - toggle switch

Parameters:
- `title` - field label
- `min`, `max` - for numbers
- `enum` - choices for select
- `default` - default value
- `group` - group name (for right column)
- `column` - force specific column (1 or 2)

## DSL Groups

```r
group(name, title, collapsible, collapsed, column)
```

- `collapsible = TRUE` - can be expanded/collapsed
- `collapsed = TRUE` - starts collapsed
- `column = 2` - force to right column

## Key Differences from Old Approach

| Old (Wrong) | New (DSL - Correct) |
|-------------|---------------------|
| Manual schema/uiSchema JSON | Use `field()` and `compile_rjsf()` |
| Hard to maintain | Easy to read and modify |
| Prone to errors | Type-safe with defaults |
| No examples | Used in f_browser_containers.R |

## Important: Font Protection

Without the scoped CSS, the main app's global styles will override form fonts. The CSS in test_2col_dsl_ui() ensures:

1. **Consistent fonts** across all form elements
2. **Not affected** by general app styling
3. **Same appearance** in test and main app

This is what you meant by "font styling is the same as in our recent tests - as it is being overtaken by general styling when we use this table in the main app".

## Troubleshooting

### Form doesn't appear
1. Check console: `window.renderRJSFGrid` should be a function
2. Check Network: `vendor/rjsf-grid.js` should load (537KB)
3. Check console for errors

### Wrong fonts
- Make sure scoped CSS is present in UI
- Check that ID in CSS matches ns("form")
- Use browser DevTools to inspect font-family

### Not 2 columns
- Verify `columns = 2` in `rjsf_auto_compile()`
- Check console log shows "Columns: 2"
- Groups should have `column = 2`

## Next Steps

Once this works:
1. Adapt for your specific needs
2. Add more field types
3. Add validation
4. Connect to database
5. Add save/edit functionality (see f_browser_containers.R for full example)

## Files Structure

```
R/react_table/
├── react_table_dsl.R          ← DSL: field(), group(), compile_rjsf()
├── react_table_auto.R         ← rjsf_auto_compile(), rjsf_auto_formdata()
├── react_table_helpers.R      ← data conversion helpers
└── mod_react_table.R          ← UI/server functions

R/
├── test_2col_dsl.R            ← NEW: Clean DSL-based test
└── browsers/
    └── f_browser_containers.R ← WORKING EXAMPLE in main app

www/vendor/
└── rjsf-grid.js               ← JavaScript renderer (still needed!)

run_test_dsl.R                 ← Test runner
```

## Summary

✓ Uses react_table DSL (already in codebase)
✓ Font protection CSS (prevents main app override)
✓ 2-column layout with collapsible groups
✓ Based on working example (f_browser_containers.R)
✓ No external dependencies beyond existing setup
✓ Easy to maintain and extend
