# R/browsers/browser_placements_minimal.R
# Minimal version of placements browser - ONLY layout dropdown
# NO helpers, NO special CSS - absolute minimal (NO f_ prefix)

# =========================== UI ===============================================
browser_placements_minimal_ui <- function(id) {
  ns <- NS(id)

  div(
    style = "padding: 2rem;",
    h3("Test Dropdown - EXACT copy of minimal_test"),
    p("If this dropdown populates, the basic mechanism works."),

    selectInput(
      ns("test_dropdown"),
      "Select a layout:",
      choices = c("Loading..." = ""),
      width = "300px"
    ),

    verbatimTextOutput(ns("debug_output"))
  )
}

# =========================== SERVER ===========================================
browser_placements_minimal_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    cat("\n========================================\n")
    cat("[ testdropdown ] MODULE INITIALIZATION STARTED\n")
    cat("========================================\n")

    # Track if we've visited this route (EXACT COPY from minimal_test)
    ui_initialized <- reactiveVal(FALSE)

    # Refresh triggers (EXACT COPY from minimal_test)
    layouts_refresh <- reactiveVal(0)

    # Load layouts (EXACT COPY from minimal_test)
    layouts_data <- reactive({
      layouts_refresh()  # Depend on refresh trigger
      cat("[ testdropdown ] layouts_data reactive called\n")
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)

      if (inherits(df, "try-error") || is.null(df)) {
        cat("[ testdropdown ] ERROR: Query failed\n")
        return(data.frame())
      }

      cat("[ testdropdown ] Query returned", nrow(df), "rows\n")
      return(df)
    })

    # Populate layout dropdown (EXACT COPY from minimal_test)
    observe({
      cat("[ testdropdown ] Populating layout dropdown observer fired\n")
      layouts <- layouts_data()
      cat("[ testdropdown ] Found", nrow(layouts), "layouts\n")

      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)
        cat("[ testdropdown ] Calling updateSelectInput with", length(choices), "choices\n")
        cat("[ testdropdown ] Choices:", paste(names(choices), collapse=", "), "\n")

        updateSelectInput(session, "test_dropdown", choices = choices, selected = choices[1])

        cat("[ testdropdown ] updateSelectInput called\n")
      } else {
        cat("[ testdropdown ] No layouts found\n")
        updateSelectInput(session, "test_dropdown", choices = c("No layouts found" = ""))
      }
    })

    # Watch for route changes (EXACT COPY)
    if (!is.null(route) && is.function(route)) {
      observe({
        current_route <- route()
        cat("[ testdropdown ] Route changed to:", paste(current_route, collapse="/"), "\n")

        # Check if this route is for testdropdown
        if (length(current_route) > 0 && current_route[1] == "testdropdown") {
          if (!ui_initialized()) {
            cat("[ testdropdown ] First navigation to testdropdown, triggering refresh\n")
            ui_initialized(TRUE)

            # Trigger refresh
            isolate({
              layouts_refresh(layouts_refresh() + 1)
            })
          }
        }
      })
    }

    # Debug output showing what's selected
    output$debug_output <- renderText({
      selected <- input$test_dropdown
      paste0(
        "Current selection: ", selected, "\n",
        "Is NULL: ", is.null(selected), "\n",
        "Is empty: ", identical(selected, "")
      )
    })

    cat("[ testdropdown ] Module server initialization complete\n")
  })
}
