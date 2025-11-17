#!/usr/bin/env Rscript
# Minimal test for fit view mechanism

library(shiny)

ui <- fluidPage(
  title = "Fit View Test",
  tags$h3("Minimal Fit View Test"),

  # Inline JavaScript
  tags$script(HTML("
    (function() {
      let canvas, ctx, state;

      $(document).on('shiny:connected', function() {
        canvas = document.getElementById('test-canvas');
        ctx = canvas.getContext('2d');

        state = {
          canvas: canvas,
          ctx: ctx,
          shapes: [],
          panX: 0,
          panY: 0,
          zoom: 1
        };

        console.log('[Test] Canvas initialized');
      });

      // Render function
      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        ctx.save();
        ctx.translate(state.panX, state.panY);
        ctx.scale(state.zoom, state.zoom);

        // Draw shapes
        state.shapes.forEach(s => {
          if (s.type === 'circle') {
            ctx.beginPath();
            ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(59, 130, 246, 0.3)';
            ctx.fill();
            ctx.strokeStyle = 'rgba(59, 130, 246, 0.8)';
            ctx.lineWidth = 2;
            ctx.stroke();

            // Label
            ctx.font = '14px sans-serif';
            ctx.fillStyle = '#000';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText(s.label, s.x, s.y);
          }
        });

        ctx.restore();

        // Draw info
        ctx.fillStyle = '#000';
        ctx.font = '12px monospace';
        ctx.fillText('Zoom: ' + state.zoom.toFixed(2) + ' | Pan: ' + state.panX.toFixed(0) + ', ' + state.panY.toFixed(0), 10, 20);
      }

      // Fit view function
      function fitView() {
        console.log('[Test] fitView called, state:', state ? 'exists' : 'null');

        if (!state) {
          console.error('[Test] State is null!');
          return;
        }

        if (!state.shapes) {
          console.error('[Test] state.shapes is null!');
          return;
        }

        if (state.shapes.length === 0) {
          console.log('[Test] No shapes to fit (empty array)');
          return;
        }

        console.log('[Test] Fitting', state.shapes.length, 'shapes:', state.shapes);

        // Calculate bounds
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

        state.shapes.forEach((s, idx) => {
          const sMinX = s.x - s.r;
          const sMinY = s.y - s.r;
          const sMaxX = s.x + s.r;
          const sMaxY = s.y + s.r;

          console.log('[Test] Shape', idx, s.label, '- bounds:', sMinX, sMinY, sMaxX, sMaxY);

          minX = Math.min(minX, sMinX);
          minY = Math.min(minY, sMinY);
          maxX = Math.max(maxX, sMaxX);
          maxY = Math.max(maxY, sMaxY);
        });

        console.log('[Test] Total bounds: minX=', minX, 'minY=', minY, 'maxX=', maxX, 'maxY=', maxY);

        const boundsWidth = maxX - minX;
        const boundsHeight = maxY - minY;
        const centerX = (minX + maxX) / 2;
        const centerY = (minY + maxY) / 2;

        console.log('[Test] BoundsWidth:', boundsWidth, 'BoundsHeight:', boundsHeight);
        console.log('[Test] Center:', centerX, centerY);

        // Calculate zoom to fit (with 10% padding)
        const zoomX = (state.canvas.width * 0.9) / boundsWidth;
        const zoomY = (state.canvas.height * 0.9) / boundsHeight;
        const newZoom = Math.min(zoomX, zoomY, 3);

        console.log('[Test] Canvas size:', state.canvas.width, state.canvas.height);
        console.log('[Test] ZoomX:', zoomX, 'ZoomY:', zoomY, 'Selected:', newZoom);

        state.zoom = newZoom;

        // Center the view
        state.panX = state.canvas.width / 2 - centerX * state.zoom;
        state.panY = state.canvas.height / 2 - centerY * state.zoom;

        console.log('[Test] Applied zoom:', state.zoom.toFixed(2), 'panX:', state.panX.toFixed(0), 'panY:', state.panY.toFixed(0));

        render();
      }

      // Message handlers
      Shiny.addCustomMessageHandler('test:loadShapes', function(shapes) {
        state.shapes = shapes;
        console.log('[Test] Loaded', shapes.length, 'shapes');
        render();
      });

      Shiny.addCustomMessageHandler('test:fitView', function(message) {
        console.log('[Test] Fit view triggered');
        fitView();
      });

    })();
  ")),

  tags$style(HTML("
    #test-canvas {
      border: 2px solid #333;
      display: block;
      margin: 20px 0;
    }
  ")),

  tags$canvas(id = "test-canvas", width = 800, height = 600),

  div(
    actionButton("load_shapes", "Load Test Shapes", class = "btn-primary"),
    actionButton("fit_view", "Fit View", class = "btn-success"),
    actionButton("reset", "Reset View", class = "btn-secondary")
  )
)

server <- function(input, output, session) {

  # Load test shapes
  observeEvent(input$load_shapes, {
    # Create shapes at various positions (simulating your data)
    shapes <- list(
      list(type = "circle", x = 100, y = 100, r = 30, label = "A"),
      list(type = "circle", x = 600, y = 400, r = 40, label = "B"),
      list(type = "circle", x = 1200, y = 300, r = 35, label = "C"),
      list(type = "circle", x = 800, y = -50, r = 25, label = "D"),
      list(type = "circle", x = 400, y = 500, r = 45, label = "E")
    )

    session$sendCustomMessage("test:loadShapes", shapes)
    cat("[Server] Sent", length(shapes), "shapes to canvas\n")
  })

  # Fit view
  observeEvent(input$fit_view, {
    session$sendCustomMessage("test:fitView", list())
    cat("[Server] Triggered fit view\n")
  })

  # Reset
  observeEvent(input$reset, {
    session$sendCustomMessage("test:loadShapes", list())
    cat("[Server] Reset canvas\n")
  })
}

cat("\n=== Minimal Fit View Test ===\n")
cat("1. Click 'Load Test Shapes' to add circles\n")
cat("2. Click 'Fit View' to test fit-to-screen\n")
cat("3. Check browser console (F12) for debug output\n\n")

shinyApp(ui, server, options = list(launch.browser = TRUE))
