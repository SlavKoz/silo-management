# R/f_app_server.R — hash router with collapsible groups (Sites, Siloes, Actions)

f_app_server <- function(input, output, session) {
  
  # Get global memoized DB pool (don't close it - it's shared across sessions)
  pool <- NULL
  try({ if (exists("db_pool")) pool <- db_pool() }, silent = TRUE)

  session$userData$icons_version <- 0
  session$userData$areas_version <- 0

  # --- Global Search Logic ---
  observeEvent(input$global_search_btn, {
    category <- input$global_search_category
    query <- input$global_search_input

    if (is.null(category)) category <- "forms"
    if (is.null(query) || !nzchar(trimws(query))) {
      showNotification("Please enter a search term", type = "warning", duration = 1)
      return()
    }

    query <- trimws(query)

    # First check if query matches a suggestion exactly (datalist selection)
    route_map <- search_route_map()
    if (!is.null(route_map[[query]])) {
      route <- route_map[[query]]
      session$sendCustomMessage("set-hash", list(h = route))
      return()
    }

    # Extract ID from label if format is "ID - Name"
    # This handles datalist selections like "BULKTANK - Bulk tank"
    search_term <- query
    if (grepl(" - ", query)) {
      parts <- strsplit(query, " - ", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        search_term <- parts[1]  # Use just the ID part
      }
    }

    # Get search results
    results <- f_get_search_items(
      category = category,
      query = search_term,
      pool = pool,
      limit = 50
    )

    if (length(results) == 0) {
      showNotification("No results found", type = "warning", duration = 1)
      return()
    }

    # If single result, navigate directly without notification
    if (length(results) == 1) {
      route <- results[[1]]$route
      session$sendCustomMessage("set-hash", list(h = route))
      return()
    }

    # Multiple results - navigate to first, show count
    route <- results[[1]]$route
    session$sendCustomMessage("set-hash", list(h = route))
    showNotification(
      paste0("Found ", length(results), " results. Showing: ", results[[1]]$label),
      type = "message",
      duration = 2
    )
  })

  # Autofill suggestions for search
  search_suggestions <- reactive({
    category <- input$global_search_category
    query <- input$global_search_input

    if (is.null(category)) category <- "forms"
    if (is.null(query) || nchar(query) < 2) return(list())

    # Get suggestions
    results <- f_get_search_items(
      category = category,
      query = query,
      pool = pool,
      limit = 20
    )

    results
  })

  output$search_datalist <- renderUI({
    suggestions <- search_suggestions()

    if (length(suggestions) == 0) return(NULL)

    options <- lapply(suggestions, function(item) {
      tags$option(value = item$label, `data-route` = item$route)
    })

    tags$datalist(id = "search_suggestions", options)
  })

  # Store route mappings for datalist selections
  search_route_map <- reactive({
    suggestions <- search_suggestions()
    if (length(suggestions) == 0) return(list())

    routes <- sapply(suggestions, function(item) item$route)
    names(routes) <- sapply(suggestions, function(item) item$label)
    as.list(routes)
  })

  # --- Router helpers ---
  parse_route <- function(h) {
    h <- sub("^#/", "", f_or(h, "home"))
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
        div(class="p-3", h3("Placements"), p("Placeholder: this section is not ready yet."))
      },
      server = function() { }
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
    "canvases"               = "image outline"
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
    list( key="canvases@single",  title="Canvases",  items=c("canvases") )
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
      if (!is.null(srv)) try(srv(), silent = TRUE)
    }
  })
}
