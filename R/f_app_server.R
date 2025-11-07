# R/f_app_server.R — Server with hash router

f_app_server <- function(input, output, session) {
  
  # Optional DB pool
  pool <- NULL
  try({ if (exists("db_pool")) pool <- db_pool() }, silent = TRUE)
  if (!is.null(pool) && inherits(pool, "Pool")) {
    onStop(function() try(pool::poolClose(pool), silent = TRUE))
  }
  
  # Map route -> title and UI function
  route_map <- list(
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
    "silos" = list(
      title = "Silos",
      ui    = function() {
        if (exists("f_browser_silos_ui")) f_browser_silos_ui("silos")
        else if (exists("browser_silos_ui")) browser_silos_ui("silos")
        else div("Silos UI placeholder")
      },
      server = function() {
        if (exists("f_browser_silos_server")) f_browser_silos_server("silos", pool)
        else if (exists("browser_silos_server")) browser_silos_server("silos", pool)
      }
    ),
    "placements" = list(
      title = "Placements",
      ui    = function() {
        if (exists("f_browser_placements_ui")) f_browser_placements_ui("placements")
        else if (exists("browser_placements_ui")) browser_placements_ui("placements")
        else div("Placements UI placeholder")
      },
      server = function() {
        if (exists("f_browser_placements_server")) f_browser_placements_server("placements", pool)
        else if (exists("browser_placements_server")) browser_placements_server("placements", pool)
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
    )
  )
  
  # Parse the '#/section/sub' hash into c('section','sub')
  parse_route <- function(h) {
    h <- sub("^#/", "", f_or(h, "containers"))
    parts <- strsplit(h, "/", fixed = TRUE)[[1]]
    parts[nzchar(parts)]
  }

  # Current route
  current <- reactiveVal(c("containers"))

  observeEvent(input$f_route, {
    parts <- parse_route(input$f_route)
    if (!length(parts)) parts <- c("containers")
    current(parts)
  }, ignoreInit = FALSE)

  # Title
  output$f_page_title <- renderText({
    parts <- current(); key <- parts[1]
    info <- route_map[[key]] %||% route_map[["containers"]]
    info$title
  })

  # Route outlet UI
  output$f_route_outlet <- renderUI({
    parts <- current(); key <- parts[1]
    info <- route_map[[key]] %||% route_map[["containers"]]
    info$ui()
  })
  
  # Mount server for active module (once per route key)
  # This approach mounts all available servers once; simple and safe.
  isolate({
    if (!is.null(route_map$icons$server))      route_map$icons$server()
    if (!is.null(route_map$canvases$server))   route_map$canvases$server()
    if (!is.null(route_map$containers$server)) route_map$containers$server()
    if (!is.null(route_map$silos$server))      route_map$silos$server()
    if (!is.null(route_map$placements$server)) route_map$placements$server()
  })
}
