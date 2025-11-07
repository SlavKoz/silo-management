# React Table / HTML Form - Instructions & Session Log

## Project Overview
Creating a prototype table/form system that will later be implemented in many tabs in the main app.r. Currently focusing on `test_html_form.R` as the prototype.

## Goals
- Store all form-related functionality in `R/react_table/` directory for reusability
- Create an easy-to-use API for calling, modifying, and returning form data
- Avoid dependency on large vendor file (`www/vendor/rjsf-grid.js`)
- Re-implement needed functionality within the `react_table` directory

## Directory Structure
```
R/react_table/
├── react_table_dsl.R          # DSL for defining form schemas
├── react_table_auto.R         # Auto-compilation of DSL to JSON schema
├── react_table_helpers.R      # Helper functions
├── html_form_renderer.R       # Pure R/HTML form renderer (no JS dependencies)
└── mod_react_table.R          # Shiny module for table functionality
```

## Key Files

### Test File
- **R/test_html_form.R** - Main test file for the prototype
  - Uses pure HTML rendering (NO vendor JS needed)
  - Implements editable forms with Edit/Save toggle
  - Bootstrap 5 for styling
  - Two-column layout support

### Core Components
1. **html_form_renderer.R** - Renders forms from DSL schema as native HTML
   - `render_html_form()` - Main rendering function
   - `render_field()` - Renders individual fields
   - `render_input()` - Renders different input types
   - Supports: text, number, select, textarea, color inputs
   - Handles groups (collapsible/non-collapsible)
   - Supports static (read-only) fields

2. **DSL System** - Declarative form definition
   - `field()` - Define form fields with validation
   - `group()` - Group fields together
   - `rjsf_auto_compile()` - Compile DSL to JSON schema

## API Usage Example

### Basic 2-Column Layout
```r
# Define form schema using DSL
auto <- rjsf_auto_compile(
  fields = list(
    field("ItemName", "text", title = "Item Name"),
    field("Quantity", "number", title = "Quantity", min = 0, max = 1000),
    field("Category", "select", title = "Category",
          enum = c("Type A", "Type B", "Type C")),
    field("Width", "number", title = "Width (cm)", group = "Specs")
  ),
  groups = list(
    group("Specs", title = "Specifications", collapsible = TRUE, column = 2)
  ),
  columns = 2,  # Creates 2-column layout
  static_fields = c("Metadata.CreatedAt", "Metadata.UpdatedAt")
)

# Render form
output$form_content <- renderUI({
  render_html_form(
    schema = auto$schema,
    uiSchema = auto$uiSchema,
    formData = your_data,
    ns_prefix = ns("field_"),
    show_header = TRUE,
    title_field = "ItemName"
  )
})
```

### 4-Column Layout
```r
auto <- rjsf_auto_compile(
  fields = list(
    # Column 1
    field("ItemName", "text", title = "Item Name", column = 1),
    field("ItemCode", "text", title = "Item Code", column = 1),

    # Column 2
    field("Quantity", "number", title = "Quantity", column = 2),
    field("Category", "select", title = "Category",
          enum = c("A", "B", "C"), column = 2),

    # Column 3 - Grouped fields
    field("Width", "number", title = "Width", group = "Specs"),
    field("Height", "number", title = "Height", group = "Specs"),

    # Column 4 - Another group
    field("CreatedAt", "text", title = "Created", group = "Meta")
  ),
  groups = list(
    group("Specs", title = "Specifications", column = 3),
    group("Meta", title = "Metadata", column = 4)
  ),
  columns = 4  # Creates 4-column layout
)
```

## Summary of Completed Work

### ✅ All Core Functionality Working
1. **Edit/Lock Toggle** - Forms load in locked mode, become editable with Edit button
2. **Static Fields** - Display-only fields render as plain text (no frames, never editable)
3. **Multi-Column Layout (1-4 columns)** - Flexible responsive layout with field grouping
4. **Pure HTML Rendering** - No dependency on vendor JS files
5. **Header Title Management** - Static header separate from body fields
6. **Per-Group Collapse Control** - Each group can start open or collapsed
7. **Inline Labels** - Labels appear next to fields (25% / 75% split)
8. **Color Picker Support** - Native HTML5 color picker field type

