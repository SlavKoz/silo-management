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
          
          # Column 1: Add New Layout button
          actionButton(
            ns("add_new_layout_btn"), "Add New", class = "btn-sm btn-primary",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),
          
          # Column 2: Layout label
          tags$label(
            "Layout:",
            style = "margin: 0; font-size: 13px; font-weight: normal;"
          ),
          
          # Column 3: Layout selector (or action input for new layout)
          div(
            style = "position: relative;",
            # Select input (visible by default)
            div(
              id = ns("select_container"),
              style = "display: block;",
              shiny::selectInput(
                ns("layout_id"), label = NULL, choices = c(), width = "100%",
                selectize = FALSE
              )
            ),
            # Fomantic-style action input (hidden by default)
            div(
              id = ns("text_container"),
              class = "ui action input",
              style = "display: none; width: 100%;",
              tags$input(
                type = "text",
                id = ns("new_layout_name"),
                placeholder = "Enter name...",
                style = "height: 26px; font-size: 12px; padding: 0.15rem 0.5rem;"
              ),
              actionButton(
                ns("save_new_btn"), "Save", class = "ui button btn-sm btn-success",
                style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;"
              )
            )
          ),
          
          # Column 4: Site label
          tags$label(
            "Site:",
            style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right;"
          ),
          
          # Column 5: Site selector
          shiny::selectInput(
            ns("layout_site_id"), label = NULL, choices = c(), width = "100%",
            selectize = TRUE
          ),
          
          # Spacer columns to preserve original formatting
          div(),
          div(),
          
          # Column 8: Empty spacer
          div(),
          
          # Column 9: Delete button (far right)
          actionButton(
            ns("delete_layout_btn"), "Delete", class = "btn-sm btn-danger",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          )
        ),
        
        # JavaScript for layout input toggle
        tags$script(HTML(sprintf(
          "$(document).on('keyup', '#%s', function(e) {\n            if (e.key === 'Enter') {\n              e.preventDefault();\n              $('#%s').click();\n            }\n          });\n          $(document).on('keydown', '#%s', function(e) {\n            if (e.which === 27) { // Escape key\n              $('#%s').hide();\n              $('#%s').show();\n              $(this).val('');\n            }\n          });",
          ns("new_layout_name"), ns("save_new_btn"),
          ns("new_layout_name"), ns("text_container"), ns("select_container")
        )))
      )
    ),
    
    verbatimTextOutput(ns("debug_output"))
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
    
    
    layouts_data <- reactive({
      layouts_refresh()
      layouts_status("Querying layouts...")
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        msg <- if (inherits(df, "try-error")) conditionMessage(attr(df, "condition")) else "query returned NULL"
        layouts_status(paste("ERROR:", msg))
        cat("[minimal] list_canvas_layouts failed:", msg, "\n")
        return(data.frame())
      }
      layouts_status(paste("Loaded", nrow(df), "layouts"))
      df
    })
    
    observe({
      layouts <- layouts_data()
      
      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)
        updateSelectInput(session, "layout_id", choices = choices, selected = choices[1])
      } else {
        
        status <- layouts_status()
        if (is.character(status) && grepl("^ERROR", status)) {
          showNotification(status, type = "error", duration = NULL)
        }
        
        updateSelectInput(session, "layout_id", choices = c("No layouts found" = ""))
      }
    })
    
    observeEvent(input$add_new_layout_btn, {
      shinyjs::hide("select_container")
      shinyjs::show("text_container")
      shinyjs::runjs(paste0("$('#", ns("new_layout_name"), "').focus();"))
    })
    
    observeEvent(input$save_new_btn, {
      layout_name <- trimws(input$new_layout_name)
      
      if (layout_name == "") {
        showNotification("Please enter a layout name", type = "error")
        return()
      }
      
      existing <- layouts_data()
      if (nrow(existing) > 0) {
        existing_names <- trimws(existing$LayoutName)
        match_idx <- match(tolower(layout_name), tolower(existing_names))
        if (!is.na(match_idx)) {
          showNotification(
            paste0("A layout called ", shQuote(layout_name), " already exists."),
            type = "error"
          )
          return()
        }
      }
      
      tryCatch({
        new_layout_id <- create_canvas_layout(layout_name = layout_name)
        
        updateTextInput(session, "new_layout_name", value = "")
        
        current_layout_id(new_layout_id)
        layouts_refresh(layouts_refresh() + 1)
        
        shinyjs::hide("text_container")
        shinyjs::show("select_container")
        
        showNotification(
          paste("Layout", shQuote(layout_name), "created"),
          type = "message", duration = 3
        )
        
      }, error = function(e) {
        notify_error("Error creating layout", e)
      })
    })
    
    observeEvent(input$delete_layout_btn, {
      layout_id <- current_layout_id()
      
      if (is.null(layout_id) || is.na(layout_id) || layout_id == "") {
        showNotification("No layout selected to delete.", type = "warning")
        return()
      }
      
      placements <- try(
        list_placements(layout_id = layout_id, limit = 1),
        silent = TRUE
      )
      if (!inherits(placements, "try-error") &&
          !is.null(placements) && nrow(placements) > 0) {
        showNotification(
          "This layout has silo placements and cannot be deleted in this test.",
          type = "error",
          duration = NULL
        )
        return()
      }
      
      ok <- tryCatch({
        delete_canvas_layout(layout_id)
        TRUE
      }, error = function(e) {
        showNotification(
          paste("Delete failed:", conditionMessage(e)),
          type = "error"
        )
        FALSE
      })
      if (!ok) return()
      
      showNotification("Layout deleted.", type = "message")
      
      current_layout_id(NULL)
      layouts_refresh(layouts_refresh() + 1)
      updateSelectInput(session, "layout_id", selected = "")
      
      shinyjs::hide("text_container")
      shinyjs::show("select_container")
    })
    
    observeEvent(input$layout_id, {
      selected_value <- input$layout_id
      
      if (!is.null(selected_value) && selected_value != "") {
        current_layout_id(as.integer(selected_value))
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
      sites_refresh()
      df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })
    
    observe({
      sites <- sites_data()
      choices <- c("(None)" = "")
      if (nrow(sites) > 0) {
        choices <- c(choices, setNames(sites$SiteID, paste0(sites$SiteCode, " - ", sites$SiteName)))
      }
      updateSelectInput(session, "layout_site_id", choices = choices)
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
    
    if (!is.null(route) && is.function(route)) {
      observe({
        current_route <- route()
        
        if (length(current_route) > 0 && current_route[1] == "minimal") {
          if (!ui_initialized()) {
            ui_initialized(TRUE)
            
            isolate({
              layouts_refresh(layouts_refresh() + 1)
              sites_refresh(sites_refresh() + 1)
            })
          }
        }
      })
      # Always force at least one refresh when the module is mounted. In the
      # router flow, the route observer above may not fire if navigation does not
      # change after initialization, which leaves the dropdown empty.
      observeEvent(TRUE, {
        layouts_refresh(layouts_refresh() + 1)
        sites_refresh(sites_refresh() + 1)
      }, once = TRUE)
    }
    
    output$debug_output <- renderText({
      layout_id <- input$layout_id
      site_id <- input$layout_site_id
      paste0(
        "Layout selection: ", layout_id, "\n",
        "Layouts status: ", layouts_status(), "\n",
        "Site selection: ", site_id
      )
    })
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

