# Minimal test 2 module - EXACT copy of minimal_test with different route name
# Purpose: Test if route name affects dropdown population

minimal_test2_ui <- function(id) {
  ns <- NS(id)

  div(
    style = "padding: 2rem;",
    h3("Minimal Dropdown Test 2"),
    p("EXACT copy of minimal_test - testing if route name matters."),

    selectInput(
      ns("test_dropdown"),
      "Select a layout:",
      choices = c("Loading..." = ""),
      width = "300px"
    ),

    verbatimTextOutput(ns("debug_output"))
  )
}

minimal_test2_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    cat("\n========================================\n")
    cat("[MINIMAL TEST 2] Module server started\n")
    cat("========================================\n")

    # Track if we've visited this route (same as placements)
    ui_initialized <- reactiveVal(FALSE)

    # Refresh trigger that increments when we navigate to this module (same as placements)
    layouts_refresh <- reactiveVal(0)

    # Load layouts using same function as placements module
    layouts_data <- reactive({
      layouts_refresh()  # Depend on refresh trigger
      cat("[MINIMAL TEST 2] layouts_data reactive called\n")
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)

      if (inherits(df, "try-error") || is.null(df)) {
        cat("[MINIMAL TEST 2] ERROR: Query failed\n")
        return(data.frame())
      }

      cat("[MINIMAL TEST 2] Query returned", nrow(df), "rows\n")
      return(df)
    })

    # Watch for route changes to "minimal2" (changed route name)
    if (!is.null(route) && is.function(route)) {
      observe({
        current_route <- route()
        cat("[MINIMAL TEST 2] Route changed to:", paste(current_route, collapse="/"), "\n")

        if (length(current_route) > 0 && current_route[1] == "minimal2") {
          if (!ui_initialized()) {
            cat("[MINIMAL TEST 2] First navigation to minimal2, triggering refresh\n")
            ui_initialized(TRUE)

            # Trigger refresh to populate dropdown
            isolate({
              layouts_refresh(layouts_refresh() + 1)
            })
          }
        }
      })
    }

    # Observer to populate dropdown (same pattern as placements)
    observe({
      cat("[MINIMAL TEST 2] Populating layout dropdown observer fired\n")
      layouts <- layouts_data()
      cat("[MINIMAL TEST 2] Found", nrow(layouts), "layouts\n")

      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)
        cat("[MINIMAL TEST 2] Calling updateSelectInput with", length(choices), "choices\n")
        cat("[MINIMAL TEST 2] Choices:", paste(names(choices), collapse=", "), "\n")

        updateSelectInput(session, "test_dropdown", choices = choices, selected = choices[1])

        cat("[MINIMAL TEST 2] updateSelectInput called\n")
      } else {
        cat("[MINIMAL TEST 2] No layouts found\n")
        updateSelectInput(session, "test_dropdown", choices = c("No layouts found" = ""))
      }
    })

    # Debug output showing what's selected
    output$debug_output <- renderText({
      selected <- input$test_dropdown
      paste0(
        "Current selection: ", selected, "\n",
        "Is NULL: ", is.null(selected), "\n",
        "Is empty: ", identical(selected, "")
      )
    })

    cat("[MINIMAL TEST 2] Module server initialization complete\n")
  })
}

# Test runner
run_minimal_test <- function() {
  library(shiny)

  # Load DB connection
  if (!exists("db_pool")) {
    source("R/db/connect_wrappers.R", local = TRUE)
  }

  ui <- fluidPage(
    title = "Minimal Dropdown Test",
    minimal_test_ui("test")
  )

  server <- function(input, output, session) {
    minimal_test_server("test", pool = db_pool())
  }

  cat("\n=== Launching Minimal Test ===\n\n")

  shinyApp(ui, server, options = list(launch.browser = TRUE))
}
