# R/browsers/mod_browser_silos.R
# Silos browser (separate view; keep if you later distinguish Containers vs Silos)

suppressPackageStartupMessages({
  library(shiny)
  library(bs4Dash)
  library(jsonlite)
})

browser_silos_ui <- function(id) {
  ns <- NS(id)
  bs4Card(
    title = "Silos",
    status = "primary",
    solidHeader = TRUE,
    width = 12,
    fluidRow(
      column(3,
             textInput(ns("q"), "Name/Code contains", ""),
             selectInput(ns("order_col"), "Order by",
                         choices = c("SiloCode","SiloName","Area","VolumeM3","CreatedAt"),
                         selected = "SiloCode"),
             selectInput(ns("order_dir"), "Direction", choices = c("ASC","DESC")),
             actionButton(ns("refresh"), "Refresh", class = "btn btn-primary")
      ),
      column(9,
             react_table_ui(ns("tbl"), height = "60vh")
      )
    )
  )
}

browser_silos_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    columns <- list(
      list(id="SiloID",      label="ID", width=80, type="number"),
      list(id="SiloCode",    label="Code", width=120),
      list(id="SiloName",    label="Name", width=220),
      list(id="Area",        label="Area", width=100),
      list(id="VolumeM3",    label="Volume (m³)", width=120, type="number"),
      list(id="AllowMixedVariants", label="Mixed", width=80),
      list(id="IsActive",    label="Active", width=80),
      list(id="CreatedAt",   label="Created", width=140)
    )
    
    data_fn <- reactive({
      input$refresh
      isolate({
        code_like <- if (nzchar(input$q)) like_contains(input$q) else NULL
        order_col <- input$order_col %||% "SiloCode"
        order_dir <- input$order_dir %||% "ASC"
        if (!exists("list_silos")) return(data.frame())
        df <- try(list_silos(
          code_like = code_like,
          order_col = order_col,
          order_dir = order_dir,
          limit     = 500
        ), silent = TRUE)
        if (inherits(df, "try-error") || is.null(df)) data.frame() else df
      })
    })
    
    react_table_server("tbl", columns = columns, data_fn = function() data_fn(), key = "SiloID", selection = "single")
    
    selected <- reactiveVal(NULL)
    return(list(
      selected_silo_id = selected
    ))
  })
}
