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

Keep record on what we are doing in the session_summary.md

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
