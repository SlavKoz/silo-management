#!/usr/bin/env Rscript
# Minimal test for layout selector with "Add New" functionality

library(shiny)
library(shinyjs)

# Mock database - use environment to persist data
mock_layouts_env <- new.env()
mock_layouts_env$layouts <- data.frame(
  LayoutID = c(1, 2, 3),
  LayoutName = c("Layout A", "Layout B", "Layout C"),
  stringsAsFactors = FALSE
)
mock_layouts_env$next_id <- 4

get_layouts <- function() {
  cat("[Mock] Fetching layouts, count:", nrow(mock_layouts_env$layouts), "\n")
  mock_layouts_env$layouts
}

create_layout_mock <- function(name) {
  # Insert to mock database
  new_id <- mock_layouts_env$next_id
  mock_layouts_env$next_id <- mock_layouts_env$next_id + 1

  new_row <- data.frame(
    LayoutID = new_id,
    LayoutName = name,
    stringsAsFactors = FALSE
  )

  mock_layouts_env$layouts <- rbind(mock_layouts_env$layouts, new_row)

  cat("[Mock] Created layout:", name, "with ID:", new_id, "\n")
  cat("[Mock] Total layouts now:", nrow(mock_layouts_env$layouts), "\n")
  return(new_id)
}

# UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      .toolbar {
        padding: 1rem;
        background: #e9ecef;
        border-radius: 4px;
      }
      .toolbar .form-group {
        margin-bottom: 0;
        display: inline-block;
      }
      .toolbar select.form-control {
        padding: 0.15rem 0.5rem;
        height: 26px;
        font-size: 12px;
        line-height: 1.2;
        width: 180px;
      }
      .toolbar input[type='text'].form-control {
        padding: 0.15rem 0.5rem;
        height: 26px;
        font-size: 12px;
        line-height: 1.2;
      }
      #text_container {
        display: inline-flex;
        align-items: center;
      }
      .info-box {
        margin-top: 1rem;
        padding: 1rem;
        background: #f8f9fa;
        border: 1px solid #ddd;
        border-radius: 4px;
      }
    "))
  ),

  titlePanel("Layout Selector Test"),

  div(class = "toolbar",
    div(style = "display: inline-flex; align-items: center; gap: 0.3rem;",
      # Add New button
      actionButton("add_new_btn", "Add New", class = "btn-sm btn-primary",
                   style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;"),

      # Layout label
      tags$label("Layout:", style = "margin: 0; font-size: 13px; font-weight: normal;"),

      # Select input (visible by default)
      div(id = "select_container", style = "display: inline-block;",
          selectInput("layout_id", label = NULL, choices = NULL, width = "180px",
                     selectize = FALSE)
      ),

      # Text input + Save button (hidden by default)
      div(id = "text_container", style = "display: none; inline-flex; gap: 0.2rem;",
          textInput("new_layout_name", label = NULL, placeholder = "Enter name...",
                   width = "130px"),
          actionButton("save_new_btn", "Save", class = "btn-sm btn-success",
                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 46px;")
      ),

      # JavaScript for Escape key handler
      tags$script(HTML("
        $(document).on('keydown', '#new_layout_name', function(e) {
          if (e.which === 27) { // Escape key
            $('#text_container').hide();
            $('#select_container').show();
            $(this).val('');
          }
        });
      "))
    ),
    actionButton("test_btn", "Test Button", class = "btn-sm btn-secondary")
  ),

  div(class = "info-box",
    h4("Current State:"),
    verbatimTextOutput("state_info")
  )
)

# Server
server <- function(input, output, session) {

  # Reactive values
  current_layout_id <- reactiveVal(1)
  layouts_refresh <- reactiveVal(0)

  # Load layouts data
  layouts_data <- reactive({
    layouts_refresh()  # Depend on refresh trigger
    get_layouts()
  })

  # Populate dropdown
  observe({
    layouts <- layouts_data()
    cat("[Populate] Layouts count:", nrow(layouts), "\n")

    if (nrow(layouts) > 0) {
      choices <- setNames(layouts$LayoutID, layouts$LayoutName)
      cat("[Populate] Choices:", paste(names(choices), "=", choices, collapse=", "), "\n")

      # Use isolate to read current_layout_id without creating a dependency
      current_id <- isolate(current_layout_id())
      selected_val <- if (!is.null(current_id) && !is.na(current_id) &&
                         as.character(current_id) %in% choices) {
        as.character(current_id)
      } else {
        as.character(layouts$LayoutID[1])
      }
      cat("[Populate] Updating dropdown, selected:", selected_val, "\n")

      updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)
    }
  })

  # Handle "Add New" button - toggle to text input mode
  observeEvent(input$add_new_btn, {
    cat("[Add New] Switching to text input mode\n")
    shinyjs::hide("select_container")
    shinyjs::show("text_container")
    # Focus on text input
    shinyjs::runjs("$('#new_layout_name').focus();")
  })

  # Handle "Save" button - create layout and toggle back to select mode
  observeEvent(input$save_new_btn, {
    layout_name <- trimws(input$new_layout_name)
    cat("[Save] Creating layout:", shQuote(layout_name), "\n")

    if (layout_name == "") {
      showNotification("Please enter a layout name", type = "error")
      return()
    }

    tryCatch({
      new_layout_id <- create_layout_mock(layout_name)
      cat("[Save] Created layout", layout_name, "with ID", new_layout_id, "\n")

      # Clear text input
      updateTextInput(session, "new_layout_name", value = "")

      # Refresh layouts and select the new one
      current_layout_id(new_layout_id)
      layouts_refresh(layouts_refresh() + 1)

      # Toggle back to select mode
      shinyjs::hide("text_container")
      shinyjs::show("select_container")

      showNotification(paste("Layout", shQuote(layout_name), "created"),
                      type = "message", duration = 3)

    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
      cat("[Save] Error:", e$message, "\n")
    })
  })

  # Handle layout selection from dropdown
  observeEvent(input$layout_id, {
    selected_value <- input$layout_id
    cat("[Handler] Selected:", selected_value, "\n")

    if (!is.null(selected_value) && selected_value != "") {
      current_layout_id(as.integer(selected_value))
    }
  }, ignoreInit = TRUE)

  # Display state
  output$state_info <- renderText({
    paste0(
      "Current Layout ID: ", current_layout_id(), "\n",
      "Selected Value: ", ifelse(is.null(input$layout_id), "NULL", input$layout_id), "\n",
      "Layouts Count: ", nrow(layouts_data())
    )
  })
}

cat("\n=== Layout Selector Test (Separate Add/Select Modes) ===\n")
cat("New approach - separate buttons and toggle visibility:\n")
cat("1. Default: 'Add New' button | 'Layout:' label | Select dropdown (180px)\n")
cat("2. Click 'Add New': Hide select, show text input (130px) + 'Save' button (46px)\n")
cat("3. Click 'Save': Create layout, hide text input, show select dropdown\n")
cat("4. Press 'Escape': Cancel add mode, return to select dropdown\n")
cat("5. NO flicking - simple selectInput with fixed width\n")
cat("6. Watch console for debug output\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
