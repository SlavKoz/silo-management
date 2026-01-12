# SiloOps/R/f_landing_page.R
# Operations Landing Page

f_landing_page_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$style(HTML("
      .ops-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem 1rem;
      }
      .ops-header {
        text-align: center;
        margin-bottom: 3rem;
      }
      .ops-header h2 {
        font-size: 2rem;
        font-weight: 600;
        color: #1b1c1d;
        margin-bottom: 0.5rem;
      }
      .ops-header p {
        font-size: 1.1rem;
        color: #666;
      }
      .ops-cards {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
        gap: 1.5rem;
      }
      .ops-card {
        background: #fff;
        border: 2px solid #e0e0e0;
        border-radius: 0.5rem;
        padding: 2rem;
        cursor: pointer;
        transition: all 0.2s ease;
        text-align: center;
      }
      .ops-card:hover {
        border-color: #2185d0;
        box-shadow: 0 4px 12px rgba(33, 133, 208, 0.15);
        transform: translateY(-2px);
      }
      .ops-card-icon {
        font-size: 3rem;
        color: #2185d0;
        margin-bottom: 1rem;
      }
      .ops-card-title {
        font-size: 1.3rem;
        font-weight: 600;
        color: #1b1c1d;
        margin: 0 0 0.5rem 0;
      }
      .ops-card-desc {
        font-size: 0.9rem;
        color: #666;
        margin: 0;
      }
    ")),

    div(class = "ops-container",
        div(class = "ops-header",
            tags$h2("Operations Dashboard"),
            tags$p("Welcome to Silo Operations - Select a function below")
        ),

        div(class = "ops-cards",
            div(class = "ops-card",
                div(class = "ops-card-icon", tags$i(class = "warehouse icon")),
                tags$h3(class = "ops-card-title", "Silo Management"),
                tags$p(class = "ops-card-desc", "View and manage silo operations")
            ),
            div(class = "ops-card",
                div(class = "ops-card-icon", tags$i(class = "clipboard list icon")),
                tags$h3(class = "ops-card-title", "Task Queue"),
                tags$p(class = "ops-card-desc", "View pending operations and tasks")
            ),
            div(class = "ops-card",
                div(class = "ops-card-icon", tags$i(class = "chart line icon")),
                tags$h3(class = "ops-card-title", "Reports"),
                tags$p(class = "ops-card-desc", "Generate operational reports")
            ),
            div(class = "ops-card",
                div(class = "ops-card-icon", tags$i(class = "cog icon")),
                tags$h3(class = "ops-card-title", "Settings"),
                tags$p(class = "ops-card-desc", "Configure operational preferences")
            )
        )
    )
  )
}

f_landing_page_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    # Server logic for landing page
    # Will add functionality as operations modules are built
  })
}