---

## Current Issues & Fixes

### Issue 1: Fields Editable on Open (FIXED)
**Problem**: Fields were editable immediately when the form loads, but should be read-only until the "Edit" button is clicked.

**Root Cause**: The `render_input()` function wasn't setting initial `readonly` and `disabled` attributes. The DOMContentLoaded JavaScript couldn't catch the form elements because Shiny's `renderUI()` happens after page load.

**Solution**: Modified `R/react_table/html_form_renderer.R` to add initial locked state attributes:
- Text inputs: Added `readonly="readonly"` and `disabled="disabled"` (lines 223-224)
- Number inputs: Added `readonly="readonly"` and `disabled="disabled"` (lines 201-202)
- Textareas: Added `readonly="readonly"` and `disabled="disabled"` (lines 170-171)
- Select dropdowns: Added `disabled="disabled"` (line 186)
- Color pickers: Added `disabled="disabled"` (line 213)

**Status**: ✅ FIXED - Forms now load in locked mode and respond to Edit/Save toggle correctly.

### Issue 2: Static Fields Not Working (FIXED)
**Problem**: Fields marked as static (via `static_fields` parameter) were still rendering as editable inputs with frames.

**Root Cause**: The `set_ui_at()` function in `react_table_auto.R` couldn't properly handle nested paths like "Metadata.CreatedAt". It was only working for root-level fields.

**Solution**: Complete rewrite of `set_ui_at()` with:
- `build_nested()` helper - recursively builds proper nested list structures
- `get_ui_at()` helper - retrieves existing values at any depth
- Proper merging to preserve existing UI settings while adding new ones

**Additional Fix**: Font size was too large
- Set to 10px (smaller than editable fields at 14px)
- Added `!important` flag to prevent style inheritance
- Added matching line-height (1.25rem)

**Status**: ✅ FIXED - Static fields now render as plain text with correct styling (10px font, gray text, no frames).

---

## Session History & Token Tracking

### Session 1 (Token Limit Reached)
- **Date**: [Previous session - exact date unknown]
- **File**: `run_html_test.R`
- **Outcome**: Ran out of tokens
- **Tasks Attempted**: [To be documented]
- **Results**: [To be documented]
- **Token Usage**: Unknown

---

### Session 2 (Current)
- **Date**: 2025-11-06
- **Token Budget**: 200,000 tokens
- **Tasks Completed**:

#### Task Set 1: Initial Setup & Fix Editability Issue
- Created comprehensive `REACT_TABLE_INSTRUCTIONS.md` documentation
- Reviewed `R/test_html_form.R` and `R/react_table/html_form_renderer.R`
- Fixed fields being editable on form open:
  - Modified `html_form_renderer.R` to add initial `readonly` and `disabled` attributes
  - Applied to all input types (text, number, textarea, select, color)
- **Result**: ✅ Forms now load in locked mode correctly
- **Tokens Remaining After Task**: ~175,000 tokens (used ~25,000)

#### Task Set 2: Static Fields Enhancement & Bug Fix
- Reviewed static fields implementation in `react_table_auto.R`
- Enhanced static field rendering in `html_form_renderer.R`:
  - Added `data-static="true"` attribute for identification
  - Improved inline styling for consistency
  - Documented complete implementation
- **CRITICAL BUG FOUND & FIXED**: Static fields were not working
  - **Root Cause**: `set_ui_at()` function in `react_table_auto.R` couldn't handle nested paths like "Metadata.CreatedAt"
  - **Solution**: Rewrote `set_ui_at()` with proper nested path handling using helper functions:
    - `build_nested()` - recursively builds nested list structure
    - `get_ui_at()` - retrieves existing values at nested paths
    - Proper merging with `modifyList()` to preserve existing settings
