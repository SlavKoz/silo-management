# R/browsers/f_browser_siloes.R

f_browser_siloes_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="p-3",
        h2("Siloes"),
        p("Placeholder content: siloes overview/list will go here."),
        p("Use dbo.vw_SilosWithStatus for live offline status + site linkage.")
    )
  )
}

f_browser_siloes_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    # TODO: query vw_SilosWithStatus and render a table/card list
  })
}
