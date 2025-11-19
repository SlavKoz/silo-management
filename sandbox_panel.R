#!/usr/bin/env Rscript
# Sandbox for sliding panel with React Table

library(shiny)
library(shiny.semantic)
library(shinyjs)

# Load form module
source("R/react_table/mod_html_form.R", local = TRUE)
source("R/react_table/html_form_renderer.R", local = TRUE)
source("R/utils/f_helper_core.R", local = TRUE)

# UI
ui <- semanticPage(
  useShinyjs(),

  tags$head(
    tags$style(HTML("
      body {
        overflow: hidden !important;
      }

      .main-content {
        margin-right: 0 !important;
        transition: margin-right 0.5s ease;
      }

      .main-content.panel-open {
        margin-right: 400px;
      }

      .sliding-panel {
        position: fixed;
        top: 0;
        right: -400px;
        width: 400px;
        height: 100vh;
        background: white;
        box-shadow: -2px 0 8px rgba(0,0,0,0.15);
        transition: right 0.5s ease;
        z-index: 1000;
        overflow-y: auto;
      }

      .sliding-panel.open {
        right: 0;
      }

      .panel-toggle {
        position: fixed;
        top: 50%;
        right: 0;
        transform: translateY(-50%);
        width: 30px;
        height: 80px;
        background: #2185d0;
        color: white;
        border: none;
        border-radius: 4px 0 0 4px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 999;
        transition: right 0.5s ease;
        font-size: 18px;
      }

      .panel-toggle.panel-open {
        right: 400px;
      }

      .panel-toggle:hover {
        background: #1678c2;
      }

      .panel-header {
        padding: 1rem;
        background: #f8f9fa;
        border-bottom: 1px solid #ddd;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .panel-content {
        padding: 1rem;
      }

      .test-canvas {
        border: 2px solid #333;
        background: #f8f9fa;
        cursor: crosshair;
      }
    "))
  ),

  # Main content
  div(class = "main-content", id = "main-content",
    div(class = "ui container", style = "padding: 2rem;",
      h2(class = "ui header", "Sliding Panel Test"),

      actionButton("open_panel_btn", "Open Panel", class = "ui primary button"),

      div(style = "margin-top: 2rem;",
        tags$canvas(id = "test_canvas", class = "test-canvas", width = 800, height = 400)
      )
    )
  ),

  # Panel toggle arrow (visible when panel closed)
  tags$button(id = "panel_toggle", class = "panel-toggle",
    icon("chevron left")
  ),

  # Sliding panel
  div(id = "sliding_panel", class = "sliding-panel",
    div(class = "panel-header",
      h3(class = "ui header", style = "margin: 0;", "Silo Details"),
      actionButton("close_panel_btn", "", icon = icon("times"),
                   class = "ui icon button", style = "margin: 0;")
    ),
    div(class = "panel-content",
      mod_html_form_ui("silo_form", max_width = "100%", margin = "0")
    )
  ),

  tags$script(HTML("
    $(document).ready(function() {
      // Toggle panel
      function togglePanel(open) {
        if (open) {
          $('#sliding_panel').addClass('open');
          $('#main-content').addClass('panel-open');
          $('#panel_toggle').addClass('panel-open');
          $('#panel_toggle i').removeClass('chevron left').addClass('chevron right');
        } else {
          $('#sliding_panel').removeClass('open');
          $('#main-content').removeClass('panel-open');
          $('#panel_toggle').removeClass('panel-open');
          $('#panel_toggle i').removeClass('chevron right').addClass('chevron left');
        }
      }

      // Open panel button
      $('#open_panel_btn').on('click', function() {
        togglePanel(true);
      });

      // Close panel button
      $('#close_panel_btn').on('click', function() {
        togglePanel(false);
      });

      // Panel toggle arrow
      $('#panel_toggle').on('click', function() {
        var isOpen = $('#sliding_panel').hasClass('open');
        togglePanel(!isOpen);
      });

      // ESC key to close
      $(document).on('keydown', function(e) {
        if (e.key === 'Escape' && $('#sliding_panel').hasClass('open')) {
          togglePanel(false);
        }
      });
    });
  "))
)

# Server
server <- function(input, output, session) {

  # Sample schema for the form
  schema_config <- reactive({
    list(
      fields = list(
        list(name = "SiloCode", label = "Silo Code", type = "text", required = TRUE),
        list(name = "SiloName", label = "Silo Name", type = "text", required = TRUE),
        list(name = "VolumeM3", label = "Volume (m³)", type = "number", required = TRUE),
        list(name = "Area", label = "Area", type = "text"),
        list(name = "IsActive", label = "Is Active", type = "checkbox"),
        list(name = "Notes", label = "Notes", type = "textarea", rows = 3)
      ),
      columns = 1
    )
  })

  # Sample form data
  form_data <- reactive({
    list(
      SiloCode = "",
      SiloName = "",
      VolumeM3 = 100,
      Area = "",
      IsActive = TRUE,
      Notes = ""
    )
  })

  # Form module
  form_module <- mod_html_form_server(
    id = "silo_form",
    schema_config = schema_config,
    form_data = form_data,
    title_field = "SiloName",
    show_header = FALSE,
    show_delete_button = FALSE,
    on_save = function(data) {
      cat("\n[Sandbox] Form saved:\n")
      cat("  SiloCode:", data$SiloCode, "\n")
      cat("  SiloName:", data$SiloName, "\n")
      cat("  VolumeM3:", data$VolumeM3, "\n")

      showNotification("Silo saved!", type = "message", duration = 2)

      # Close panel after save
      shinyjs::runjs("
        $('#sliding_panel').removeClass('open');
        $('#main-content').removeClass('panel-open');
        $('#panel_toggle').removeClass('panel-open');
        $('#panel_toggle i').removeClass('chevron right').addClass('chevron left');
      ")

      return(TRUE)
    }
  )
}

cat("\n=== Sliding Panel Sandbox ===\n")
cat("1. Click 'Open Panel' button or arrow on right side\n")
cat("2. Panel slides in from right (400px width)\n")
cat("3. Contains React Table form\n")
cat("4. Close with X button, arrow, or ESC key\n")
cat("5. Panel slides out smoothly\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