- Fixed static field font size to match other fields (14px with !important flag)
- Removed all debug statements from code
- **Result**: ✅ Static fields now render correctly as plain text with no frames
- **Tokens Remaining After Task**: ~147,000 tokens (used ~53,000 total)

#### Task Set 3: Inline Labels & Multiple Enhancements
- Documented revert point for label position (Revert Point 1)
- Modified `render_field()` in `html_form_renderer.R` to use Bootstrap grid layout:
  - Labels now inline on the left (col-sm-3, 25% width)
  - Fields inline on the right (col-sm-9, 75% width)
  - Used `align-items-center` for vertical alignment
  - Changed label class from `form-label` to `col-form-label` for proper inline styling
- **Header Title Made Static**: Modified `test_html_form.R`
  - Removed JavaScript code that made title editable in edit mode (line 153-155)
  - Removed CSS styling for editable title (lines 76-82)
  - Header title now always stays readonly, even in edit mode
  - This allows managing the title separately (e.g., computed from multiple fields)
- **Individual Group Collapse Control**:
  - Set Metadata group to start collapsed (`collapsed = TRUE`)
  - Set Specs group to start open (`collapsed = FALSE`)
  - Each group can have its own initial state
- **Additional Static Field**: Added `CreatedBy` to static fields list
- **Color Picker Example**: Added "Label Color" field to Specs group
  - Uses `field("Color", "color", ...)` syntax
  - Renders as native HTML5 color picker
  - Sample value: `"#3498db"` (hex color format)
- **Result**: ✅ All enhancements complete - narrower labels, static header, per-group collapse, color picker
- **Tokens Remaining After Task**: ~132,000 tokens (used ~68,000 total)

#### Task Set 4: Dynamic Multi-Column Support (1-4 Columns)
- **Rewrote column rendering system** in `html_form_renderer.R`:
  - Removed hardcoded 2-column logic
  - Implemented dynamic column distribution (supports 1-4 columns)
  - Fields distributed to columns based on `column` parameter in field/group definition
  - Automatic Bootstrap grid class calculation (col-md-12, col-md-6, col-md-4, col-md-3)
  - Border dividers automatically added between columns (except last)
- **Updated test to 4-column layout**:
  - Column 1: ItemName, ItemCode
  - Column 2: Quantity, Category
  - Column 3: Specs group (Width, Height, Weight, Color)
  - Column 4: Metadata group (CreatedBy, CreatedAt, UpdatedAt)
- **Enhanced CSS** for flexible column spacing:
  - Generic column spacing rules work for any column count
  - First/last column padding adjustments
  - Border divider styling
- **Result**: ✅ Forms now support 1-4 columns via simple `columns` parameter
- **Tokens Remaining After Task**: ~120,000 tokens (used ~80,000 total)

#### Task Set 5: Bug Fixes - Column Assignment & Visual Frame
- **Fixed Critical Column Assignment Bug** in `react_table_dsl.R`:
  - **Root Cause**: `set_field_ui()` function wasn't actually storing column values in uiSchema
  - Old code used `<<-` with `.set_nested()` incorrectly, values were lost
  - **Solution**: Rewrote to directly assign to nested structures like `ensure_group()` does
  - Now properly stores: `root[[name]][["ui:options"]] <- modifyList(...)`
- **Added Visual Frame Around Form**:
  - Wrapped entire form (header + columns) in bordered container with shadow
  - CSS class: `.form-wrapper` with border, rounded corners, padding, box-shadow
- **Fixed Label Overlap Issue**:
  - Problem: Bootstrap `.row` has negative margins that break out of container
  - Solution: Override row margins to 0 inside `.form-wrapper`
  - Added label truncation and padding for proper spacing
  - Simplified column spacing with margin/padding on `.border-end` only
