Context & token discipline
Keep outputs concise. Default to bullet points and short paragraphs.
Before answering, quickly plan silently; then produce only the final answer.
If a task would exceed token limits, propose a smaller plan ("Step 1/2/3") and ask which parts to run.
When the chat is long, summarize prior turns into 5–8 bullets and discard details unless explicitly requested.
Prefer retrieval (look up only the needed snippets) over pasting large documents.
When listing code/logs, include only minimal, relevant excerpts; offer a downloadable file if the user wants full content.
If you're near the output limit, end with: "I truncated for brevity—ask for any section to expand."
Never repeat unchanged context. Refer back with short labels ("Spec v2 §Auth", "Design A").
For tables longer than 30 rows, provide a compact summary + top 10; offer to filter/page.
For iterative work, carry forward only decisions, constraints, and open questions; compress the rest.



f_or Operator Usage (Mandatory)
ALWAYS use f_or() for null-coalescing, NEVER create or use %||%
  - Syntax: f_or(value, default) returns default if value is NULL, length 0, or NA
  - Example: name <- f_or(input$name, "Unknown")
  - Do NOT define %||% anywhere in the codebase




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


## Files to Read at Session Start

Always read these files at the start of a session:
- `R/utils/f_helper_core.R` - Universal helper functions
- `.claude/deletion_safety.md` - Referential integrity pattern (prevents orphaned records)
- `.claude/cross_module_state.md` - Cross-module synchronization pattern (global state management)
- `table_structures.csv` - Complete database schema (all tables, columns, data types)
- `.claude/conventions.md` - This file (project conventions)

Keep record on what we are doing in the session_summary.md

---

## Browser Module Pattern (f_browser_*.R)

### Standard Browser Structure
All modern browsers follow this pattern (React Table + React List):

```r
# UI - Two-column layout
browser_name_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "ui grid stackable",
        # LEFT — compact list (33%)
        div(class = "five wide column",
            compact_list_ui(ns("list"),
                           show_filter = TRUE,
                           filter_placeholder = "Filter by code/name…")
        ),
        # RIGHT — detail/editor (66%)
        div(class = "eleven wide column",
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
        )
    )
  )
}

# Server - Standard pattern
browser_name_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # 1. Trigger refresh reactive
    trigger_refresh <- reactiveVal(0)

    # 2. Raw data with icon display
    raw_data <- reactive({
      trigger_refresh()
      df <- try(list_items(...), silent = TRUE)
      # Add IconDisplay column if needed
      df
    })

    # 3. Transform for compact list
    list_items <- reactive({
      data.frame(
        id = df$ID,
        icon = df$IconDisplay,
        title = toupper(df$Name),
        description = df$Code,
        stringsAsFactors = FALSE
      )
    })

    # 4. Compact list module
    list_result <- compact_list_server(
      "list",
      items = list_items,
      add_new_item = TRUE,
      initial_selection = "first"
    )
    selected_id <- list_result$selected_id

    # 5. Schema configuration
    schema_config <- reactive({
      list(fields = list(...), columns = 1)
    })

    # 6. Form data reactive
    form_data <- reactive({
      trigger_refresh()
      sid <- selected_id()
      if (is.null(sid)) return(list(...))  # Empty
      if (is.na(sid)) return(list(...))    # New
      # Existing - fetch from DB
      df1 <- try(get_item_by_id(sid), silent = TRUE)
      list(...)  # Return flat structure
    })

    # 7. HTML form module
    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "FieldName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          is_new_record <- is.na(selected_id())
          saved_id <- upsert_item(data)

          if (is_new_record && !is.null(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          trigger_refresh(trigger_refresh() + 1)
          return(TRUE)
        }, error = function(e) {
          # Parse and show error
          showNotification(user_msg, type = "error", duration = NULL)
          form_module$handle_save_failure(field_to_clear)
          return(FALSE)
        })
      },
      on_delete = function() {
        # TODO: Implement with referential integrity check
        return(FALSE)
      }
    )

    # 8. Deep-linking support (if route provided)
    if (!is.null(route) && shiny::is.reactive(route)) {
      # Observe route changes
      # Update URL on selection change
    }

    return(list(selected_item_id = selected_id))
  })
}

# Aliases with f_ prefix
f_browser_name_ui <- browser_name_ui
f_browser_name_server <- function(id, pool, route = NULL) {
  browser_name_server(id, pool, route)
}
```

### Icon Display Patterns

**For tables WITH Icon column (Icons table FK):**
```r
# Fetch icon data
icons_df <- try(list_icons_for_picker(limit = 1000), silent = TRUE)

# Create IconDisplay column
df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
  icon_id <- df$Icon[i]
  if (is.na(icon_id)) {
    return('<div style="display:inline-block; width:32px; height:32px; background:#e5e7eb; border-radius:4px;"></div>')
  }
  icon_row <- icons_df[icons_df$id == icon_id, ]
  if (nrow(icon_row) == 0 || is.na(icon_row$png_32_b64[1])) {
    return('<div style="display:inline-block; width:32px; height:32px; background:#e5e7eb; border-radius:4px;"></div>')
  }
  sprintf('<img src="data:image/png;base64,%s" style="width:32px; height:32px; border-radius:4px;" />',
          icon_row$png_32_b64[1])
}, character(1))
```

