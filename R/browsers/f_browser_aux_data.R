# R/browsers/f_browser_aux_data.R
# Auxiliary data browser for Crop Years and Pools (read-only)

f_browser_aux_data_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$head(tags$style(HTML("
      .ui.dropdown,
      .ui.dropdown .text,
      .ui.dropdown .menu .item { font-size: 13px; }
      .ui.right.labeled.input { display: flex; align-items: stretch; }
      .ui.right.labeled.input > .ui.dropdown { flex: 1 1 auto; min-width: 0; width: auto; }
    "))),
    div(class = "ui grid stackable",
        div(class = "five wide column",
            div(class = "ui form", style = "margin-bottom: 0.75rem;",
                div(class = "field",
                    div(class = "ui right labeled input", style = "width:100%;",
                        shiny.semantic::dropdown_input(
                          input_id = ns("dataset"),
                          choices = c("Crop Years", "Pools"),
                          choices_value = c("cropyears", "pools"),
                          value = "cropyears",
                          type = "fluid selection"
                        ),
                        div(class = "ui basic label", "Datasets")
                    )
                )
            ),
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter…",
              add_new_item = FALSE
            )
        ),
        div(class = "eleven wide column",
            div(class = "ui form", style = "margin-bottom: 0.75rem;",
                div(class = "field",
                    actionButton(
                      inputId = ns("refresh_aux"),
                      label   = "Refresh aux data",
                      class   = "ui primary button",
                      style   = "width:100%;"
                    )
                )
            ),
            div(style = "margin-top: 2.85rem;",
                uiOutput(ns("details"))
            )
        )
    )
  )
}

f_browser_aux_data_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    refresh <- reactiveVal(0)
    dataset <- reactive(input$dataset %||% "cropyears")

    observeEvent(input$refresh_aux, {
      res <- try(DBI::dbExecute(pool, "EXEC dbo.sp_SyncAuxDataFromFranklin"), silent = TRUE)
      if (inherits(res, "try-error")) {
        showNotification(conditionMessage(attr(res, "condition")), type = "error")
      } else {
        refresh(refresh() + 1)
        showNotification("Aux data refreshed", type = "message")
      }
    })

    raw_data <- reactive({
      refresh()  # depend on refresh counter
      if (dataset() == "cropyears") {
        try(list_crop_years(pool), silent = TRUE) %||% data.frame()
      } else {
        try(list_pools(pool), silent = TRUE) %||% data.frame()
      }
    })

    list_items <- reactive({
      df <- raw_data()
      if (!nrow(df)) {
        return(data.frame(id=character(0), icon=character(0), title=character(0),
                          description=character(0), stringsAsFactors = FALSE))
      }
      if (dataset() == "cropyears") {
        data.frame(
          id = df$CropYearID %||% df$Code,
          icon = "",
          title = df$Name,
          description = df$Code,
          stringsAsFactors = FALSE
        )
      } else {
        data.frame(
          id = df$PoolID %||% df$PoolCode,
          icon = "",
          title = df$PoolName,
          description = df$PoolCode,
          stringsAsFactors = FALSE
        )
      }
    })

    list_result <- compact_list_server(
      "list",
      items = list_items,
      add_new_item = FALSE,
      initial_selection = "first"
    )

    selected_id <- list_result$selected_id

    output$details <- renderUI({
      df <- raw_data()
      sid <- selected_id()
      if (is.null(sid) || !nrow(df)) return(
        div(class="ui placeholder segment", p("Select an item to view details."))
      )

      row <- if (dataset() == "cropyears") {
        if ("CropYearID" %in% names(df)) df[df$CropYearID == sid, ] else df[df$Code == sid, ]
      } else {
        if ("PoolID" %in% names(df)) df[df$PoolID == sid, ] else df[df$PoolCode == sid, ]
      }
      if (!nrow(row)) return(div(class="ui message", "Not found"))

      if (dataset() == "cropyears") {
        code <- row$Code[1] %||% ""
        name <- row$Name[1] %||% ""
      } else {
        code <- row$PoolCode[1] %||% ""
        name <- row$PoolName[1] %||% ""
      }

      div(class = "ui segment",
          h4(class = "ui header", name),
          p(tags$b("Code: "), code),
          p(tags$b("Status: "), ifelse(isTRUE(row$IsActive[1]), "Active", "Inactive"))
      )
    })
  })
}
