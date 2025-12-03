# Dropdown Population Issue in Router Context

## Problem Statement

The SiloPlacements browser worked correctly when run standalone but dropdown inputs failed to populate when embedded in the app's hash router via `renderUI`.

**Symptoms:**
- Layout dropdown: ✅ Eventually fixed
- Site dropdown: ❌ Never populated
- Canvas/Area dropdowns: ❌ Did not update on layout change
- Shape templates: ❌ Showed "Loading..." forever

## Root Causes

### 1. Timing Issue with renderUI and Input Bindings

When UI is dynamically rendered via `renderUI`:

```r
output$f_route_outlet <- renderUI({ info$ui() })
```

**Timeline:**
1. Navigate to route
2. `renderUI` fires → HTML sent to browser
3. Server-side observers fire **immediately**
4. `updateSelectInput()` called
5. ❌ **Shiny JavaScript binding not ready yet**
6. 50-100ms later → Binding initializes (too late)

**Standalone app (works):**
1. App starts
2. UI rendered statically at startup
3. Bindings initialize
4. Server code runs
5. ✅ `updateSelectInput` works

### 2. Empty choices Vector

```r
# This prevents input binding from being created:
selectInput(ns("layout_site_id"), choices = c(), ...)
```

When `choices = c()` (completely empty), Shiny may not properly create the input binding at all. The input watcher never fires because the input never appears in the DOM.

**Solution:** Provide at least one initial choice:
```r
selectInput(ns("layout_site_id"), choices = c("Loading..." = ""), ...)
```

### 3. Selectize.js vs Standard Select

**selectize = TRUE:**
- Shiny replaces `<select>` with complex div structure
- `document.getElementById()` won't find the original `<select>`
- JavaScript DOM manipulation fails
- Works fine with `updateSelectInput()` (Shiny handles the complexity)

**selectize = FALSE:**
- Standard HTML `<select>` element
- `document.getElementById()` works
- JavaScript DOM manipulation possible
- But `updateSelectInput()` may fail with renderUI timing issues

### 4. Wrapper Divs

```r
# This breaks input detection:
div(
  style = "position: relative;",
  div(id = ns("select_container"),
    selectInput(ns("layout_id"), ...)
  )
)

# This works:
selectInput(ns("layout_id"), ...)
```

Wrapper divs around selectInput prevent Shiny from properly detecting and binding to the input.

### 5. Circular Reactive Dependencies

```r
# This creates infinite loop:
observe({
  layouts <- layouts_data()
  if (!is.null(input$layout_id)) {  # ❌ Creates reactive dependency
    updateSelectInput(...)
  }
})

# Solution:
observe({
  layouts <- layouts_data()
  input_exists <- isolate(!is.null(input$layout_id))  # ✅ No dependency
  if (!input_exists) return()
  # ... update code
})
```

## Solution Strategy

### For Main Toolbar Dropdowns (in renderUI context)

These are the dropdowns in the top toolbar that's dynamically rendered.

**Affected:** `layout_id`, `layout_site_id`

**UI Definition:**
```r
selectInput(
  ns("layout_id"),
  label = NULL,
  choices = c("Loading..." = ""),  # ✅ Initial choice
  width = "100%",
  selectize = FALSE  # ✅ Standard select for JS manipulation
)
```

**Population Observer:**
```r
observe({
  cat("[", id, "] Layout dropdown observer fired\n")
  layouts <- layouts_data()  # Only reactive dependency

  input_exists <- isolate(!is.null(input$layout_id))  # ✅ No circular dep
  if (!input_exists) return()

  if (nrow(layouts) > 0) {
    choices <- setNames(layouts$LayoutID, layouts$LayoutName)
    choices_json <- jsonlite::toJSON(as.list(choices), auto_unbox = TRUE)
    selected_value <- unname(choices[1])

    # ✅ Direct JavaScript DOM manipulation
    shinyjs::runjs(sprintf("
      var sel = document.getElementById('%s');
      if (sel) {
        sel.innerHTML = '';
        var choices = %s;
        Object.keys(choices).forEach(function(name) {
          var opt = document.createElement('option');
          opt.value = choices[name];
          opt.text = name;
          sel.appendChild(opt);
        });
        sel.value = '%s';
        $(sel).trigger('change');
      }
    ", session$ns("layout_id"), choices_json, selected_value))
  }
})
```

