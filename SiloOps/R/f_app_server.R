# SiloOps/R/f_app_server.R
# Operations Server Logic

f_app_server <- function(input, output, session) {

  # Get database pool
  pool <- NULL
  try({ if (exists("db_pool")) pool <- db_pool() }, silent = TRUE)

  # Simple routing - just show landing page for now
  output$f_route_outlet <- renderUI({
    f_landing_page_ui("landing")
  })

  # Initialize landing page
  f_landing_page_server("landing", pool)
}
