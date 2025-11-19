#!/usr/bin/env Rscript
# Sandbox for sliding panel with React Table

library(shiny)
library(shiny.semantic)
library(shinyjs)

# Load modules
source("R/utils/f_helper_core.R", local = TRUE)
source("R/react_table/mod_react_table.R", local = TRUE)

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
          h3(class = "ui header", style = "margin: 0;", "Placement React Table"),
          actionButton("close_panel_btn", "", icon = icon("times"),
                       class = "ui icon button", style = "margin: 0;")
      ),
      div(class = "panel-content",
          react_table_ui("silo_table", height = "calc(100vh - 160px)")
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
  
  sample_columns <- list(
    list(id = "PlacementID", label = "ID", width = 80, type = "number"),
    list(id = "PlacementName", label = "Placement", width = 180),
    list(id = "Status", label = "Status", width = 120),
    list(id = "UpdatedAt", label = "Updated", width = 180)
  )
  
  sample_data <- data.frame(
    PlacementID = 1:6,
    PlacementName = c(
      "North Hopper",
      "South Hopper",
      "West Feed",
      "Main Intake",
      "Aux Mixer",
      "Cooling Bin"
    ),
    Status = c("Active", "Paused", "Active", "Maintenance", "Active", "Offline"),
    UpdatedAt = format(Sys.time() - c(1200, 3600, 7200, 10800, 20000, 40000), "%Y-%m-%d %H:%M"),
    stringsAsFactors = FALSE
  )
  
  react_table_server(
    "silo_table",
    columns = sample_columns,
    data_fn = function() sample_data,
    key = "PlacementID",
    selection = "single"
  )
}

cat("\n=== Sliding Panel Sandbox ===\n")
cat("1. Click 'Open Panel' button or arrow on right side\n")
cat("2. Panel slides in from right (400px width)\n")
cat("3. Contains React Table with placement sample data\n")
cat("4. Close with X button, arrow, or ESC key\n")
cat("5. Panel slides out smoothly\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
