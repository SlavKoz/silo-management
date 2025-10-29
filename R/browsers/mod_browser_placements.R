# R/browsers/mod_browser_placements.R
# Placements browser; optionally filter by silo/layout if provided in args.

suppressPackageStartupMessages({
  library(shiny)
  library(bs4Dash)
  library(jsonlite)
})

browser_placements_ui <- function(id) {
  ns <- NS(id)
  bs4Card(
    title = "Placements",
    status = "primary",
    solidHeader = TRUE,
    width = 12,
    fluidRow(
      column(3,
             numericInput(ns("silo_id"), "Filter by SiloID", value = NA, min = 1, step = 1),
             numericInput(ns("layout_id"), "Filter by LayoutID", value = NA, min = 1, step = 1),
             selectInput(ns("order_col"), "Order by",
                         choices = c("PlacementID","SiloID","LayoutID","ZIndex","CreatedAt"),
                         selected = "PlacementID"),
             selectInput(ns("order_dir"), "Direction", choices = c("ASC","DESC")),
             actionButton(ns("refresh"), "Refresh", class = "btn btn-primary")
      ),
      column(9,
             react_table_ui(ns("tbl"), height = "60vh")
      )
    )
  )
}

browser_placements_server <- function(id, pool, silo_id_reactive = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    columns <- list(
      list(id="PlacementID",   label="PlacementID", width=110, type="number"),
      list(id="SiloID",        label="SiloID", width=90, type="number"),
      list(id="LayoutID",      label="LayoutID", width=90, type="number"),
      list(id="ShapeTemplateID",label="ShapeTmplID", width=110, type="number"),
      list(id="CenterX",       label="X", width=80, type="number"),
      list(id="CenterY",       label="Y", width=80, type="number"),
      list(id="ZIndex",        label="Z", width=60, type="number"),
      list(id="IsVisible",     label="Visible", width=80),
      list(id="IsInteractive", label="Interactive", width=100),
      list(id="CreatedAt",     label="Created", width=140)
    )
    
    # derive silo filter from external selection if provided
    observe({
      if (is.null(silo_id_reactive)) return()
      sid <- silo_id_reactive()
      if (is.null(sid) || is.na(sid) || !length(sid)) return()
      updateNumericInput(session, "silo_id", value = as.integer(sid))
    })
    
    data_fn <- reactive({
      input$refresh
      isolate({
        order_col <- input$order_col %||% "PlacementID"
        order_dir <- input$order_dir %||% "ASC"
        sid <- input$silo_id; if (is.nan(sid) || is.na(sid)) sid <- NULL
        lid <- input$layout_id; if (is.nan(lid) || is.na(lid)) lid <- NULL
        
        if (!exists("list_placements")) return(data.frame())
        df <- try(list_placements(
          layout_id = if (!is.null(lid)) as.integer(lid) else NULL,
          silo_id   = if (!is.null(sid)) as.integer(sid) else NULL,
          order_col = order_col,
          order_dir = order_dir,
          limit     = 1000
        ), silent = TRUE)
        if (inherits(df, "try-error") || is.null(df)) data.frame() else df
      })
    })
    
    react_table_server("tbl", columns = columns, data_fn = function() data_fn(), key = "PlacementID", selection = "single")
    
    selected <- reactiveVal(NULL)
    return(list(
      selected_placement_id = selected
    ))
  })
}
