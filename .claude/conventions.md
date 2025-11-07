# Project Conventions & Naming

## Component Naming

### React Table
**What it is**: The HTML form module (mod_html_form.R + html_form_renderer.R)
**Usage**: Display/edit structured data with fields, groups, columns
**Files**:
- `R/react_table/mod_html_form.R` - Main module
- `R/react_table/html_form_renderer.R` - Renderer

**When user says "react table"**, they mean this form component.

### React List
**What it is**: The compact list module (f_mod_compact_list.R)
**Usage**: Left-side filterable list for browsing/selecting items
**Files**:
- `R/utils/f_mod_compact_list.R` - Main module

**When user says "react list"**, they mean this list component.

---

## Formatting Change Protocol

**IMPORTANT**: When user requests formatting changes to React Table or React List:

### ALWAYS ASK FIRST:
> "Should this change be applied **globally** (all instances) or **locally** (this instance only)?"

### If GLOBAL:
- **React Table**: Modify `R/react_table/mod_html_form.R` CSS section (lines 25-145)
- **React List**: Modify `R/utils/f_mod_compact_list.R` CSS section

### If LOCAL:
- Add instance-specific CSS in the calling file (e.g., f_browser_containers.R)
- Use scoped CSS targeting the specific module ID

**Never assume global vs local - always ask!**

---

## Session Tracking

### Token & Time Warnings
- **Token Budget**: 200,000 tokens per session
- **Time Window**: 5 hours total
- **Warn user at**:
  - ~180,000 tokens used
  - ~4.5 hours elapsed
- **Track in every response** (tokens used/remaining, time elapsed)

### Session Start Timestamp
Record at start of session (from user or system time):
- Current session started: ~2025-11-07 [time user specified]
- Always note time elapsed in responses

---

## File Organization

### React Table (Form Module)
```
R/react_table/
├── react_table_dsl.R           # DSL for defining schemas
├── react_table_auto.R          # Schema compiler
├── html_form_renderer.R        # Pure HTML renderer
└── mod_html_form.R            # Generic reusable module ⭐
```

### React List (Compact List)
```
R/utils/
└── f_mod_compact_list.R       # Generic reusable list module
```

---

## Current Form Styling Standards

### React Table
- **Header**: 3rem, extra bold (900), blue (#2563eb), uppercase
- **Labels**: 11px, normal weight, 33.33% width (col-sm-4)
- **Inputs**: 11px, 66.67% width (col-sm-8)
- **Static fields**: 10px, gray (#6c757d)
- **Group headers**: 11px, normal weight (same as labels)
- **Columns**: Supports 1-4 columns
- **Buttons**: 12px font, 0.25rem 0.5rem padding
- **Header/Footer padding**: 0.375rem
- **Field spacing**: 0.5rem between consecutive inputs (mb-3 override)
- **Delete button**: Auto-disabled when title is empty (add new mode)
- **Edit toggle**: Console logging enabled for debugging

### React List
- (To be documented after template changes)

---

## Common Patterns

### Using React Table
```r
# UI
mod_html_form_ui("unique_id")

# Server
mod_html_form_server(
  id = "unique_id",
  schema_config = list(fields = ..., groups = ..., columns = 2),
  form_data = reactive_or_static_data,
  title_field = "FieldName",
  show_header = TRUE
)
```

### Using React List
```r
# UI
compact_list_ui("list_id", show_filter = TRUE)

# Server
compact_list_server("list_id", items = reactive_items, add_new_item = TRUE)
```
