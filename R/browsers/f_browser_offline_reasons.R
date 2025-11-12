# R/browsers/f_browser_offline_reasons.R

f_browser_offline_reasons_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="p-3",
        h2("Offline Reasons"),
        p("Placeholder content: manage OfflineReasonTypes and SiloOfflineEvents.")
    )
  )
}

f_browser_offline_reasons_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    # TODO:
    # - list dbo.OfflineReasonTypes (CRUD)
    # - list/filter dbo.SiloOfflineEvents by site/silo/date
  })
}
