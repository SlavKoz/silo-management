# R/browsers/f_browser_placements_minimal.R
# Minimal version of placements browser - ONLY layout dropdown

# Source helpers (same as full browser)
source("R/utils/f_siloplacements_helpers.R", local = TRUE)

# =========================== UI ===============================================
f_browser_placements_minimal_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),

    # External CSS (same as full browser)
    tags$link(rel = "stylesheet", href = "css/f_siloplacements.css"),

    # Main content - SIMPLIFIED (no special classes or wrappers)
    div(style = "padding: 2rem;",
      h3("Placements Minimal - Layout Dropdown Only"),

      # Simple layout dropdown (NO wrapper divs)
      div(style = "margin-bottom: 1rem;",
        tags$label("Layout:", style = "display: block; margin-bottom: 0.5rem;"),
        shiny::selectInput(
          ns("layout_id"),
          label = NULL,
          choices = c("Loading..." = ""),
          width = "300px",
          selectize = FALSE
        )
      ),

      # Debug output
      div(style = "margin-top: 2rem; padding: 1rem; background: #f0f0f0;",
        h4("Debug Info"),
        verbatimTextOutput(ns("debug_output"))
      )
    )
  )
}

# =========================== SERVER ===========================================
f_browser_placements_minimal_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    cat("\n========================================\n")
    cat("[ placements-minimal ] MODULE INITIALIZATION STARTED\n")
    cat("========================================\n")

    # Track if we've visited this route
    ui_initialized <- reactiveVal(FALSE)

    # Refresh triggers
    layouts_refresh <- reactiveVal(0)

    # Current state
    current_layout_id <- reactiveVal(NULL)

    # ---- Load layouts (EXACT COPY) ----
    layouts_data <- reactive({
      layouts_refresh()  # Depend on refresh trigger
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # Populate layout dropdown (EXACT COPY)
    observe({
      cat("[ placements-minimal ] Populating layout dropdown observer fired\n")
      layouts <- layouts_data()
      cat("[ placements-minimal ] Found", nrow(layouts), "layouts\n")

      if (nrow(layouts) > 0) {
        cat("[ placements-minimal ] Building choices for layout dropdown\n")
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)

        # Use isolate to read current_layout_id without creating a dependency
        current_id <- isolate(current_layout_id())
        cat("[ placements-minimal ] Current layout ID:", current_id, "\n")

        selected_val <- if (!is.null(current_id) && !is.na(current_id) &&
                           as.character(current_id) %in% choices) {
          as.character(current_id)
        } else {
          as.character(layouts$LayoutID[1])
        }
        cat("[ placements-minimal ] Selected value:", selected_val, "\n")
        cat("[ placements-minimal ] Calling updateSelectInput for layout_id with", length(choices), "choices\n")

        updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)

        cat("[ placements-minimal ] Layout dropdown updateSelectInput called\n")
      } else {
        cat("[ placements-minimal ] No layouts found\n")
      }
    })

    # Watch for route changes (EXACT COPY)
    if (!is.null(route) && is.function(route)) {
      observe({
        current_route <- route()
        cat("[ placements-minimal ] Route changed to:", paste(current_route, collapse="/"), "\n")

        # Check if this route is for placements-minimal
        if (length(current_route) > 0 && current_route[1] == "placements_minimal") {
          if (!ui_initialized()) {
            cat("[ placements-minimal ] First navigation to placements-minimal, triggering refresh\n")
            ui_initialized(TRUE)

            # Trigger refresh
            isolate({
              layouts_refresh(layouts_refresh() + 1)
            })
          }
        }
      })
    }

    # Debug output
    output$debug_output <- renderText({
      selected <- input$layout_id
      paste0(
        "Current selection: ", selected, "\n",
        "Is NULL: ", is.null(selected), "\n",
        "Is empty: ", identical(selected, ""), "\n",
        "Layouts count: ", nrow(layouts_data())
      )
    })

    cat("[ placements-minimal ] Module server initialization complete\n")
  })
}
