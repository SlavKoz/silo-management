# Minimal test module - isolates the layout selector UI/logic

minimal_test_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    shinyjs::useShinyjs(),
    
    # Reuse the same stylesheet for consistent formatting
    tags$link(rel = "stylesheet", href = "css/f_siloplacements.css"),
    
    # Layout toolbar copied from placements browser
    div(
      class = "main-content",
      style = "padding: 1rem;",
      div(
        class = "canvas-container",
        div(
          class = "toolbar-grid",
          
          # Column 1: Empty (removed Add New button for testing)
          div(),

          # Column 2: Layout label
          tags$label(
            "Layout:",
            style = "margin: 0; font-size: 13px; font-weight: normal;"
          ),
          
          # Column 3: Layout selector - NO WRAPPER DIV to avoid update issues
          shiny::selectInput(
            ns("layout_id"), label = NULL, choices = c("Loading..." = ""), width = "100%",
            selectize = FALSE
          ),
          
          # Column 4: Site label
          tags$label(
            "Site:",
            style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right;"
          ),
          
          # Column 5: Site selector
          shiny::selectInput(
            ns("layout_site_id"), label = NULL, choices = c(), width = "100%",
            selectize = FALSE
          ),
          
          # Spacer columns to preserve original formatting
          div(),
          div(),
          
          # Column 8: Empty spacer
          div(),

          # Column 9: Empty (removed Delete button for testing)
          div()
        )
      )
    ),

    verbatimTextOutput(ns("debug_output")),

    # JavaScript to monitor DOM changes
    tags$script(HTML(sprintf("
      console.log('[JS] Minimal test UI loaded');

      // Watch for when the select element appears
      var checkInterval = setInterval(function() {
        var select = document.getElementById('%s');
        if (select) {
          console.log('[JS] Select element found:', select);
          console.log('[JS] Select has', select.options.length, 'options');

          // Watch for changes to the select
          var observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
              console.log('[JS] Select mutated:', mutation.type, mutation);
              console.log('[JS] Select now has', select.options.length, 'options');
            });
          });

          observer.observe(select, {
            childList: true,
            attributes: true,
            subtree: true
          });

          // Also watch if the select gets removed from DOM
          var parentObserver = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
              if (mutation.removedNodes) {
                mutation.removedNodes.forEach(function(node) {
                  if (node.id === '%s' || (node.querySelector && node.querySelector('#%s'))) {
                    console.error('[JS] SELECT ELEMENT WAS REMOVED FROM DOM!');
                    console.trace();
                  }
                });
              }
            });
          });

          parentObserver.observe(document.body, {
            childList: true,
            subtree: true
          });

          clearInterval(checkInterval);
        }
      }, 100);
    ", ns("layout_id"), ns("layout_id"), ns("layout_id"))))
  )
}

