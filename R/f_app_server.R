# R/f_app_server.R — hash router with collapsible groups (Sites, Siloes, Actions)

f_app_server <- function(input, output, session) {
  
  # Optional DB pool
  pool <- NULL
  try({ if (exists("db_pool")) pool <- db_pool() }, silent = TRUE)
  if (!is.null(pool) && inherits(pool, "Pool")) {
    onStop(function() try(pool::poolClose(pool), silent = TRUE))
  }
  
  session$userData$icons_version <- 0
  
  # --- Router helpers ---
  parse_route <- function(h) {
    h <- sub("^#/", "", f_or(h, "sites"))
    parts <- strsplit(h, "/", fixed = TRUE)[[1]]
    parts[nzchar(parts)]
  }
  route_key <- function(parts) if (length(parts)) paste(parts, collapse = ".") else "sites"
  
  # --- Route map ---
  route_map <- list(
    # Sites group
    "sites" = list(
      title = "Sites",
      ui    = function() {
        if (exists("f_browser_sites_ui")) f_browser_sites_ui("sites")
        else div(class = "p-3", h3("Sites"), p("Placeholder: Sites overview will go here."))
      },
      server = function() {
        if (exists("f_browser_sites_server")) f_browser_sites_server("sites", pool)
      }
    ),
    "sites.areas" = list(
      title = "Areas",
      ui    = function() {
        if (exists("f_form_site_areas_ui")) f_form_site_areas_ui("sites_areas")
        else div(class = "p-3", h3("Areas"), p("Placeholder: Areas form will go here."))
      },
      server = function() {
        if (exists("f_form_site_areas_server")) f_form_site_areas_server("sites_areas", pool)
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
        if (exists("f_browser_siloes_server")) f_browser_siloes_server("siloes", pool)
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
        if (exists("f_browser_operations_server")) f_browser_operations_server("ops", pool)
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
        if (exists("f_browser_shapes_server")) f_browser_shapes_server("shapes", pool)
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
        if (exists("f_browser_containers_server")) f_browser_containers_server("containers", pool)
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
    "sites"                  = "building",
    "sites.areas"            = "circle outline",
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
    list(                      # Sites group
      key   = "sites@group",
      title = "Sites",
      items = c("sites", "sites.areas")
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
  
  output$f_sidebar_menu <- renderUI({
    key <- route_key(current())
    build_menu(key)
  })
  
  # --- Hash -> route state ---
  current <- reactiveVal(c("sites"))  # default to Sites
  
  observeEvent(input$f_route, {
    parts <- parse_route(input$f_route)
    key <- route_key(parts)
    if (is.null(route_map[[key]])) parts <- c("sites")
    current(parts)
  }, ignoreInit = FALSE)
  
  # --- Title & Outlet ---
  output$f_page_title <- renderText({
    key <- route_key(current())
    info <- route_map[[key]] %||% route_map[["sites"]]
    info$title
  })
  output$f_route_outlet <- renderUI({
    key <- route_key(current())
    info <- route_map[[key]] %||% route_map[["sites"]]
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