**Input Watcher:**
```r
# Trigger refresh when input first appears
observeEvent(input$layout_id, {
  cat("[", id, "] layout_id input appeared, triggering layouts refresh\n")
  isolate({
    layouts_refresh(layouts_refresh() + 1)
  })
}, once = TRUE, ignoreNULL = TRUE)

# Separate watcher for sites dropdown
observeEvent(input$layout_site_id, {
  cat("[", id, "] layout_site_id input appeared, triggering sites refresh\n")
  isolate({
    sites_refresh(sites_refresh() + 1)
  })
}, once = TRUE, ignoreNULL = TRUE)
```

**Cascade Updates (when layout changes):**
```r
observe(priority = -1, {
  layout <- current_layout()

  # ✅ Use JavaScript for cascade updates too
  site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) "" else as.character(layout$SiteID)
  shinyjs::runjs(sprintf("
    var sel = document.getElementById('%s');
    if (sel) {
      sel.value = '%s';
      $(sel).trigger('change');
      console.log('[CASCADE] Set site to:', sel.value);
    }
  ", session$ns("layout_site_id"), site_id))
})
```

### For Collapsible Section Dropdowns

These are in the collapsible "Backgrounds" section that can be hidden/shown.

**Affected:** `canvas_id`, `bg_area_id`

**UI Definition:**
```r
# Keep original settings - selectize works when hidden
selectInput(ns("canvas_id"), label = NULL, choices = c(), width = "100%", selectize = TRUE)
selectInput(ns("bg_area_id"), label = NULL, choices = c(), width = "100%", selectize = TRUE)
```

**Population Observer:**
```r
# Standard approach - no special handling needed
observe({
  canvases <- canvases_data()
  current_canvas_id <- input$canvas_id

  choices <- c("(None)" = "")
  if (nrow(canvases) > 0) {
    choices <- c(choices, setNames(canvases$id, canvases$canvas_name))
  }

  # ✅ updateSelectInput works fine in collapsible section
  updateSelectInput(session, "canvas_id", choices = choices, selected = current_canvas_id)
})
```

**Cascade Updates:**
```r
observe(priority = -1, {
  layout <- current_layout()

  # ✅ updateSelectInput works for cascade updates too
  canvas_id <- if (is.null(layout$CanvasID) || is.na(layout$CanvasID)) "" else as.character(layout$CanvasID)
  updateSelectInput(session, "canvas_id", selected = canvas_id)

  if (!is.null(canvas_id) && canvas_id != "") {
    canvas_data <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
    if (!inherits(canvas_data, "try-error") && !is.null(canvas_data) && nrow(canvas_data) > 0) {
      area_id <- if (is.null(canvas_data$AreaID) || is.na(canvas_data$AreaID[1])) "" else as.character(canvas_data$AreaID[1])
      updateSelectInput(session, "bg_area_id", selected = area_id)
    }
  }
})
```

**Why updateSelectInput works here:**
- These dropdowns are in a collapsible section that might be hidden
- JavaScript `document.getElementById()` fails when element is hidden/collapsed
- `updateSelectInput()` queues the update and Shiny applies it when the element becomes visible
- `selectize = TRUE` is fine because we're not using JavaScript DOM manipulation

### For Independent Dropdowns

These populate independently without filtering by other dropdowns.

**Affected:** `shape_template_id`

