# Cross-Module State Management

## Overview

When multiple Shiny modules need to stay synchronized (e.g., when one module updates data that another module displays), use `session$userData` to share state changes.

## Pattern: Global Version Counter

Use a **version counter** that increments when data changes. Other modules observe this counter to know when to refresh.

**Critical**: Initialize the counter at app startup (in `server.R` or `f_app_server.R`) so all modules can establish reactive dependencies on an existing value:

```r
f_app_server <- function(input, output, session) {
  # Initialize global state counters at startup
  session$userData$icons_version <- 0
  session$userData$silos_version <- 0
  # ... etc

  # Rest of app server code...
}
```

Without initialization, modules that load before the counter is first set won't establish the reactive dependency!

### Example: Icons Updated in One Module, Used in Another

**Scenario**: Icon browser can add/delete icons. Container browser shows icon picker with all available icons. When icons change, the picker needs to refresh.

**Implementation:**

### 1. Module That Changes Data (Icon Browser)

Signal changes by incrementing `session$userData$icons_version`:

```r
# After successfully saving an icon
if (success) {
  showNotification("Icon saved!", type = "message")
  refresh_library()

  # Signal global icon change
  if (!is.null(session$userData$icons_version)) {
    session$userData$icons_version <- session$userData$icons_version + 1
  } else {
    session$userData$icons_version <- 1
  }
}

# After successfully deleting an icon
if (success) {
  showNotification("Icon deleted", type = "message")
  refresh_library()

  # Signal global icon change
  if (!is.null(session$userData$icons_version)) {
    session$userData$icons_version <- session$userData$icons_version + 1
  } else {
    session$userData$icons_version <- 1
  }
}
```

### 2. Module That Consumes Data (Container Browser)

Observe the version counter in a reactive:

```r
icons_data <- reactive({
  # Depend on global icons version to refresh when icons are added/deleted
  # IMPORTANT: Always access to create dependency, even if NULL
  icons_version <- session$userData$icons_version

  # Fetch fresh data
  df <- list_icons_for_picker(limit = 1000)
  # ... process and return
})
```

**Critical**: Don't use `if (!is.null(...))` check - this prevents dependency creation if the value doesn't exist yet!

**How It Works:**
1. Icon browser saves/deletes an icon
2. Increments `session$userData$icons_version` (e.g., from 1 to 2)
3. Container browser's `icons_data` reactive observes this value
4. When version changes, reactive invalidates and re-runs
5. Fresh icon list is fetched from database
6. Icon picker updates automatically

## Benefits

✅ **Simple**: Just increment a counter
✅ **Automatic**: Reactive chain handles propagation
✅ **Decoupled**: Modules don't need to know about each other
✅ **Efficient**: Only refetches when actually needed
✅ **Session-Scoped**: Isolated per user session

## When to Use

Use this pattern when:
- **Multiple modules** need to display/use the same data
- **One module** can modify that data (add/edit/delete)
- You need **automatic synchronization** without manual refresh

## Naming Convention

Use descriptive names for version counters:

```r
session$userData$icons_version       # Icons added/deleted
session$userData$silos_version       # Silos added/deleted/updated
session$userData$layouts_version     # Layouts changed
```

## Alternative: Reactive Values

For more complex scenarios, you can use a reactiveValues object:

```r
# In server.R or parent module
global_state <- reactiveValues(
  icons_version = 0,
  silos_version = 0
)

# Pass to child modules
browser_icons_server("icons", global_state = global_state)
browser_containers_server("containers", global_state = global_state)

# In modules
global_state$icons_version <- global_state$icons_version + 1
```

But `session$userData` is simpler for basic version tracking.

## Complete Example

**Icon Browser** (`R/browsers/f_browser_icons.R`):
```r
observeEvent(input$btn_save, {
  # ... save icon ...
  if (success) {
    refresh_library()

    # Increment version
    session$userData$icons_version <-
      f_or(session$userData$icons_version, 0) + 1
  }
})

observeEvent(input$delete_btn, {
  # ... delete icon ...
  if (success) {
    refresh_library()

    # Increment version
    session$userData$icons_version <-
      f_or(session$userData$icons_version, 0) + 1
  }
})
```

**Container Browser** (`R/browsers/f_browser_containers.R`):
```r
icons_data <- reactive({
  # Observe version
  session$userData$icons_version

  # Fetch fresh data
  list_icons_for_picker(limit = 1000)
})

schema_config <- reactive({
  icon_info <- icons_data()  # Depends on icons_version

  list(
    fields = list(
      field("IconID", "select", enum = icon_info$choices, ...)
    )
  )
})
```

## Debugging

To see when synchronization happens:

```r
# In consuming module
icons_data <- reactive({
  version <- session$userData$icons_version
  cat("Icons version changed to:", version, "\n")

  # ... fetch data
})
```

## Important Notes

⚠️ **Session-Only**: `session$userData` is unique per browser session. Changes don't affect other users.

⚠️ **Creating Dependencies**: Always access the value directly, never wrap in `if (!is.null())`:
```r
# CORRECT - creates dependency even if NULL
icons_data <- reactive({
  version <- session$userData$icons_version  # Always access
  fetch_data()
})

# WRONG - prevents dependency creation if value doesn't exist
icons_data <- reactive({
  if (!is.null(session$userData$icons_version)) {
    session$userData$icons_version  # Dependency only created if value exists!
  }
  fetch_data()
})
```

⚠️ **Incrementing**: Use `f_or()` for safe increment:
```r
# CORRECT - safe increment
session$userData$icons_version <- f_or(session$userData$icons_version, 0) + 1

# ALSO CORRECT but more verbose
new_version <- if (!is.null(session$userData$icons_version)) {
  session$userData$icons_version + 1
} else {
  1
}
session$userData$icons_version <- new_version
```

✅ **Use Sparingly**: Only for cross-module synchronization. For single-module state, use regular reactiveVal().
