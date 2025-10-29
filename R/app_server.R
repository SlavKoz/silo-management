app_server <- function(input, output, session) {
  # DB pool (optional, as before)
  pool <- NULL
  try({
    if (exists("db_pool")) pool <- db_pool()
  }, silent = TRUE)
  if (!is.null(pool) && inherits(pool, "Pool")) {
    onStop(function() try(pool::poolClose(pool), silent = TRUE))
  }
  
  # Icons
  if (exists("f_browser_icons_server")) f_browser_icons_server("icons", pool)
  else if (exists("browser_icons_server")) browser_icons_server("icons", pool)
  else if (exists("mod_browser_icons_server")) mod_browser_icons_server("icons")
  
  # Containers
  if (exists("f_browser_containers_server")) f_browser_containers_server("containers", pool)
  else if (exists("browser_containers_server")) browser_containers_server("containers", pool)
  
  # Silos
  if (exists("f_browser_silos_server")) f_browser_silos_server("silos", pool)
  else if (exists("browser_silos_server")) browser_silos_server("silos", pool)
  
  # Placements
  if (exists("f_browser_placements_server")) f_browser_placements_server("placements", pool)
  else if (exists("browser_placements_server")) browser_placements_server("placements", pool)
  
  # Canvas
  if (exists("f_canvas_server")) f_canvas_server("canvas", pool)
  else if (exists("canvas_server")) canvas_server("canvas", pool)
}