**UI Definition:**
```r
# Keep original - standard approach
selectInput(ns("shape_template_id"), label = NULL, choices = c(), width = "100%", selectize = TRUE)
```

**Population Observer:**
```r
# No input existence check needed - will populate when data available
observe({
  templates <- shape_templates_data()
  choices <- c("(select shape)" = "")
  if (nrow(templates) > 0) {
    choices <- c(choices, setNames(
      as.character(templates$ShapeTemplateID),
      paste0(templates$TemplateCode, " (", templates$ShapeType, ")")
    ))
  }
  # ✅ Standard updateSelectInput - no special handling
  updateSelectInput(session, "shape_template_id", choices = choices)
})
```

## Summary Table

| Dropdown | Location | selectize | Initial choices | Population Method | Cascade Method | Input Watcher |
|----------|----------|-----------|----------------|-------------------|----------------|---------------|
| `layout_id` | Main toolbar | FALSE | `c("Loading..." = "")` | JavaScript | JavaScript | ✅ Yes |
| `layout_site_id` | Main toolbar | FALSE | `c("Loading..." = "")` | JavaScript | JavaScript | ✅ Yes |
| `canvas_id` | Collapsible | TRUE | `c()` | updateSelectInput | updateSelectInput | ❌ No |
| `bg_area_id` | Collapsible | TRUE | `c()` | updateSelectInput | updateSelectInput | ❌ No |
| `shape_template_id` | Main toolbar | TRUE | `c()` | updateSelectInput | N/A | ❌ No |

## Key Learnings

### 1. renderUI Timing Is Critical

Dynamic UI rendering via `renderUI` creates a timing gap between when HTML appears and when Shiny's JavaScript bindings initialize. Standard `updateSelectInput()` calls during this window fail silently.

### 2. Two Different Solutions for Two Different Contexts

**Main toolbar (renderUI context):**
- Use `selectize = FALSE`
- Provide initial `choices = c("Loading..." = "")`
- Use JavaScript DOM manipulation for updates
- Add input watchers with `once = TRUE`
- Use `isolate()` to avoid circular dependencies

