#!/usr/bin/env Rscript
# Minimal test for layout selector with "Add New" functionality

library(shiny)

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
        height: 28px;
        font-size: 13px;
        line-height: 1.3;
        width: 120px;
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
      tags$label("Layout:", style = "margin: 0; font-size: 13px; font-weight: normal;"),
      selectInput("layout_id", label = NULL, choices = NULL, width = "120px")
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

  # Populate dropdown (only when layouts data changes, not when selection changes)
  observe({
    layouts <- layouts_data()
    choices <- setNames(layouts$LayoutID, layouts$LayoutName)
    # Add "Add New..." option at the end
    choices <- c(choices, "Add New..." = "__ADD_NEW__")

    # Use isolate to read current_layout_id without creating a dependency
    current_id <- isolate(current_layout_id())
    selected_val <- if (!is.null(current_id) && !is.na(current_id) && as.character(current_id) %in% choices) {
      as.character(current_id)
    } else {
      NULL
    }

    cat("[Populate] Choices:", paste(names(choices), "=", choices, collapse=", "), "\n")

    cat("[Populate] Updating choices, selecting:", selected_val, "\n")
    updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)
  })

  # Handle layout selection
  observeEvent(input$layout_id, {
    selected_value <- input$layout_id

    cat("[Handler] Selected:", selected_value, "\n")

    if (!is.null(selected_value) && selected_value != "") {
      if (selected_value == "__ADD_NEW__") {
        # Show modal for new layout
        cat("[Handler] Opening modal for new layout\n")
        showModal(modalDialog(
          title = "New Layout",
          textInput("new_layout_name", "Layout Name:", placeholder = "Enter name..."),
          tags$script(HTML("
            $(document).ready(function() {
              setTimeout(function() {
                $('#new_layout_name').focus();
                $('#new_layout_name').on('keypress', function(e) {
                  if (e.which === 13) {
                    e.preventDefault();
                    $('#confirm_new_layout').click();
                  }
                });
              }, 300);
            });
          ")),
          footer = tagList(
            modalButton("Cancel"),
            actionButton("confirm_new_layout", "Create", class = "btn-primary")
          ),
          size = "s",
          easyClose = TRUE
        ))
        # Reset dropdown to previous selection
        updateSelectInput(session, "layout_id", selected = as.character(isolate(current_layout_id())))
      } else {
        numeric_value <- as.integer(selected_value)
        current_layout_id(numeric_value)
      }
    }
  }, ignoreInit = TRUE)

  # Handle create new layout
  observeEvent(input$confirm_new_layout, {
    layout_name <- trimws(input$new_layout_name)

    if (layout_name == "") {
      showNotification("Please enter a layout name", type = "error")
      return()
    }

    tryCatch({
      new_layout_id <- create_layout_mock(layout_name)

      # Close modal
      removeModal()

      # Clear input
      updateTextInput(session, "new_layout_name", value = "")

      # Refresh layouts and select the new one
      current_layout_id(new_layout_id)
      layouts_refresh(layouts_refresh() + 1)

      showNotification(paste("Layout", shQuote(layout_name), "created"), type = "message", duration = 3)

    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
      cat("[Handler] Error:", e$message, "\n")
    })
  })

  # Display state
  output$state_info <- renderText({
    paste0(
      "Current Layout ID: ", current_layout_id(), "\n",
      "Selected Value: ", ifelse(is.null(input$layout_id), "NULL", input$layout_id), "\n",
      "Layouts Count: ", nrow(layouts_data())
    )
  })
}

cat("\n=== Layout Selector Test ===\n")
cat("1. Select different layouts from dropdown\n")
cat("2. Verify label is inline with selector\n")
cat("3. Verify selector doesn't overlap Test Button\n")
cat("4. Select 'Add New...' to create a new layout\n")
cat("5. Watch console for debug output\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