- **Updated Test to 3-Column Layout**:
  - Column 1: ItemName, ItemCode, Quantity
  - Column 2: Category, Width, Height, Weight, Color (5 fields)
  - Column 3: Metadata group (CreatedBy, CreatedAt, UpdatedAt - all static)
- **Result**: ✅ Column assignment working, visual frame contains all content, no overlap
- **Tokens Remaining After Task**: ~99,000 tokens (used ~101,000 total)

#### Task Set 6: Fixed Column Wrapping Issue
- **Critical Bug Found**: Columns were wrapping to next line
  - **Root Cause**: Bootstrap's default flex behavior allows columns to wrap when container is narrow
  - **Symptom**: Third column appeared below first two columns instead of side-by-side
  - **Solution**: Added `flex-nowrap` class to the row div in `html_form_renderer.R`
  - This forces all columns to stay on one line regardless of container width
- **Fixed Label Truncation**:
  - Removed `text-truncate` class from labels (was cutting off long labels with ellipsis)
  - Added `word-wrap: break-word` to allow labels to wrap onto multiple lines
  - Labels now display fully even if long
- **IMPORTANT NOTE**: For multi-column layouts (2-4 columns), always use `flex-nowrap` on the row container to prevent columns from wrapping vertically
- **Result**: ✅ All 3 columns display side-by-side, labels wrap properly
- **Tokens Remaining After Task**: ~74,000 tokens (used ~126,000 total)

---

### Token Tracking Guidelines
After each set of related tasks, record:
1. Tasks completed
2. Files modified
3. Results achieved
4. **Tokens remaining** (check system warnings)

This helps estimate remaining capacity for future tasks in the session.

---

## Revert Points (Backup States)

### Revert Point 1: Label Position (Before Inline Change)
**Date**: 2025-11-06
**File**: `R/react_table/html_form_renderer.R`
**Lines**: 129-133

**Original Code (Labels Above Fields)**:
```r
  } else {
    # Regular field
    div(class = "mb-3",
      tags$label(`for` = paste0(ns_prefix, name), class = "form-label", title),
      render_input(name, schema, ui, value, is_plaintext, ns_prefix)
    )
  }
```

**Description**: Labels appear above their corresponding inputs/outputs (stacked vertically).

---

## Technical Notes

### Edit Mode Toggle System
- Uses CSS class `.edit-mode` on body element
- Button has `.editing` class when in edit mode
- Title input has special styling (transparent when locked)
- JavaScript function `toggleEditMode()` handles state changes
- **Header title is always readonly** - never becomes editable, even in edit mode

### Header Title Management
The header title input is intentionally kept static (non-editable) to allow flexible management:

**Use Cases**:
- Computed from multiple fields (e.g., `ItemCode + " - " + ItemName`)
- Auto-generated (e.g., timestamps, IDs)
- Managed by server-side logic

**Implementation**:
```r
# In your server logic, compute title from form data
computed_title <- paste(formData$ItemCode, "-", formData$ItemName)

# Pass to render_html_form via title_field parameter
render_html_form(
  schema = auto$schema,
  uiSchema = auto$uiSchema,
  formData = modifyList(formData, list(ItemName = computed_title)),
  title_field = "ItemName",  # This field value shows in header
  show_header = TRUE
)
```

The body can still have an editable "ItemName" field - it's separate from the header display.

### Static Fields (Non-Editable Display Fields)
Static fields are for displaying data that should NEVER be editable (e.g., "Created At", "Updated At", "System ID").