minimal_test_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    notify_error <- function(prefix, e, duration = NULL) {
      message(sprintf("[minimal layout] %s: %s", prefix, conditionMessage(e)))
      if (!is.null(e$call)) {
        message("  call: ", paste(deparse(e$call), collapse = " "))
      }
      showNotification(paste(prefix, conditionMessage(e)), type = "error", duration = duration)
    }
    
    as_optional_integer_na <- function(value) {
      if (is.null(value) || is.na(value) || identical(value, "")) return(NA)
      as.integer(value)
    }
    
    ui_initialized <- reactiveVal(FALSE)
    layouts_refresh <- reactiveVal(0)
    sites_refresh <- reactiveVal(0)
    current_layout_id <- reactiveVal(1)
    layouts_status <- reactiveVal("Waiting for query...")

    cat("[minimal_test] ======================================\n")
    cat("[minimal_test] MODULE SERVER STARTED\n")
    cat("[minimal_test] ======================================\n")

    layouts_data <- reactive({
      refresh_val <- layouts_refresh()
      cat("[minimal_test] layouts_data() CALLED - refresh trigger value:", refresh_val, "\n")
      layouts_status("Querying layouts...")
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        msg <- if (inherits(df, "try-error")) conditionMessage(attr(df, "condition")) else "query returned NULL"
        layouts_status(paste("ERROR:", msg))
        cat("[minimal_test] list_canvas_layouts FAILED:", msg, "\n")
        return(data.frame())
      }
      cat("[minimal_test] list_canvas_layouts SUCCESS - returned", nrow(df), "layouts\n")
      if (nrow(df) > 0) {
        cat("[minimal_test] Layout names:", paste(df$LayoutName, collapse=", "), "\n")
      }
      layouts_status(paste("Loaded", nrow(df), "layouts"))
      df
    })

    # Update dropdown when layouts data changes
    # Use isolate() to check if input exists without creating a reactive dependency
    observe({
      cat("[minimal_test] -----------------------------------\n")
      cat("[minimal_test] DROPDOWN UPDATE OBSERVER FIRED\n")

      # Get layouts data (this is the reactive dependency)
      layouts <- layouts_data()
      cat("[minimal_test] Got", nrow(layouts), "layouts from reactive\n")

      # Check if input exists using isolate() to avoid creating dependency
      input_exists <- isolate(!is.null(input$layout_id))
      cat("[minimal_test] input$layout_id exists (isolated check):", input_exists, "\n")

      if (!input_exists) {
        cat("[minimal_test] Input doesn't exist yet, skipping update\n")
        cat("[minimal_test] -----------------------------------\n")
        return()
      }

      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)
        selected_value <- unname(choices[1])
        cat("[minimal_test] Prepared", length(choices), "choices:\n")
        cat("[minimal_test] Choices:", paste(names(choices), "=", choices, collapse=", "), "\n")
        cat("[minimal_test] Selected value:", selected_value, "(type:", class(selected_value), ")\n")

        cat("[minimal_test] Calling updateSelectInput\n")
        cat("[minimal_test] Input ID:", session$ns("layout_id"), "\n")
        cat("[minimal_test] Choices length:", length(choices), "\n")
        cat("[minimal_test] Selected:", selected_value, "\n")

        tryCatch({
          # Direct DOM manipulation because updateSelectInput fails when binding isn't ready
          cat("[minimal_test] Using JavaScript to update select (bypassing Shiny binding)\n")

          choices_json <- jsonlite::toJSON(as.list(choices), auto_unbox = TRUE)

          shinyjs::runjs(sprintf("
            var sel = document.getElementById('%s');
            if (!sel) {
              console.error('[UPDATE] Select element not found!');
            } else {
              // Clear and rebuild options
              sel.innerHTML = '';
              var choices = %s;
              Object.keys(choices).forEach(function(name) {
                var opt = document.createElement('option');
                opt.value = choices[name];
                opt.text = name;
                sel.appendChild(opt);
              });

              // Set selected value
              sel.value = '%s';

              // Notify Shiny of the change
              $(sel).trigger('change');

              console.log('[UPDATE] Populated with ' + sel.options.length + ' options, selected:', sel.value);
            }
          ", session$ns("layout_id"), choices_json, selected_value))

          cat("[minimal_test] Dropdown populated via JavaScript\n")

        }, error = function(e) {
          cat("[minimal_test] ERROR in update:", conditionMessage(e), "\n")
        })
      } else {
        cat("[minimal_test] No layouts found, setting empty dropdown\n")
        status <- layouts_status()
        if (is.character(status) && grepl("^ERROR", status)) {
          showNotification(status, type = "error", duration = NULL)
        }

        updateSelectInput(session, "layout_id", choices = c("No layouts found" = ""))
      }
      cat("[minimal_test] -----------------------------------\n")
    })
    
    # COMMENTED OUT: Add/Delete functionality removed for testing
    # observeEvent(input$add_new_layout_btn, {
    #   shinyjs::hide("select_container")
    #   shinyjs::show("text_container")
    #   shinyjs::runjs(paste0("$('#", ns("new_layout_name"), "').focus();"))
    # })
    #
    # observeEvent(input$save_new_btn, {
    #   ...
    # })
    #
    # observeEvent(input$delete_layout_btn, {
    #   ...
    # })
    
    # REMOVED: Input watcher that was creating circular dependencies
    # observe({
    #   val <- input$layout_id
    #   cat("[minimal_test] input$layout_id CHANGED to:", val, "(type:", class(val), ")\n")
    # })

    observeEvent(input$layout_id, {
      selected_value <- input$layout_id
      cat("[minimal_test] layout_id observeEvent triggered with value:", selected_value, "\n")

      if (!is.null(selected_value) && selected_value != "") {
        current_layout_id(as.integer(selected_value))
        cat("[minimal_test] Set current_layout_id to:", as.integer(selected_value), "\n")
      }
    }, ignoreInit = TRUE)
    
    current_layout <- reactive({
      layout_id <- current_layout_id()
      df <- try(get_layout_by_id(layout_id), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || nrow(df) == 0) {
        return(list(
          LayoutID = layout_id,
          SiteID = NA
        ))
      }
      as.list(df[1, ])
    })
    
    observe(priority = -1, {
      layout <- current_layout()
      site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) "" else as.character(layout$SiteID)
      updateSelectInput(session, "layout_site_id", selected = site_id)
    })
    
    sites_data <- reactive({
      refresh_val <- sites_refresh()
      cat("[minimal_test] sites_data() CALLED - refresh trigger value:", refresh_val, "\n")
      df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        cat("[minimal_test] list_sites FAILED\n")
        return(data.frame())
      }
      cat("[minimal_test] list_sites SUCCESS - returned", nrow(df), "sites\n")
      df
    })

    observe({
      cat("[minimal_test] SITES DROPDOWN UPDATE OBSERVER FIRED\n")

      # Get sites data (this is the reactive dependency)
      sites <- sites_data()
      cat("[minimal_test] Got", nrow(sites), "sites from reactive\n")

      # Check if input exists using isolate() to avoid creating dependency
      input_exists <- isolate(!is.null(input$layout_site_id))
      cat("[minimal_test] input$layout_site_id exists (isolated check):", input_exists, "\n")

      if (!input_exists) {
        cat("[minimal_test] Sites input doesn't exist yet, skipping update\n")
        return()
      }

      choices <- c("(None)" = "")
      if (nrow(sites) > 0) {
        choices <- c(choices, setNames(sites$SiteID, paste0(sites$SiteCode, " - ", sites$SiteName)))
      }
      cat("[minimal_test] Prepared", length(choices), "site choices\n")

      # Use JavaScript to update (same as layouts dropdown)
      choices_json <- jsonlite::toJSON(as.list(choices), auto_unbox = TRUE)

      shinyjs::runjs(sprintf("
        var sel = document.getElementById('%s');
        if (sel) {
          sel.innerHTML = '';
          var choices = %s;
          Object.keys(choices).forEach(function(name) {
            var opt = document.createElement('option');
            opt.value = choices[name];
            opt.text = name;
            sel.appendChild(opt);
          });
          $(sel).trigger('change');
          console.log('[UPDATE] Sites dropdown populated with ' + sel.options.length + ' options');
        }
      ", session$ns("layout_site_id"), choices_json))

      cat("[minimal_test] Sites dropdown updated via JavaScript\n")
    })
    
    observeEvent(input$layout_site_id, {
      layout_id <- current_layout_id()
      if (is.null(layout_id) || is.na(layout_id)) return()
      
      site_id_value <- as_optional_integer_na(input$layout_site_id)
      
      tryCatch({
        layout <- current_layout()
        update_layout_background(
          layout_id = layout_id,
          canvas_id = if (is.null(layout$CanvasID) || is.na(layout$CanvasID)) NA else layout$CanvasID,
          site_id = site_id_value,
          rotation = f_or(layout$BackgroundRotation, 0),
          pan_x = f_or(layout$BackgroundPanX, 0),
          pan_y = f_or(layout$BackgroundPanY, 0),
          scale_x = f_or(layout$BackgroundScaleX, 1),
          scale_y = f_or(layout$BackgroundScaleY, 1)
        )
      }, error = function(e) {
        notify_error("Error updating site", e)
      })
    }, ignoreInit = TRUE)
    
    # Watch for when the input first appears (UI rendered) and trigger refresh
    # Use observeEvent with once=TRUE to avoid circular dependencies
    observeEvent(input$layout_id, {
      cat("[minimal_test] Input appeared! Value:", input$layout_id, "\n")
      cat("[minimal_test] Triggering data refresh...\n")

      isolate({
        layouts_refresh(layouts_refresh() + 1)
        sites_refresh(sites_refresh() + 1)
      })
    }, once = TRUE, ignoreNULL = TRUE)

    cat("[minimal_test] Setup complete - waiting for UI to render\n")
    
    output$debug_output <- renderText({
      layout_id <- input$layout_id
      site_id <- input$layout_site_id
      paste0(
        "Layout selection: ", layout_id, "\n",
        "Layouts status: ", layouts_status(), "\n",
        "Site selection: ", site_id
      )
    })

    cat("[minimal_test] ======================================\n")
    cat("[minimal_test] MODULE SERVER INITIALIZATION COMPLETE\n")
    cat("[minimal_test] ======================================\n")
  })
}

# Test runner focused solely on the layout selector
run_minimal_test <- function() {
  library(shiny)
  library(shinyjs)
  
  if (!exists("db_pool")) {
    source("R/db/connect_wrappers.R", local = TRUE)
  }
  
  ui <- fluidPage(
    title = "Minimal Layout Selector Test",
    minimal_test_ui("test")
  )
  
  server <- function(input, output, session) {
    minimal_test_server("test", pool = db_pool())
  }
  
  cat("\n=== Launching Minimal Layout Selector Test ===\n\n")
  
  shinyApp(ui, server, options = list(launch.browser = TRUE))
}

