# R/browsers/f_browser_sites.R

f_browser_sites_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "p-3",
        h2("Sites"),
        p("Placeholder content: site list, map, filters, etc."),
        tags$ul(
          tags$li("Site table from dbo.Sites"),
          tags$li("Geo preview (later Google aerial view)"),
          tags$li("Link to Siloes filtered by site")
        )
    )
  )
}

f_browser_sites_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    # TODO: load dbo.Sites into a DT/compact list; add map later
  })
}
