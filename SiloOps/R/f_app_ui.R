# SiloOps/R/f_app_ui.R
# Operations UI

f_app_ui <- function() {
  shiny.semantic::semanticPage(
    shinyjs::useShinyjs(),

    tags$head(
      tags$style(HTML("
        body {
          margin: 0;
          padding: 20px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
        }
        .header {
          background: #2185d0;
          color: white;
          padding: 1rem 2rem;
          margin-bottom: 2rem;
          border-radius: 0.5rem;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .header h1 {
          margin: 0;
          font-size: 1.8rem;
        }
        .admin-link {
          color: white;
          text-decoration: none;
          padding: 0.5rem 1rem;
          background: rgba(255,255,255,0.2);
          border-radius: 0.3rem;
          transition: background 0.2s;
        }
        .admin-link:hover {
          background: rgba(255,255,255,0.3);
        }
      "))
    ),

    div(class = "header",
        tags$h1("Silo Operations"),
        tags$a(class = "admin-link", href = "http://localhost:3838", target = "_blank",
               tags$i(class = "settings icon"),
               " Admin"
        )
    ),

    uiOutput("f_route_outlet")
  )
}
