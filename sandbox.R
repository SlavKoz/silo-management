#!/usr/bin/env Rscript
# Minimal test for click-to-add placements

library(shiny)
library(shinyjs)

# UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$script(HTML("
      var shapes = [];

      function drawCanvas() {
        var canvas = document.getElementById('test_canvas');
        var ctx = canvas.getContext('2d');

        // Clear canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Draw all shapes
        shapes.forEach(function(shape) {
          console.log('[Sandbox] Drawing shape:', shape);

          if (shape.template === 'circle_20') {
            ctx.beginPath();
            ctx.arc(shape.x, shape.y, 20, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(59, 130, 246, 0.3)';
            ctx.fill();
            ctx.strokeStyle = 'rgba(59, 130, 246, 0.8)';
            ctx.lineWidth = 2;
            ctx.stroke();
          } else if (shape.template === 'rect_60_30') {
            ctx.fillStyle = 'rgba(59, 130, 246, 0.3)';
            ctx.fillRect(shape.x - 30, shape.y - 15, 60, 30);
            ctx.strokeStyle = 'rgba(59, 130, 246, 0.8)';
            ctx.lineWidth = 2;
            ctx.strokeRect(shape.x - 30, shape.y - 15, 60, 30);
          }
        });

        console.log('[Sandbox] Canvas redrawn with', shapes.length, 'shapes');
      }

      $(document).ready(function() {
        // Simple canvas click handler
        $('#test_canvas').on('click', function(e) {
          var rect = this.getBoundingClientRect();
          var x = e.clientX - rect.left;
          var y = e.clientY - rect.top;

          console.log('[Sandbox] Canvas clicked at:', x, y);
          console.log('[Sandbox] Shape template:', $('#shape_template').val());

          // Send to Shiny
          var template = $('#shape_template').val();
          if (template && template !== '') {
            console.log('[Sandbox] Sending to Shiny input: canvas_click_add');
            Shiny.setInputValue('canvas_click_add', {
              x: x,
              y: y,
              template: template
            }, {priority: 'event'});
          } else {
            console.log('[Sandbox] No template selected');
          }
        });
      });

      // Handler to receive shapes from R
      Shiny.addCustomMessageHandler('updateShapes', function(data) {
        console.log('[Sandbox] Received shapes from R:', data);
        shapes = data;
        drawCanvas();
      });
    "))
  ),

  titlePanel("Click-to-Add Test"),

  div(style = "padding: 1rem; background: #e9ecef; margin-bottom: 1rem;",
    tags$label("Shape Template:"),
    selectInput("shape_template", label = NULL,
                choices = c("(select)" = "", "Circle 20px" = "circle_20", "Rectangle 60x30" = "rect_60_30"),
                width = "200px")
  ),

  div(style = "margin-bottom: 1rem;",
    tags$canvas(id = "test_canvas", width = 800, height = 400,
                style = "border: 2px solid #333; background: #f8f9fa; cursor: crosshair;")
  ),

  div(class = "info-box", style = "padding: 1rem; background: #fff; border: 1px solid #ddd;",
    h4("Debug Info:"),
    verbatimTextOutput("debug_info")
  )
)

# Server
server <- function(input, output, session) {

  # Track shapes
  shapes_list <- reactiveVal(list())
  click_count <- reactiveVal(0)
  last_click <- reactiveVal(NULL)

  # Handle canvas click
  observeEvent(input$canvas_click_add, {
    cat("\n[Sandbox R] *** observeEvent FIRED ***\n")

    click_data <- input$canvas_click_add
    cat("[Sandbox R] Received data:", !is.null(click_data), "\n")

    if (!is.null(click_data)) {
      cat("[Sandbox R] Click at:", click_data$x, click_data$y, "template:", click_data$template, "\n")

      # Add new shape to list
      current_shapes <- shapes_list()
      new_shape <- list(
        x = click_data$x,
        y = click_data$y,
        template = click_data$template
      )
      current_shapes[[length(current_shapes) + 1]] <- new_shape
      shapes_list(current_shapes)

      cat("[Sandbox R] Total shapes:", length(current_shapes), "\n")
      cat("[Sandbox R] Sending shapes to JavaScript\n")

      # Send updated shapes to JavaScript
      session$sendCustomMessage("updateShapes", current_shapes)

      click_count(click_count() + 1)
      last_click(click_data)

      showNotification(
        paste0("Added ", click_data$template, " at (", round(click_data$x), ", ", round(click_data$y), ")"),
        type = "message",
        duration = 2
      )
    }
  }, ignoreInit = TRUE)

  # Display debug info
  output$debug_info <- renderText({
    paste0(
      "Selected Template: ", ifelse(is.null(input$shape_template), "NULL", input$shape_template), "\n",
      "Click Count: ", click_count(), "\n",
      "Shapes Count: ", length(shapes_list()), "\n",
      "Last Click: ", if (!is.null(last_click())) {
        paste0("(", last_click()$x, ", ", last_click()$y, ") - ", last_click()$template)
      } else {
        "None"
      }
    )
  })
}

cat("\n=== Click-to-Add Sandbox Test ===\n")
cat("1. Select a shape template from dropdown\n")
cat("2. Click anywhere on the canvas\n")
cat("3. Watch console for:\n")
cat("   - Browser console: [Sandbox] messages\n")
cat("   - R console: [Sandbox R] messages\n")
cat("4. If observeEvent fires, you'll see notification\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
