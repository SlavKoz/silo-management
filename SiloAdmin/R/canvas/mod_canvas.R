# R/canvas/mod_canvas.R
# Canvas module: UI + server wiring to the front-end engine (www/js/canvas.js)
# and app glue (www/js/silo-canvas.js). Keeps DB optional; shows empty scene if none.

suppressPackageStartupMessages({
  library(shiny)
  library(jsonlite)
})

# ---------------- UI ----------------
canvas_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      id = ns("root"),
      class = "silo-canvas-root",
      # --- toolbar (compact) ---
      div(
        class = "d-flex align-items-center mb-2 gap-2",
        checkboxInput(ns("edit"), "Edit mode", FALSE),
        numericInput(ns("snap"), "Grid (units, 0=off)", value = 0, min = 0, step = 1, width = 180),
        actionButton(ns("fit"), "Fit view"),
        actionButton(ns("refresh"), "Refresh")
      ),
      # --- viewport ---
      div(
        class = "canvas-viewport",
        # The <canvas> is the drawing surface; labels DIV sits on top
        tags$canvas(id = ns("canvas"), width = 1400, height = 900, style = "width:100%; height:auto;"),
        tags$div(id = ns("labels"))
      )
    )
  )
}

# ---------------- Server ----------------
canvas_server <- function(id, pool = NULL, data_provider = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Helper: compute the global prefix used by silo-canvas.js for input ids
    # rootId is like "<id>-root", we convert to "<id>"
    root_id <- ns("root")
    base_id <- sub("-root$", "", root_id)  # e.g. "canvas"
    
    # Shape data (reactive store)
    r <- reactiveValues(shapes = list())
    
    # --- Data loader --------------------------------------------------------
    # You can pass a custom `data_provider()` that returns a data.frame or list of placements.
    load_shapes <- function() {
      if (is.function(data_provider)) {
        dat <- try(data_provider(), silent = TRUE)
      } else if (exists("list_placements")) {
        dat <- try(list_placements(limit = 1000), silent = TRUE)
      } else {
        dat <- NULL
      }
      if (inherits(dat, "try-error") || is.null(dat)) dat <- data.frame()
      canvas_utils_coerce(dat)  # from canvas_utils.R
    }
    
    # --- Outbound: send payload to front-end -------------------------------
    send_canvas <- function(shapes) {
      # message name namespace: "<ns('root')>:setData"
      session$sendCustomMessage(paste0(root_id, ":", "setData"), list(data = shapes))
    }
    set_edit_mode <- function(on) session$sendCustomMessage(paste0(root_id, ":", "setEditMode"), list(on = isTRUE(on)))
    set_snap      <- function(v)  session$sendCustomMessage(paste0(root_id, ":", "setSnap"), list(units = as.numeric(v %||% 0)))
    fit_view      <- function(b)  session$sendCustomMessage(paste0(root_id, ":", "fitView"), list(bounds = b))
    
    # --- Initial load -------------------------------------------------------
    observeEvent(input$refresh, {
      r$shapes <- load_shapes()
      send_canvas(r$shapes)
      # auto-fit if we have any shapes
      b <- canvas_utils_bounds(r$shapes)
      if (!is.null(b)) fit_view(b)
    }, ignoreInit = FALSE)
    
    # --- Edit mode + snap ---------------------------------------------------
    observe({
      set_edit_mode(isTRUE(input$edit))
    })
    observe({
      set_snap(input$snap %||% 0)
    })
    
    # --- Fit view button ----------------------------------------------------
    observeEvent(input$fit, {
      b <- canvas_utils_bounds(r$shapes)
      if (!is.null(b)) fit_view(b)
    })
    
    # --- Inbound events from JS --------------------------------------------
    # Selection (JS posts "<base>_selection")
    observeEvent(input[[paste0(base_id, "_selection")]], {
      sel <- input[[paste0(base_id, "_selection")]]
      # Do something with selection, e.g., update a reactiveVal or emit to other modules
      # message(sprintf("Selected shape: %s", as.character(sel)))
    }, ignoreInit = TRUE)
    
    # Pending positions (stage drag moves, not yet saved)
    observeEvent(input[[paste0(base_id, "_pending_pos")]], {
      pending <- input[[paste0(base_id, "_pending_pos")]] %||% list()
      # Here you could enable a "Save" button, or auto-save if policy allows.
      # Example: store in r$pending for later commit
      r$pending <- pending
    }, ignoreInit = TRUE)
    
    # --- Optional save integration (skeleton) ------------------------------
    # If you later add a "Save" button, call:
    # observeEvent(input$save, {
    #   # Use canvas_utils_commit_pending(pool, r$pending) to persist
    # })
    
  })
}


