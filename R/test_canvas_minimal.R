# Minimal canvas test - canvas + popup editor
# Click shape to edit, change shape template updates canvas immediately

test_canvas_minimal_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),

    tags$head(
      tags$script(src = paste0("js/f_canvas_minimal.js?v=", format(Sys.time(), "%Y%m%d%H%M%S")))
    ),

    # Simple popup editor (hidden by default)
    div(
      id = ns("popup"),
      style = "display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
              background: white; border: 2px solid #333; padding: 1rem; box-shadow: 0 4px 8px rgba(0,0,0,0.3);
              z-index: 1000; min-width: 300px;",

      h4("Edit Shape", style = "margin-top: 0;"),

      div(style = "margin-bottom: 1rem;",
        tags$label("Silo:"),
        textOutput(ns("popup_silo"))
      ),

      div(style = "margin-bottom: 1rem;",
        tags$label("Shape Template:"),
        selectInput(ns("popup_shape_template"), label = NULL, choices = NULL)
      ),

      div(style = "text-align: right;",
        actionButton(ns("popup_close"), "Close", class = "btn btn-secondary btn-sm")
      )
    ),

    # Backdrop
    div(
      id = ns("backdrop"),
      style = "display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
              background: rgba(0,0,0,0.5); z-index: 999;",
      onclick = sprintf("$('#%s').hide(); $('#%s').hide();", ns("popup"), ns("backdrop"))
    ),

    div(style = "padding: 1rem;",
      h3("Minimal Canvas Test - Click shape to edit"),

      # Canvas
      div(style = "border: 1px solid #ddd; margin-bottom: 1rem;",
        tags$canvas(id = ns("canvas"), width = 800, height = 400)
      ),

      # Add button
      actionButton(ns("add_random"), "Add Random Shape", class = "btn btn-primary")
    )
  )
}

test_canvas_minimal_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values - start with some initial shapes
    placements <- reactiveVal(data.frame(
      PlacementID = c(1, 2, 3),
      SiloCode = c("S1", "S2", "S3"),
      ShapeTemplateID = c(1, 2, 3),
      ShapeType = c("CIRCLE", "RECTANGLE", "TRIANGLE"),
      CenterX = c(150, 400, 650),
      CenterY = c(200, 200, 200),
      Radius = c(30, NA, 25),
      Width = c(NA, 50, NA),
      Height = c(NA, 40, NA),
      stringsAsFactors = FALSE
    ))

    selected_id <- reactiveVal(NULL)

    # Available templates (hardcoded for simplicity)
    templates <- data.frame(
      ShapeTemplateID = 1:3,
      ShapeType = c("CIRCLE", "RECTANGLE", "TRIANGLE"),
      Radius = c(30, NA, 25),
      Width = c(NA, 50, NA),
      Height = c(NA, 40, NA),
      stringsAsFactors = FALSE
    )

    # Populate shape template choices
    updateSelectInput(session, "popup_shape_template",
                      choices = setNames(1:3, c("Circle", "Rectangle", "Triangle")))

    # Add random placement
    observeEvent(input$add_random, {
      df <- placements()

      # Random template
      template_id <- sample(1:3, 1)
      template <- templates[template_id, ]

      # Random position
      x <- runif(1, 100, 700)
      y <- runif(1, 100, 300)

      # Create new placement
      new_id <- if (nrow(df) == 0) 1 else max(df$PlacementID) + 1

      new_row <- data.frame(
        PlacementID = new_id,
        SiloCode = paste0("S", new_id),
        ShapeTemplateID = template_id,
        ShapeType = template$ShapeType,
        CenterX = x,
        CenterY = y,
        Radius = ifelse(is.na(template$Radius), NA, template$Radius),
        Width = ifelse(is.na(template$Width), NA, template$Width),
        Height = ifelse(is.na(template$Height), NA, template$Height),
        stringsAsFactors = FALSE
      )

      placements(rbind(df, new_row))
    })

    # Update canvas when placements change
    observe({
      df <- placements()

      if (nrow(df) == 0) {
        session$sendCustomMessage(paste0(ns("root"), ":setShapes"), list(shapes = list()))
        return()
      }

      # Build shapes
      shapes <- lapply(seq_len(nrow(df)), function(i) {
        p <- df[i, ]

        if (p$ShapeType == "CIRCLE") {
          list(
            id = as.character(p$PlacementID),
            type = "circle",
            x = p$CenterX,
            y = p$CenterY,
            r = p$Radius,
            label = p$SiloCode
          )
        } else if (p$ShapeType == "RECTANGLE") {
          list(
            id = as.character(p$PlacementID),
            type = "rect",
            x = p$CenterX - p$Width / 2,
            y = p$CenterY - p$Height / 2,
            w = p$Width,
            h = p$Height,
            label = p$SiloCode
          )
        } else if (p$ShapeType == "TRIANGLE") {
          list(
            id = as.character(p$PlacementID),
            type = "triangle",
            x = p$CenterX,
            y = p$CenterY,
            r = p$Radius,
            label = p$SiloCode
          )
        }
      })

      session$sendCustomMessage(paste0(ns("root"), ":setShapes"), list(shapes = shapes))
    })

    # Handle shape click - open popup
    observeEvent(input$shape_clicked, {
      clicked_id <- as.integer(input$shape_clicked)
      selected_id(clicked_id)

      df <- placements()
      row <- df[df$PlacementID == clicked_id, ]

      if (nrow(row) > 0) {
        # Update popup content
        output$popup_silo <- renderText({ row$SiloCode })

        # Update dropdown
        updateSelectInput(session, "popup_shape_template", selected = row$ShapeTemplateID)

        # Show popup
        shinyjs::show("popup")
        shinyjs::show("backdrop")
      }
    }, ignoreInit = TRUE)

    # Close popup
    observeEvent(input$popup_close, {
      shinyjs::hide("popup")
      shinyjs::hide("backdrop")
      selected_id(NULL)
    })

    # Watch for shape template changes in popup
    observeEvent(input$popup_shape_template, {
      sid <- selected_id()
      if (is.null(sid)) return()

      template_id <- as.integer(input$popup_shape_template)
      template <- templates[template_id, ]

      df <- placements()
      row_idx <- which(df$PlacementID == sid)

      if (length(row_idx) > 0) {
        # Update data
        df$ShapeTemplateID[row_idx] <- template_id
        df$ShapeType[row_idx] <- template$ShapeType
        df$Radius[row_idx] <- ifelse(is.na(template$Radius), NA, template$Radius)
        df$Width[row_idx] <- ifelse(is.na(template$Width), NA, template$Width)
        df$Height[row_idx] <- ifelse(is.na(template$Height), NA, template$Height)

        placements(df)

        cat("[Canvas] Updated shape", sid, "to template", template_id, "(", template$ShapeType, ")\n")
      }
    }, ignoreInit = TRUE)
  })
}

# Standalone runner
run_canvas_minimal_test <- function() {
  library(shiny)

  ui <- fluidPage(
    title = "Minimal Canvas Test",
    test_canvas_minimal_ui("test")
  )

  server <- function(input, output, session) {
    test_canvas_minimal_server("test")
  }

  cat("\n=== Minimal Canvas Test ===\n")

  shiny::addResourcePath("js", "www/js")

  shinyApp(ui, server, options = list(launch.browser = TRUE))
}