**For tables WITHOUT Icon column (code-based badge):**
```r
# Create 3-letter code badge
df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
  code_3 <- toupper(substr(df$Code[i], 1, 3))
  sprintf(
    '<div style="display:inline-block; width:32px; height:32px; background:#059669; color:#fff; font-weight:bold; font-size:11px; text-align:center; line-height:32px; border-radius:4px;">%s</div>',
    code_3
  )
}, character(1))
```

### Deep-Linking Pattern

**For simple routes (e.g., #/sites/SITECODE):**
```r
observeEvent(route(), {
  parts <- route()
  if (length(parts) >= 1 && parts[1] == "sites") {
    if (length(parts) >= 2) {
      code <- parts[2]
      # Find and select item by code
      row <- df[trimws(df$Code) == trimws(code), ]
      if (nrow(row) > 0) {
        list_result$select_item(as.integer(row$ID[1]))
      }
    }
  }
}, ignoreInit = TRUE)
```

**For nested routes (e.g., #/actions/operations/OPCODE):**
```r
observeEvent(route(), {
  parts <- route()
  if (length(parts) >= 2 && parts[1] == "actions" && parts[2] == "operations") {
    if (length(parts) >= 3) {
      code <- parts[3]
      # Find and select
    }
  }
}, ignoreInit = TRUE)
```

**For composite codes (e.g., #/areas/SITECODE-AREACODE):**
```r
observeEvent(route(), {
  parts <- route()
  if (length(parts) >= 2 && parts[1] == "areas") {
    composite <- parts[2]
    if (grepl("-", composite, fixed = TRUE)) {
      code_parts <- strsplit(composite, "-", fixed = TRUE)[[1]]
      site_code <- trimws(code_parts[1])
      area_code <- trimws(paste(code_parts[-1], collapse = "-"))
      # Find by composite
    }
  }
}, ignoreInit = TRUE)
```

### Error Handling Pattern

```r
error = function(e) {
  error_msg <- conditionMessage(e)
  cat("[Save Error]:", error_msg, "\n")

  field_to_clear <- NULL
  user_msg <- NULL

  if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
    field_to_clear <- "Code"
    if (grepl("duplicate key value is \\(([^)]+)\\)", error_msg, ignore.case = TRUE)) {
      dup_value <- gsub(".*duplicate key value is \\(([^)]+)\\).*", "\\1", error_msg, ignore.case = TRUE)
      user_msg <- paste0("Cannot save: Code '", dup_value, "' already exists.")
    } else {
      user_msg <- "Cannot save: This code already exists."
    }
  } else if (grepl("NULL", error_msg, ignore.case = TRUE) && grepl("cannot insert", error_msg, ignore.case = TRUE)) {
    user_msg <- "Cannot save: Required field is missing."
  } else {
    user_msg <- paste0("Database error: ", substr(error_msg, 1, 200))
  }

  showNotification(user_msg, type = "error", duration = NULL)
  form_module$handle_save_failure(field_to_clear)
  return(FALSE)
}
```

### Cross-Module State Management

**Icon changes refresh dependencies:**
```r
# In form_data reactive
if (!is.null(session$userData$icons_version)) {
  session$userData$icons_version  # Depend on it
}
```

**On save, increment version:**
```r
# In on_save callback
if (!is.null(session$userData$icons_version)) {
  session$userData$icons_version <- session$userData$icons_version + 1
}
```

### Wiring in App Server

```r
# In route_map
"items" = list(
  title = "Items",
  ui = function() {
    if (exists("f_browser_items_ui")) f_browser_items_ui("items")
    else div("Placeholder")
  },
  server = function() {
    if (exists("f_browser_items_server")) f_browser_items_server("items", pool, route = current)
  }
)

# In icon_map
"items" = "icon-class"

# In sidebar_structure
list(key = "items@single", title = "Items", items = c("items"))
```

---

## Universal Helper Functions (from f_helper_core.R)

### f_scoped_css() - For ID-based CSS scoping
**When to use**: Creating module CSS that targets by ID (e.g., `#module_id .class`)

```r
# Automatically scopes CSS rules to a module ID
f_scoped_css(ns("form"), c(
  ".my-class { color: red; }",
  ".another-class { font-size: 12px; }"
))
# Generates: #module-ns-form .my-class { color: red; } ...
```

**When NOT to use**:
- Class-based scoping (e.g., `.cl-container-{id}`)
- Mixed placeholders (use auto-count pattern instead)

### f_or() - Null coalescing (MANDATORY)
**Always use** `f_or(value, default)` instead of `%||%`

```r
name <- f_or(input$name, "Unknown")
```

---

## CSS in mod_html_form.R

**BEST PRACTICE**: Use auto-counting for sprintf placeholders (prevents errors):

```r
# Define template first
css_template <- "
  #%s .class1 { ... }
  #%s .class2 { ... }
"

# Auto-count and apply
n_css <- length(gregexpr("%s", css_template, fixed = TRUE)[[1]])
tags$style(HTML(do.call(sprintf, c(list(css_template), rep(list(ns("form")), n_css)))))
```

**For JavaScript with mixed args:**
```r
js_template <- "const id = '%s'; window['func_%s'] = ..."
n_js <- length(gregexpr("%s", js_template, fixed = TRUE)[[1]])
js_args <- list(js_template, ns("form"))
for (i in 2:n_js) js_args[[i+1]] <- gsub("-", "_", ns("form"))
tags$script(HTML(do.call(sprintf, js_args)))
```

**Why:** No manual counting = no sprintf argument mismatch errors!