**Key Features**:
- No input frame or border - rendered as plain text
- Smaller font size (10px) compared to editable fields (14px)
- Styled with gray color (#6c757d) to indicate read-only status
- Never affected by Edit/Save toggle - always displayed as text
- Uses CSS class `.form-static-value` for consistent styling
- Marked with `data-static="true"` attribute for easy identification

**Implementation**:
1. **Define in DSL**: Use `static_fields` parameter in `rjsf_auto_compile()`
   ```r
   static_fields = c("Metadata.CreatedAt", "Metadata.UpdatedAt", "SystemID")
   ```

2. **Compiler Processing**: `react_table_auto.R` (line 72) sets `ui:field = "plaintext"` for each static field

3. **Rendering**: `html_form_renderer.R` (lines 160-167) detects plaintext fields and renders as `div` instead of `input`

**Example**:
```r
# In your schema definition
auto <- rjsf_auto_compile(
  fields = list(
    field("ItemName", "text", title = "Item Name"),
    field("CreatedAt", "text", title = "Created At", group = "Metadata"),
    field("UpdatedAt", "text", title = "Updated At", group = "Metadata")
  ),
  groups = list(
    group("Metadata", title = "Metadata", column = 2)
  ),
  static_fields = c("Metadata.CreatedAt", "Metadata.UpdatedAt")  # These won't be editable
)
```

**Visual Result**:
- Static fields appear as plain text with no border
- Gray color indicates they are informational only
- Other fields have input frames and can be edited when Edit mode is active

### Multi-Column Layout System (1-4 Columns)

The form system supports flexible column layouts from 1 to 4 columns.

**How It Works**:
1. Set total columns with `columns` parameter in `rjsf_auto_compile()`
2. Assign fields to specific columns using `column` parameter in `field()` or `group()`
3. Fields without explicit column assignment go to column 1 by default

**Column Width Distribution**:
- **1 column**: Full width (col-md-12, 100%)
- **2 columns**: Half width each (col-md-6, 50%)
- **3 columns**: Third width each (col-md-4, 33%)
- **4 columns**: Quarter width each (col-md-3, 25%)

**Example - 3 Column Layout**:
```r
auto <- rjsf_auto_compile(
  fields = list(
    # Column 1 (default if no column specified)
    field("Name", "text", title = "Name"),
    field("Email", "text", title = "Email"),

    # Column 2
    field("Phone", "text", title = "Phone", column = 2),
    field("Age", "number", title = "Age", column = 2),

    # Column 3 - Group
    field("Street", "text", title = "Street", group = "Address"),
    field("City", "text", title = "City", group = "Address")
  ),
  groups = list(
    group("Address", title = "Address", column = 3)
  ),
  columns = 3  # Creates 3-column layout
)
```

**Important Notes**:
- Grouped fields inherit their group's column assignment
- Individual fields in a group cannot be in different columns
- Column numbers are clamped to valid range (if you specify column 5 with 3 columns, it goes to column 3)
- Border dividers automatically appear between columns

### Group Collapse Control
Each group can have its own initial collapse state:

```r
groups = list(
  group("Specs", title = "Specifications",
        collapsible = TRUE, collapsed = FALSE, column = 2),  # Starts OPEN
  group("Metadata", title = "Metadata",
        collapsible = TRUE, collapsed = TRUE, column = 2)    # Starts COLLAPSED
)
```

- `collapsible = TRUE` - Group can be expanded/collapsed by clicking
- `collapsed = FALSE` - Group starts open
- `collapsed = TRUE` - Group starts collapsed
- `column = 2` - Places group in second column (for 2-column layouts)

### Field Types Available
- **Text**: `field("Name", "text", ...)`
- **Number**: `field("Age", "number", min = 0, max = 150, ...)`
- **Select**: `field("Type", "select", enum = c("A", "B", "C"), ...)`
- **Color Picker**: `field("Color", "color", ...)` - Returns hex values like "#3498db"
- **Textarea**: `field("Notes", "textarea", ...)` (via widget parameter)
- More types available - see DSL documentation

### Styling
- Bootstrap 5 from CDN
- Bootstrap Icons for edit/save buttons
- Compact form controls (2rem height)
- Two-column layout with border divider
- Font protection to prevent Shiny defaults
- Inline labels (25% width) with fields (75% width)

---

## Future Enhancements
- [ ] Add form validation
- [ ] Implement data persistence
- [ ] Add change tracking
- [ ] Create more field types (date, time, file upload)
- [ ] Add conditional field visibility
- [ ] Implement field dependencies
