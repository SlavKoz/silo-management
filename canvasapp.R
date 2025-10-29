# app.R — bs4Dash wrapper for the Canvas Manager (Upload → Tray → Library)
library(shiny)
library(bs4Dash)

source("R/canvas_manager.R", local = TRUE)

ui <- bs4DashPage(
  title = "Canvas Manager",
  header = bs4DashNavbar(title = NULL, skin = "light", border = FALSE),
  sidebar = bs4DashSidebar(disable = TRUE),
  controlbar = NULL,
  footer = NULL,
  body = bs4DashBody(
    tags$head(tags$style(HTML("
      .main-header { display: none !important; }
      .content-wrapper, .content { margin-top: 0 !important; }
      .nav-tabs { border-bottom: 1px solid #dee2e6; margin-bottom: .75rem; }
      .nav-tabs .nav-link { padding: .5rem .75rem; margin-right: .25rem; border: 1px solid transparent; }
      .nav-tabs .nav-link:hover { border-color: #e9ecef #e9ecef #dee2e6; }
      .nav-tabs .nav-link.active { color: #495057; background-color: #fff; border-color: #dee2e6 #dee2e6 #fff; }
    "))),
    fluidRow(
      column(width = 12, canvasManagerUI("cmgr"))
    )
  )
)

server <- function(input, output, session) {
  canvasManagerServer("cmgr")
}

shinyApp(ui, server)
