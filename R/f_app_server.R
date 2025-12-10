# R/f_app_server.R — hash router with collapsible groups (Sites, Siloes, Actions)

f_app_server <- function(input, output, session) {
  
  # Get global memoized DB pool (don't close it - it's shared across sessions)
  pool <- NULL
  try({ if (exists("db_pool")) pool <- db_pool() }, silent = TRUE)

  session$userData$icons_version <- 0
  session$userData$areas_version <- 0

  # --- Search (grouped search) ---
  observeEvent(input$test_search_input, {
    selected <- input$test_search_input
    cat(sprintf("[Search] Selected: %s\n", f_or(selected, "NULL")))
    flush.console()

    if (is.null(selected) || !nzchar(selected)) return()

    # Find the route for the selected item
    route_map_test <- test_search_route_map()
    if (!is.null(route_map_test[[selected]])) {
      route <- route_map_test[[selected]]
      session$sendCustomMessage("set-hash", list(h = route))
    }
  })

  # Monitor search query typing
  observeEvent(input$test_search_query, {
    cat(sprintf("[Search][query] \"%s\" (len=%d)\n",
                f_or(input$test_search_query, ""), nchar(f_or(input$test_search_query, ""))))
    flush.console()
  }, ignoreInit = FALSE)

  # Get search items
  test_search_items <- reactive({
    category <- f_or(input$global_search_category, "all")
    query <- f_or(input$test_search_query, "")
    cat(sprintf("[Search][reactive] category=%s query=\"%s\" len=%d pool=%s\n",
                category, query, nchar(query), if (is.null(pool)) "NULL" else "OK"))
    flush.console()

    # For "all" require 3+ characters
    # For specific category, allow empty query (show all items)
    if (category == "all" && nchar(query) < 3) {
      cat("[Search] All category needs 3+ chars; returning empty\n")
      flush.console()
      return(list())
    }

    # Search with selected category
    results <- f_get_search_items(
      category = category,
      query = query,
      pool = pool,
      limit = 100
    )
    cat(sprintf("[Search] fetched %d items\n", length(results)))
    flush.console()
    results
  })

  # Store route mappings for search selections
  test_search_route_map <- reactive({
    items <- test_search_items()
    if (length(items) == 0) return(list())

    routes <- sapply(items, function(item) item$route)
    names(routes) <- sapply(items, function(item) item$label)
    as.list(routes)
  })

  # Update search dropdown with real data
  observe({
    # Explicit dependencies
    items <- test_search_items()
    category <- input$global_search_category
    query <- input$test_search_query

    category <- f_or(category, "all")
    query <- f_or(query, "")

    cat(sprintf("[Search][observer] category=%s query=\"%s\" items=%d\n",
                category, query, length(items)))
    flush.console()

    # For "all" require 3+ chars, for specific category show all items
    if (category == "all" && nchar(query) < 3) {
      session$sendCustomMessage("test-search-menu", list(
        groups = list(list(name = "Type 3+ chars...", items = list())),
        query  = query,
        show_categories = FALSE
      ))
      return()
    }

    if (length(items) > 0) {
      # Group items by category
      labels <- sapply(items, function(x) x$label)
      categories <- sapply(items, function(x) x$category)

      # Debug: print category breakdown
      cat(sprintf("[Search] Category breakdown:\n"))
      for (cat_name in unique(categories)) {
        count <- sum(categories == cat_name)
        cat(sprintf("  - %s: %d items\n", cat_name, count))
      }
      flush.console()

      # If specific category selected, don't show category headers
      if (category != "all") {
        cat("[Search] Specific category - hiding headers\n")
        flush.console()
        session$sendCustomMessage("test-search-menu", list(
          groups = list(list(name = "", items = as.list(labels))),
          query = query,
          show_categories = FALSE
        ))
      } else {
        # Show grouped with category headers for "all"
        groups <- sapply(items, function(x) {
          paste0(toupper(substring(x$category, 1, 1)), substring(x$category, 2))
        })
        grouped <- split(labels, groups)

        # Debug: print grouped structure
        cat(sprintf("[Search] Grouped structure:\n"))
        for (g in names(grouped)) {
          cat(sprintf("  - %s: %d items\n", g, length(grouped[[g]])))
        }
        flush.console()

        # Send grouped data to client
        session$sendCustomMessage("test-search-menu", list(
          groups = lapply(names(grouped), function(g) {
            # Ensure items is always a list/array, even with 1 element
            list(name = g, items = as.list(unname(grouped[[g]])))
          }),
          query = query,
          show_categories = TRUE
        ))
      }
    } else {
      session$sendCustomMessage("test-search-menu", list(
        groups = list(list(name = "No results", items = list())),
        query = query,
        show_categories = FALSE
      ))
    }
  })


  # --- Router helpers ---
  parse_route <- function(h) {
    h <- sub("^#/", "", f_or(h, "home"))
    # Strip query parameters (everything after ?)
    h <- sub("\\?.*$", "", h)
    parts <- strsplit(h, "/", fixed = TRUE)[[1]]
    parts[nzchar(parts)]
  }
  route_key <- function(parts) if (length(parts)) paste(parts, collapse = ".") else "home"
  
  # --- Route map ---
  route_map <- list(
    # Home / Landing page
    "home" = list(
      title = "Home",
      ui    = function() {
        if (exists("f_landing_page_ui")) f_landing_page_ui("landing")
        else div(class = "p-3", h3("Home"), p("Welcome to Silo Operations"))
      },
      server = function() {
        if (exists("f_landing_page_server")) f_landing_page_server("landing")
      }
    ),

    # Sites group
    "sites" = list(
      title = "Sites",
      ui    = function() {
        if (exists("f_browser_sites_ui")) f_browser_sites_ui("sites")
        else div(class = "p-3", h3("Sites"), p("Placeholder: Sites overview will go here."))
      },
      server = function() {
        if (exists("f_browser_sites_server")) f_browser_sites_server("sites", pool, route = current)
      }
    ),
    "areas" = list(
      title = "Areas",
      ui    = function() {
        if (exists("f_browser_areas_ui")) f_browser_areas_ui("areas")
        else div(class = "p-3", h3("Areas"), p("Placeholder: Areas browser will go here."))
      },
      server = function() {
        if (exists("f_browser_areas_server")) f_browser_areas_server("areas", pool, route = current)
      }
    ),
    
    # Siloes (single)
    "siloes" = list(
      title = "Siloes",
      ui    = function() {
        if (exists("f_browser_siloes_ui")) f_browser_siloes_ui("siloes")
        else div(class="p-3", h3("Siloes"), p("Placeholder: Siloes overview/list will go here."))
      },
      server = function() {
        if (exists("f_browser_siloes_server")) f_browser_siloes_server("siloes", pool, route = current)
      }
    ),
    
    # Actions group
    "actions.offline_reasons" = list(
      title = "Offline Reasons",
      ui    = function() {
        if (exists("f_browser_offline_reasons_ui")) f_browser_offline_reasons_ui("offline")
        else div(class="p-3", h3("Offline Reasons"), p("Placeholder: manage reason types & offline events."))
      },
      server = function() {
        if (exists("f_browser_offline_reasons_server")) f_browser_offline_reasons_server("offline", pool)
      }
    ),
    "actions.operations" = list(
      title = "Operations",
      ui    = function() {
        if (exists("f_browser_operations_ui")) f_browser_operations_ui("ops")
        else div(class="p-3", h3("Operations"), p("Placeholder: container/silo operations will go here."))
      },
      server = function() {
        if (exists("f_browser_operations_server")) f_browser_operations_server("ops", pool, route = current)
      }
    ),
    
    # Existing
    "shapes" = list(
      title = "Shapes",
      ui    = function() {
        if (exists("f_browser_shapes_ui")) f_browser_shapes_ui("shapes")
        else if (exists("browser_shapes_ui")) browser_shapes_ui("shapes")
        else div("Shapes UI placeholder")
      },
      server = function() {
        if (exists("f_browser_shapes_server")) f_browser_shapes_server("shapes", pool, route = current)
        else if (exists("browser_shapes_server")) browser_shapes_server("shapes", pool)
      }
    ),
    "icons" = list(
      title = "Icons",
      ui    = function() {
        if (exists("f_browser_icons_ui")) f_browser_icons_ui("icons")
        else if (exists("browser_icons_ui")) browser_icons_ui("icons")
        else div("Icons UI placeholder")
      },
      server = function() {
        if (exists("f_browser_icons_server")) f_browser_icons_server("icons", pool)
        else if (exists("browser_icons_server")) browser_icons_server("icons", pool)
      }
    ),
    "containers" = list(
      title = "Containers",
      ui    = function() {
        if (exists("f_browser_containers_ui")) f_browser_containers_ui("containers")
        else if (exists("browser_containers_ui")) browser_containers_ui("containers")
        else div("Containers UI placeholder")
      },
      server = function() {
        if (exists("f_browser_containers_server")) f_browser_containers_server("containers", pool, route = current)
        else if (exists("browser_containers_server")) browser_containers_server("containers", pool)
      }
    ),
    "placements" = list(
      title = "Placements",
      ui    = function() {
        if (exists("browser_siloplacements_ui")) browser_siloplacements_ui("placements")
        else div(class="p-3", h3("Placements"), p("Placeholder: this section is not ready yet."))
      },
      server = function() {
        if (exists("browser_siloplacements_server")) browser_siloplacements_server("placements", pool, route = current)
      }
    ),
    "canvases" = list(
      title = "Canvases",
      ui    = function() {
        if (exists("f_browser_canvas_ui")) f_browser_canvas_ui("canvases")
        else div("Canvases UI placeholder")
      },
      server = function() {
        if (exists("f_browser_canvas_server")) f_browser_canvas_server("canvases", pool)
      }
    ),
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
  )
  
  # Icon map for sidebar items (Semantic UI icon class names)
  icon_map <- c(
    "home"                   = "home",
    "sites"                  = "building",
    "areas"                  = "map outline",
    "siloes"                 = "warehouse",
    "actions.offline_reasons"= "ban",
    "actions.operations"     = "play",
    "shapes"                 = "shapes",
    "icons"                  = "icons",
    "containers"             = "boxes",
    "placements"             = "map marker alternate",
    "canvases"               = "image outline",
    "variants"               = "tags"
  )
  

  header_icon_map <- list(
    "sites@group"   = "building",
    "actions@group" = "bolt"
  )
  
  
  
  
  # --- Sidebar menu (explicit order + group metadata) ---
  # Define groups and items for rendering (and for collapse persistence)
  sidebar_structure <- list(
    list(                      # Silo single (home/landing)
      key   = "home@single",
      title = "Silo",
      items = c("home")
    ),
    list(                      # Sites group
      key   = "sites@group",
      title = "Sites",
      items = c("sites", "areas")
    ),
    list(                      # Siloes single
      key   = "siloes@single",
      title = "Siloes",
      items = c("siloes")
    ),
    list(                      # Actions group
      key   = "actions@group",
      title = "Actions",
      items = c("actions.offline_reasons", "actions.operations")
    ),
    list( key="shapes@single",    title="Shapes",    items=c("shapes") ),
    list( key="icons@single",     title="Icons",     items=c("icons") ),
    list( key="containers@single",title="Containers",items=c("containers") ),
    list( key="placements@single",title="Placements",items=c("placements") ),
    list( key="canvases@single",  title="Canvases",  items=c("canvases") ),
    list( key="variants@single",  title="Variants",  items=c("variants") )
  )
  
  build_menu <- function(active_key) {
    sections <- lapply(sidebar_structure, function(sec){
      is_group <- grepl("@group$", sec$key)
      
      # group header icon (safe fallback)
      header_icon <- if (is_group) {
        ic <- header_icon_map[[sec$key]]
        if (is.null(ic)) "circle outline" else ic
      } else NULL
      
      # ---- group header (with tooltip via title attr) ----
      header <- if (is_group) div(
        class = "item group-header",
        `data-group` = sec$key,
        `data-tip` = sec$title,
        `aria-label` = sec$title,
        tags$i(class = paste(header_icon, "icon")),
        span(class = "item-label", sec$title)
      ) else NULL
      
      # ---- children items ----
      children <- lapply(sec$items, function(key){
        info <- route_map[[key]]
        if (is.null(info)) return(NULL)
        
        href   <- paste0("#/", gsub("\\.", "/", key))
        a_cls  <- if (identical(active_key, key)) "nav-active" else NULL
        icon   <- icon_map[[key]] %||% "circle outline"
        label  <- as.character(info$title %||% key)  # avoid using a var named 'title'
        
        div(
          class = paste("item", if (is_group) "subitem" else NULL, a_cls),
          `data-route` = href,
          `data-tip` = label,
          `aria-label` = label,
          tags$i(class = paste(icon, "icon")),
          span(class = "item-label", label)
        )
      })
      
      # wrap as a group block or a single
      if (is_group) {
        div(class = "group-block collapsed",  # collapsed by default
            header,
            div(class = "group-children", children))
      } else {
        children
      }
    })
    
    tags$div(class="ui vertical inverted menu fluid", sections)
  }

  # --- Hash -> route state ---
  current <- reactiveVal(c("home"))  # default to Home

  # Helper to find the best matching route key
  find_route_key <- function(parts) {
    if (length(parts) == 0) return("home")

    # Try exact match first
    full_key <- route_key(parts)
    if (!is.null(route_map[[full_key]])) return(full_key)

    # Try progressively shorter paths (for deep-linking support)
    # e.g., c("containers", "BULKTANK") -> try "containers"
    # e.g., c("sites", "areas") -> try "sites.areas", then "sites"
    for (i in length(parts):1) {
      test_parts <- parts[1:i]
      test_key <- route_key(test_parts)
      if (!is.null(route_map[[test_key]])) return(test_key)
    }

    # No match found, default to home
    return("home")
  }

  output$f_sidebar_menu <- renderUI({
    key <- find_route_key(current())
    build_menu(key)
  })

  observeEvent(input$f_route, {
    parts <- parse_route(input$f_route)
    key <- find_route_key(parts)

    # If we found a valid route, keep the full parts for deep-linking
    # Otherwise fall back to home
    if (key != "home" || identical(parts, character(0)) || (length(parts) > 0 && parts[1] == "home")) {
      current(parts)
    } else {
      current(c("home"))
    }
  }, ignoreInit = FALSE)

  # --- Title & Outlet ---
  output$f_page_title <- renderText({
    key <- find_route_key(current())
    info <- route_map[[key]] %||% route_map[["home"]]
    info$title
  })
  output$f_route_outlet <- renderUI({
    key <- find_route_key(current())
    info <- route_map[[key]] %||% route_map[["home"]]
    info$ui()
  })
  
  # --- Mount all servers once ---
  isolate({
    for (nm in names(route_map)) {
      srv <- route_map[[nm]]$server
      if (!is.null(srv)) {
        cat("[App Server] Loading route:", nm, "\n")
        result <- try(srv(), silent = FALSE)
        if (inherits(result, "try-error")) {
          cat("[App Server] ERROR loading route:", nm, "\n")
          print(result)
        }
      }
    }
  })
}
