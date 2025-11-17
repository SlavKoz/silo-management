# R/f_landing_page.R
# Landing page with navigation cards organized by groups

f_landing_page_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$style(HTML("
      .landing-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem 1rem;
      }
      .landing-header {
        text-align: center;
        margin-bottom: 3rem;
      }
      .landing-header h1 {
        font-size: 2.5rem;
        font-weight: 600;
        color: #1b1c1d;
        margin-bottom: 0.5rem;
      }
      .landing-header p {
        font-size: 1.1rem;
        color: #666;
      }
      .landing-group {
        margin-bottom: 2.5rem;
      }
      .landing-group-title {
        font-size: 1.3rem;
        font-weight: 600;
        color: #1b1c1d;
        margin-bottom: 1rem;
        padding-bottom: 0.5rem;
        border-bottom: 2px solid #3b82f6;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }
      .landing-group-title i {
        color: #3b82f6;
      }
      .landing-cards {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
        gap: 0.75rem;
      }
      .landing-card {
        background: #fff;
        border: 1px solid #e0e0e0;
        border-radius: 0.4rem;
        padding: 0.85rem;
        cursor: pointer;
        transition: all 0.2s ease;
        text-decoration: none;
        color: inherit;
        display: flex;
        flex-direction: column;
        gap: 0.4rem;
      }
      .landing-card:hover {
        border-color: #3b82f6;
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
        transform: translateY(-2px);
      }
      .landing-card-icon {
        font-size: 1.5rem;
        color: #3b82f6;
      }
      .landing-card-title {
        font-size: 0.95rem;
        font-weight: 600;
        color: #1b1c1d;
        margin: 0;
      }
      .landing-card-desc {
        font-size: 0.8rem;
        color: #666;
        margin: 0;
        line-height: 1.3;
      }
    ")),

    div(class = "landing-container",
        # Header
        div(class = "landing-header",
            tags$h1("Silo Operations"),
            tags$p("Select a module to get started")
        ),

        # Sites Group
        div(class = "landing-group",
            div(class = "landing-group-title",
                tags$i(class = "map marker alternate icon"),
                "Location Management"
            ),
            div(class = "landing-cards",
                tags$a(class = "landing-card", href = "#/sites",
                       div(class = "landing-card-icon", tags$i(class = "building icon")),
                       tags$h3(class = "landing-card-title", "Sites"),
                       tags$p(class = "landing-card-desc", "Manage facility locations and site information")
                ),
                tags$a(class = "landing-card", href = "#/areas",
                       div(class = "landing-card-icon", tags$i(class = "map icon")),
                       tags$h3(class = "landing-card-title", "Areas"),
                       tags$p(class = "landing-card-desc", "Define and organize site areas")
                )
            )
        ),

        # Actions Group
        div(class = "landing-group",
            div(class = "landing-group-title",
                tags$i(class = "cogs icon"),
                "Actions & Operations"
            ),
            div(class = "landing-cards",
                tags$a(class = "landing-card", href = "#/actions/offline_reasons",
                       div(class = "landing-card-icon", tags$i(class = "ban icon")),
                       tags$h3(class = "landing-card-title", "Offline Reasons"),
                       tags$p(class = "landing-card-desc", "Configure reasons for equipment offline status")
                ),
                tags$a(class = "landing-card", href = "#/actions/operations",
                       div(class = "landing-card-icon", tags$i(class = "play icon")),
                       tags$h3(class = "landing-card-title", "Operations"),
                       tags$p(class = "landing-card-desc", "Define and manage operational procedures")
                )
            )
        ),

        # Storage & Equipment
        div(class = "landing-group",
            div(class = "landing-group-title",
                tags$i(class = "warehouse icon"),
                "Storage & Equipment"
            ),
            div(class = "landing-cards",
                tags$a(class = "landing-card", href = "#/siloes",
                       div(class = "landing-card-icon", tags$i(class = "warehouse icon")),
                       tags$h3(class = "landing-card-title", "Siloes"),
                       tags$p(class = "landing-card-desc", "Manage silo inventory and configurations")
                ),
                tags$a(class = "landing-card", href = "#/containers",
                       div(class = "landing-card-icon", tags$i(class = "boxes icon")),
                       tags$h3(class = "landing-card-title", "Containers"),
                       tags$p(class = "landing-card-desc", "Container types and specifications")
                ),
                tags$a(class = "landing-card", href = "#/shapes",
                       div(class = "landing-card-icon", tags$i(class = "shapes icon")),
                       tags$h3(class = "landing-card-title", "Shapes"),
                       tags$p(class = "landing-card-desc", "Define shape templates and dimensions")
                )
            )
        ),

        # Visual Configuration
        div(class = "landing-group",
            div(class = "landing-group-title",
                tags$i(class = "palette icon"),
                "Visual Configuration"
            ),
            div(class = "landing-cards",
                tags$a(class = "landing-card", href = "#/icons",
                       div(class = "landing-card-icon", tags$i(class = "icons icon")),
                       tags$h3(class = "landing-card-title", "Icons"),
                       tags$p(class = "landing-card-desc", "Manage icon library for UI elements")
                ),
                tags$a(class = "landing-card", href = "#/placements",
                       div(class = "landing-card-icon", tags$i(class = "map marker alternate icon")),
                       tags$h3(class = "landing-card-title", "Placements"),
                       tags$p(class = "landing-card-desc", "Configure object placement rules")
                ),
                tags$a(class = "landing-card", href = "#/canvases",
                       div(class = "landing-card-icon", tags$i(class = "image outline icon")),
                       tags$h3(class = "landing-card-title", "Canvases"),
                       tags$p(class = "landing-card-desc", "Design and manage visual layouts")
                )
            )
        )
    )
  )
}

f_landing_page_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # No server logic needed - navigation handled by href links
  })
}