**Collapsible/Independent dropdowns:**
- Keep `selectize = TRUE` (or FALSE, doesn't matter)
- Standard `updateSelectInput()` works fine
- No special handling needed

### 3. The Role of isolate()

```r
# Reading input directly creates reactive dependency:
observe({
  data <- some_data()
  if (!is.null(input$my_input)) {  # ❌ Dependency created
    # ... update my_input → observer fires again → infinite loop
  }
})

# Use isolate() to check without dependency:
observe({
  data <- some_data()  # Only reactive dependency
  input_exists <- isolate(!is.null(input$my_input))  # ✅ No dependency
  if (!input_exists) return()
  // ... safe to update now
})
```

### 4. Module Server Mounting in Router

All module servers mount once at app startup in an `isolate()` block:

```r
# f_app_server.R
isolate({
  for (nm in names(route_map)) {
    srv <- route_map[[nm]]$server
    if (!is.null(srv)) srv()
  }
})
```

This means:
- Server code runs before any UI is rendered
- Observers are set up before inputs exist
- Input watchers (`observeEvent(input$x, ..., once = TRUE)`) are critical for triggering initial population

### 5. Why Standalone Works But Router Doesn't

**Standalone:**
```r
ui <- fluidPage(
  browser_siloplacements_ui("test")  # Static UI at startup
)
server <- function(input, output, session) {
  browser_siloplacements_server("test", pool)
}
```
Timeline: App starts → Static UI rendered → Bindings ready → Server runs → ✅ Works

**Router:**
```r
output$f_route_outlet <- renderUI({
  route_map[[key]]$ui()  # Dynamic UI on navigation
})
# Server already running from startup
```
Timeline: Navigate → renderUI → HTML sent → ❌ Observers fire immediately → Bindings not ready → updateSelectInput fails silently → 100ms later → Bindings ready (too late)

## Files Modified

### R/browsers/f_browser_siloplacements_fixed.R

Main fixed version with all the solutions applied.

**Key changes:**
- Lines 50-65: Main toolbar dropdowns (`layout_id`, `layout_site_id`) with `selectize = FALSE` and initial choices
- Lines 127-139: Collapsible section dropdowns (`canvas_id`, `bg_area_id`) kept as original
- Lines 228: Shape templates dropdown kept as original
- Lines 448-460: Input watchers for layout_id and layout_site_id
- Lines 531-577: Layout dropdown population using JavaScript
- Lines 760-798: Sites dropdown population using JavaScript
- Lines 740-757: Canvas dropdown population using updateSelectInput
- Lines 800-818: Areas dropdown population using updateSelectInput
- Lines 1191-1203: Shape templates population using updateSelectInput
- Lines 906-936: Cascade updates - JavaScript for site, updateSelectInput for canvas/area

### R/browsers/minimal_test.R

Minimal test module that isolated and demonstrated the fix.

**Purpose:**
- Stripped down version focusing only on layout/site dropdowns
- Used to verify the JavaScript approach worked
- Helped identify the root cause without other code interfering

### R/f_app_server.R

Router configuration (unchanged, for reference).

**Key points:**
- Line 428: `output$f_route_outlet <- renderUI(...)` - the source of timing issues
- Lines 441-453: Module servers mount once in `isolate()` block

## Testing Checklist

When testing the placements browser in router context:

- [ ] Navigate to `#/placements`
- [ ] Layout dropdown populates immediately with layout names
- [ ] Site dropdown populates immediately with site options
- [ ] Shape templates ("New") dropdown shows shape options (not "Loading...")
- [ ] When changing layouts, site dropdown updates automatically
- [ ] Click "Backgrounds" button to expand
- [ ] Canvas dropdown shows available canvases
- [ ] Area dropdown shows areas
- [ ] When changing layouts, canvas/area update if layout has them set
- [ ] Shapes appear on canvas filtered by selected site

## Debugging Tips

### Check if input exists:
```r
observe({
  cat("input$layout_id exists:", !is.null(input$layout_id), "\n")
  cat("input$layout_id value:", input$layout_id, "\n")
})
```

### Check JavaScript console:
```javascript
// Check if select element exists
var sel = document.getElementById('placements-layout_id');
console.log('Select exists:', sel);
console.log('Select has', sel ? sel.options.length : 0, 'options');
```

### Check observer firing:
```r
observe({
  layouts <- layouts_data()
  cat("Observer fired, got", nrow(layouts), "layouts\n")
  // ... rest of code
})
```

### Check reactive dependency loops:
```r
observe({
  val <- input$my_input
  cat("my_input changed to:", val, "\n")
})
# If this prints repeatedly without user interaction → circular dependency
```

## Related Issues

### SuspendWhenHidden

Initially investigated whether `suspendWhenHidden = FALSE` was needed, but this was not the issue. The problem was purely about input binding timing and the choice between JavaScript vs updateSelectInput.

### Delay-based Solutions

Attempted using `Sys.sleep()` and `shiny::later()` to wait for bindings, but this was rejected as it's a timing hack rather than proper event ordering. The input watcher approach (`observeEvent(..., once = TRUE)`) is the correct solution.

### Route-based Triggers

Initially tried triggering refresh based on route changes, but this was too complex. The input watcher approach is simpler and more reliable.

## Conclusion

The fix requires understanding the distinction between:
1. **Main toolbar dropdowns in renderUI** → Need JavaScript workaround
2. **Collapsible section dropdowns** → Standard approach works
3. **Independent dropdowns** → Standard approach works

The key insight is that not all dropdowns have the same problem. Only those in the dynamically rendered main toolbar need the JavaScript solution. Over-applying the fix to all dropdowns actually breaks the collapsible section dropdowns because JavaScript can't find hidden elements.
