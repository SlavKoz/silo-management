# R/test_siloplacements_canvas.R
# Test file for SiloPlacements canvas + table browser

# UI - Canvas on top, React Table below
test_siloplacements_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),
    tags$style(HTML(sprintf("
      .canvas-container {
        border: 1px solid #ddd;
        border-radius: 4px;
        background: #f8f9fa;
        padding: 0.5rem;
      }
      .canvas-toolbar {
        display: flex;
        gap: 0.5rem;
        align-items: center;
        margin-bottom: 0.5rem;
        padding: 0.5rem;
        background: white;
        border-radius: 4px;
      }
      .canvas-toolbar .form-group {
        margin-bottom: 0;
        display: flex;
        align-items: center;
        gap: 0.3rem;
      }
      .canvas-toolbar select.form-control {
        padding: 0.15rem 0.5rem;
        height: 26px;
        font-size: 12px;
        line-height: 1.2;
        width: 180px;
      }
      .canvas-toolbar input[type='text'].form-control {
        padding: 0.15rem 0.5rem;
        height: 26px;
        font-size: 12px;
        line-height: 1.2;
      }
      .text-container-class {
        display: inline-flex;
        align-items: center;
        gap: 0.2rem;
      }
      .canvas-toolbar label {
        margin: 0;
        font-size: 13px;
        font-weight: normal;
      }
      .canvas-viewport {
        position: relative;
        background: white;
        border: 1px solid #ddd;
        border-radius: 4px;
        overflow: hidden;
      }
      #%s {
        display: block;
        width: 100%%;
        height: auto;
        cursor: crosshair;
      }
      .shape-label {
        position: absolute;
        font-size: 10px;
        color: #333;
        pointer-events: none;
        white-space: nowrap;
      }
      /* Ensure modal appears on top of canvas */
      .modal {
        z-index: 10000 !important;
      }
      .modal-backdrop {
        z-index: 9999 !important;
      }
    ", ns("canvas")))),

    div(
      # Canvas area
      div(class = "canvas-container",
          # Top toolbar - Layout selector only
          div(class = "canvas-toolbar", style = "background: #e9ecef; flex-wrap: wrap;",
              div(style = "display: flex; gap: 0.5rem; align-items: center; width: 100%; flex-wrap: wrap;",
                  div(style = "display: inline-flex; align-items: center; gap: 0.3rem;",
                      # Add New button
                      actionButton(ns("add_new_btn"), "Add New", class = "btn-sm btn-primary",
                                  style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;"),

                      # Layout label
                      tags$label("Layout:", style = "margin: 0; font-size: 13px; font-weight: normal;"),

                      # Select input (visible by default)
                      div(id = ns("select_container"), style = "display: inline-block;",
                          selectInput(ns("layout_id"), label = NULL, choices = NULL, width = "180px",
                                     selectize = FALSE)
                      ),

                      # Text input + Save button (hidden by default)
                      div(id = ns("text_container"), style = "display: none; inline-flex; gap: 0.2rem;",
                          textInput(ns("new_layout_name"), label = NULL, placeholder = "Enter name...",
                                   width = "130px"),
                          actionButton(ns("save_new_btn"), "Save", class = "btn-sm btn-success",
                                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 46px;")
                      ),

                      # JavaScript for Escape key handler
                      tags$script(HTML(paste0("
                        $(document).on('keydown', '#", ns("new_layout_name"), "', function(e) {
                          if (e.which === 27) { // Escape key
                            $('#", ns("text_container"), "').hide();
                            $('#", ns("select_container"), "').show();
                            $(this).val('');
                          }
                        });
                      ")))
                  )
              )
          ),

          # Canvas viewport
          div(class = "canvas-viewport",
              tags$canvas(id = ns("canvas"), width = 1400, height = 600),
              div(id = ns("labels"))
          )
      )
    )
  )
}

# Server
test_siloplacements_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    trigger_refresh <- reactiveVal(0)
    selected_placement_id <- reactiveVal(NULL)
    canvas_shapes <- reactiveVal(list())
    current_layout_id <- reactiveVal(1)  # Default to layout 1
    background_image <- reactiveVal(NULL)
    layouts_refresh <- reactiveVal(0)  # Trigger to refresh layouts list

    # ---- Load layouts ----
    layouts_data <- reactive({
      layouts_refresh()  # Depend on refresh trigger
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # Populate layout dropdown
    observe({
      layouts <- layouts_data()
      cat("[Canvas Test] Populating dropdown, layouts count:", nrow(layouts), "\n")

      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)
        cat("[Canvas Test] Choices:", paste(names(choices), "=", choices, collapse = ", "), "\n")

        # Use isolate to read current_layout_id without creating a dependency
        current_id <- isolate(current_layout_id())
        selected_val <- if (!is.null(current_id) && !is.na(current_id) &&
                           as.character(current_id) %in% choices) {
          as.character(current_id)
        } else {
          as.character(layouts$LayoutID[1])
        }
        cat("[Canvas Test] Updating dropdown, selected:", selected_val, "\n")

        updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)
      }
    })

    # Handle "Add New" button - toggle to text input mode
    observeEvent(input$add_new_btn, {
      cat("[Canvas Test] Switching to text input mode\n")
      shinyjs::hide("select_container")
      shinyjs::show("text_container")
      # Focus on text input
      shinyjs::runjs(paste0("$('#", session$ns("new_layout_name"), "').focus();"))
    })

    # Handle "Save" button - create layout and toggle back to select mode
    observeEvent(input$save_new_btn, {
      layout_name <- trimws(input$new_layout_name)
      cat("[Canvas Test] Creating layout:", shQuote(layout_name), "\n")

      if (layout_name == "") {
        showNotification("Please enter a layout name", type = "error")
        return()
      }

      tryCatch({
        new_layout_id <- create_canvas_layout(layout_name = layout_name)
        cat("[Canvas Test] Created layout", layout_name, "with ID", new_layout_id, "\n")

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
        cat("[Canvas Test] Error:", e$message, "\n")
      })
    })

    # Handle layout selection from dropdown
    observeEvent(input$layout_id, {
      selected_value <- input$layout_id
      cat("[Canvas Test] Selected:", selected_value, "\n")

      if (!is.null(selected_value) && selected_value != "") {
        current_layout_id(as.integer(selected_value))
      }
    }, ignoreInit = TRUE)

    # ---- Load canvases ----
    canvases_data <- reactive({
      df <- try(list_canvases(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # Populate canvas dropdown
    observe({
      canvases <- canvases_data()
      choices <- c("(None)" = "")
      if (nrow(canvases) > 0) {
        choices <- c(choices, setNames(canvases$id, canvases$canvas_name))
      }
      updateSelectInput(session, "canvas_id", choices = choices)
    })

    # ---- Load current layout settings ----
    current_layout <- reactive({
      layout_id <- current_layout_id()
      df <- try(get_layout_by_id(layout_id), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || nrow(df) == 0) {
        return(list(
          LayoutID = layout_id,
          CanvasID = NA,
          BackgroundRotation = 0,
          BackgroundPanX = 0,
          BackgroundPanY = 0,
          BackgroundZoom = 1,
          BackgroundScaleX = 1,
          BackgroundScaleY = 1
        ))
      }
      as.list(df[1, ])
    })

    # Update UI when layout changes
    observe({
      layout <- current_layout()

      # Update canvas selection
      canvas_id <- if (is.na(layout$CanvasID)) "" else as.character(layout$CanvasID)
      updateSelectInput(session, "canvas_id", selected = canvas_id)

      # Update background rotation control
      bg_rot <- f_or(layout$BackgroundRotation, 0)
      updateNumericInput(session, "bg_rotation", value = bg_rot)

      # Update background scale control (uniform - use ScaleX)
      bg_scale <- f_or(layout$BackgroundScaleX, 1)
      updateNumericInput(session, "bg_scale", value = bg_scale)

      # Update background offset controls
      bg_offset_x <- f_or(layout$BackgroundPanX, 0)
      bg_offset_y <- f_or(layout$BackgroundPanY, 0)
      updateNumericInput(session, "bg_offset_x", value = bg_offset_x)
      updateNumericInput(session, "bg_offset_y", value = bg_offset_y)

      # Send background settings to JavaScript
      session$sendCustomMessage(paste0(ns("root"), ":setRotation"), list(angle = bg_rot))
      session$sendCustomMessage(paste0(ns("root"), ":setBackgroundScale"), list(scale = bg_scale))
      session$sendCustomMessage(paste0(ns("root"), ":setBackgroundOffset"), list(x = bg_offset_x, y = bg_offset_y))
    })

    # ---- Load background image when canvas selected ----
    observe({
      canvas_id <- input$canvas_id
      if (is.null(canvas_id) || canvas_id == "") {
        background_image(NULL)
        session$sendCustomMessage(paste0(ns("root"), ":setBackground"), list(image = NULL))
        return()
      }

      df <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || nrow(df) == 0) {
        background_image(NULL)
        return()
      }

      # Send base64 image to JavaScript
      bg_data <- paste0("data:image/png;base64,", df$bg_png_b64[1])
      background_image(bg_data)
      session$sendCustomMessage(paste0(ns("root"), ":setBackground"), list(image = bg_data))
    })

    # ---- Load placements from DB (filtered by current layout) ----
    raw_placements <- reactive({
      trigger_refresh()
      layout_id <- current_layout_id()

      df <- try(list_placements(layout_id = layout_id, limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        return(data.frame())
      }
      df
    })

    # ---- Load related data (Silos, ShapeTemplates, ContainerTypes) ----
    silos_data <- reactive({
      df <- try(list_silos(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    shape_templates_data <- reactive({
      df <- try(list_shape_templates(limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    container_types_data <- reactive({
      df <- try(list_container_types(limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    # ---- Convert placements to canvas shapes ----
    observe({
      placements <- raw_placements()
      if (!nrow(placements)) {
        canvas_shapes(list())
        return()
      }

      silos <- silos_data()
      templates <- shape_templates_data()

      # Build shapes for canvas
      shapes <- lapply(seq_len(nrow(placements)), function(i) {
        p <- placements[i, ]

        # Find silo info
        silo <- silos[silos$SiloID == p$SiloID, ]
        silo_code <- if (nrow(silo) > 0) silo$SiloCode[1] else paste0("S", p$SiloID)

        # Find shape template
        template <- templates[templates$ShapeTemplateID == p$ShapeTemplateID, ]

        shape_type <- if (nrow(template) > 0) template$ShapeType[1] else "CIRCLE"

        # Build shape object
        if (shape_type == "CIRCLE") {
          radius <- if (nrow(template) > 0 && !is.na(template$Radius[1])) as.numeric(template$Radius[1]) else 20
          list(
            id = as.character(p$PlacementID),
            type = "circle",
            x = as.numeric(p$CenterX),
            y = as.numeric(p$CenterY),
            r = radius,
            label = silo_code,
            fill = "rgba(59, 130, 246, 0.2)",
            stroke = "rgba(59, 130, 246, 0.8)",
            strokeWidth = 2
          )
        } else {
          width <- if (nrow(template) > 0 && !is.na(template$Width[1])) as.numeric(template$Width[1]) else 40
          height <- if (nrow(template) > 0 && !is.na(template$Height[1])) as.numeric(template$Height[1]) else 40
          list(
            id = as.character(p$PlacementID),
            type = "rect",
            x = as.numeric(p$CenterX) - width / 2,
            y = as.numeric(p$CenterY) - height / 2,
            w = width,
            h = height,
            label = silo_code,
            fill = "rgba(34, 197, 94, 0.2)",
            stroke = "rgba(34, 197, 94, 0.8)",
            strokeWidth = 2
          )
        }
      })

      canvas_shapes(shapes)

      # Send to canvas with auto-fit
      session$sendCustomMessage(paste0(ns("root"), ":setData"), list(data = shapes, autoFit = TRUE))
    })

    # ---- Form schema for placement details ----
    schema_config <- reactive({
      # Build dropdown choices
      silo_choices <- c("(select silo)" = "")
      silos <- silos_data()
      if (nrow(silos) > 0) {
        silo_choices <- c(silo_choices, setNames(
          as.character(silos$SiloID),
          paste0(silos$SiloCode, " - ", silos$SiloName)
        ))
      }

      template_choices <- c("(select template)" = "")
      templates <- shape_templates_data()
      if (nrow(templates) > 0) {
        template_choices <- c(template_choices, setNames(
          as.character(templates$ShapeTemplateID),
          paste0(templates$TemplateCode, " (", templates$ShapeType, ")")
        ))
      }

      list(
        fields = list(
          field("SiloID", "select", title = "Silo", enum = silo_choices, required = TRUE),
          field("ShapeTemplateID", "select", title = "Shape Template", enum = template_choices, required = TRUE),
          field("LayoutID", "number", title = "Layout ID", required = TRUE, default = 1),
          field("CenterX", "number", title = "Center X"),
          field("CenterY", "number", title = "Center Y"),
          field("ZIndex", "number", title = "Z-Index"),
          field("IsVisible", "switch", title = "Visible", default = TRUE),
          field("IsInteractive", "switch", title = "Interactive", default = TRUE)
        ),
        columns = 1
      )
    })

    # ---- Form data based on selection ----
    form_data <- reactive({
      trigger_refresh()

      pid <- selected_placement_id()

      if (is.null(pid) || is.na(pid)) {
        # New placement
        return(list(
          SiloID = "",
          ShapeTemplateID = "",
          LayoutID = 1,
          CenterX = 100,
          CenterY = 100,
          ZIndex = 0,
          IsVisible = TRUE,
          IsInteractive = TRUE
        ))
      }

      # Existing placement - fetch from DB
      df <- try(get_placement_by_id(pid), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || !nrow(df)) {
        return(list())
      }

      list(
        PlacementID = as.integer(df$PlacementID),
        SiloID = as.character(df$SiloID),
        ShapeTemplateID = as.character(df$ShapeTemplateID),
        LayoutID = as.integer(df$LayoutID),
        CenterX = as.numeric(df$CenterX),
        CenterY = as.numeric(df$CenterY),
        ZIndex = as.integer(f_or(df$ZIndex, 0)),
        IsVisible = as.logical(f_or(df$IsVisible, TRUE)),
        IsInteractive = as.logical(f_or(df$IsInteractive, TRUE))
      )
    })

    # ---- HTML form module ----
    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = NULL,
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          saved_id <- upsert_placement(data)
          selected_placement_id(as.integer(saved_id))
          trigger_refresh(trigger_refresh() + 1)
          showNotification("Placement saved", type = "message", duration = 2)
          return(TRUE)
        }, error = function(e) {
          showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
          return(FALSE)
        })
      },
      on_delete = function() {
        pid <- selected_placement_id()
        if (is.null(pid) || is.na(pid)) return(FALSE)

        tryCatch({
          delete_placement(pid)
          selected_placement_id(NULL)
          trigger_refresh(trigger_refresh() + 1)
          showNotification("Placement deleted", type = "message", duration = 2)
          return(TRUE)
        }, error = function(e) {
          showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
          return(FALSE)
        })
      }
    )

    # ---- Toolbar button handlers ----
    observeEvent(input$add, {
      selected_placement_id(NA)  # Trigger new mode
    })

    observeEvent(input$duplicate, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to duplicate", type = "warning", duration = 2)
        return()
      }

      # Get current placement data
      df <- try(get_placement_by_id(pid), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      # Create duplicate with offset position
      new_data <- list(
        SiloID = df$SiloID,
        LayoutID = df$LayoutID,
        ShapeTemplateID = df$ShapeTemplateID,
        CenterX = as.numeric(df$CenterX) + 50,
        CenterY = as.numeric(df$CenterY) + 50,
        ZIndex = df$ZIndex,
        IsVisible = df$IsVisible,
        IsInteractive = df$IsInteractive
      )

      tryCatch({
        new_id <- upsert_placement(new_data)
        selected_placement_id(as.integer(new_id))
        trigger_refresh(trigger_refresh() + 1)
        showNotification("Placement duplicated", type = "message", duration = 2)
      }, error = function(e) {
        showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
      })
    })

    observeEvent(input$delete, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to delete", type = "warning", duration = 2)
        return()
      }

      # Trigger form module's delete
      form_module$trigger_delete()
    })

    # ---- Canvas interactions ----

    # Handle canvas selection (JavaScript sends with underscore: test_canvas_selection)
    observeEvent(input$test_canvas_selection, {
      sel_id <- input$test_canvas_selection
      if (!is.null(sel_id) && nzchar(sel_id)) {
        selected_placement_id(as.integer(sel_id))
      }
    }, ignoreInit = TRUE)

    # Handle canvas move (drag in edit mode)
    observeEvent(input$test_canvas_moved, {
      moved <- input$test_canvas_moved
      if (is.null(moved)) return()

      # Update placement position in DB
      tryCatch({
        df <- get_placement_by_id(as.integer(moved$id))
        if (nrow(df) > 0) {
          df$CenterX <- moved$x
          df$CenterY <- moved$y

          upsert_placement(as.list(df))
          # Don't refresh - just updated visually
        }
      }, error = function(e) {
        cat("Error updating position:", conditionMessage(e), "\n")
      })
    }, ignoreInit = TRUE)

    # Handle edit mode toggle
    observe({
      edit_on <- isTRUE(input$edit_mode)
      session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = edit_on))
    })

    # Handle snap grid changes
    observe({
      snap <- input$snap_grid
      if (!is.null(snap)) {
        session$sendCustomMessage(paste0(ns("root"), ":setSnap"), list(units = as.numeric(snap)))
      }
    })

    # Layout selection is handled by the observeEvent at line 187-221 (includes Add New functionality)

    # Handle background rotation
    observeEvent(input$bg_rotation, {
      if (!is.null(input$bg_rotation)) {
        session$sendCustomMessage(paste0(ns("root"), ":setRotation"), list(angle = as.numeric(input$bg_rotation)))
      }
    })

    # Handle background scale
    observeEvent(input$bg_scale, {
      if (!is.null(input$bg_scale)) {
        session$sendCustomMessage(paste0(ns("root"), ":setBackgroundScale"), list(scale = as.numeric(input$bg_scale)))
      }
    })

    observeEvent(input$bg_scale_up, {
      current <- f_or(input$bg_scale, 1)
      new_scale <- min(current + 0.1, 10)
      updateNumericInput(session, "bg_scale", value = round(new_scale, 1))
    })

    observeEvent(input$bg_scale_down, {
      current <- f_or(input$bg_scale, 1)
      new_scale <- max(current - 0.1, 0.1)
      updateNumericInput(session, "bg_scale", value = round(new_scale, 1))
    })

    # Handle background offset
    observeEvent(input$bg_offset_x, {
      if (!is.null(input$bg_offset_x) && !is.null(input$bg_offset_y)) {
        session$sendCustomMessage(paste0(ns("root"), ":setBackgroundOffset"),
                                 list(x = as.numeric(input$bg_offset_x), y = as.numeric(input$bg_offset_y)))
      }
    })

    observeEvent(input$bg_offset_y, {
      if (!is.null(input$bg_offset_x) && !is.null(input$bg_offset_y)) {
        session$sendCustomMessage(paste0(ns("root"), ":setBackgroundOffset"),
                                 list(x = as.numeric(input$bg_offset_x), y = as.numeric(input$bg_offset_y)))
      }
    })

    # Handle background pan mode
    observe({
      bg_pan <- isTRUE(input$bg_pan_mode)
      session$sendCustomMessage(paste0(ns("root"), ":setBackgroundPanMode"), list(on = bg_pan))
    })

    # Receive background offset updates from JavaScript (when dragging)
    observeEvent(input$test_bg_offset_update, {
      offset <- input$test_bg_offset_update
      if (!is.null(offset)) {
        updateNumericInput(session, "bg_offset_x", value = round(offset$x, 1))
        updateNumericInput(session, "bg_offset_y", value = round(offset$y, 1))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$rotate_cw_90, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- (current + 90) %% 360
      if (new_angle > 180) new_angle <- new_angle - 360
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })

    observeEvent(input$rotate_ccw_90, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- (current - 90) %% 360
      if (new_angle < -180) new_angle <- new_angle + 360
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })

    observeEvent(input$rotate_cw_15, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- current + 15
      if (new_angle > 180) new_angle <- -180 + (new_angle - 180)
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })

    observeEvent(input$rotate_ccw_15, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- current - 15
      if (new_angle < -180) new_angle <- 180 + (new_angle + 180)
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })

    # Save background settings to database
    observeEvent(input$save_bg_settings, {
      layout_id <- current_layout_id()
      canvas_id <- input$canvas_id
      rotation <- input$bg_rotation
      scale <- input$bg_scale
      offset_x <- input$bg_offset_x
      offset_y <- input$bg_offset_y

      result <- try(update_layout_background(
        layout_id = layout_id,
        canvas_id = if (canvas_id == "") NA else canvas_id,
        rotation = rotation,
        pan_x = offset_x,
        pan_y = offset_y,
        scale_x = scale,  # Uniform scaling
        scale_y = scale   # Same for both axes
      ), silent = TRUE)

      if (inherits(result, "try-error")) {
        showNotification("Error saving background settings", type = "error", duration = 3)
      } else {
        showNotification("Background settings saved", type = "message", duration = 2)
      }
    })

    # Handle zoom buttons
    observeEvent(input$zoom_in, {
      cat("[Canvas] Zoom in button clicked\n")
      session$sendCustomMessage(paste0(ns("root"), ":setZoom"), list(direction = "in"))
    })

    observeEvent(input$zoom_out, {
      cat("[Canvas] Zoom out button clicked\n")
      session$sendCustomMessage(paste0(ns("root"), ":setZoom"), list(direction = "out"))
    })

    # Handle fit view
    observeEvent(input$fit_view, {
      cat("[Canvas] Fit view button clicked\n")
      cat("[Canvas] Sending message:", paste0(ns("root"), ":fitView"), "\n")
      session$sendCustomMessage(paste0(ns("root"), ":fitView"), list())
    })

    # Initial load - trigger first refresh (run once only)
    observeEvent(session$clientData$url_hostname, once = TRUE, {
      trigger_refresh(trigger_refresh() + 1)
    })

  })
}

# Standalone runner
run_siloplacements_canvas_test <- function() {
  library(shiny)

  # Load DSL and queries
  if (!exists("compile_rjsf")) {
    cat("[Test] Loading modules...\n")
    source("R/utils/f_helper_core.R", local = TRUE)
    source("R/db/connect_wrappers.R", local = TRUE)
    source("R/db/queries.R", local = TRUE)
    source("R/react_table/react_table_dsl.R", local = TRUE)
    source("R/react_table/react_table_auto.R", local = TRUE)
    source("R/react_table/html_form_renderer.R", local = TRUE)
    source("R/react_table/mod_html_form.R", local = TRUE)
  }

  ui <- fluidPage(
    title = "SiloPlacements Canvas Test",
    tags$head(
      tags$script(src = paste0("js/f_siloplacements_canvas.js?v=", format(Sys.time(), "%Y%m%d%H%M%S")))
    ),
    tags$h3("SiloPlacements Canvas + Table Browser"),
    test_siloplacements_ui("test")
  )

  server <- function(input, output, session) {
    test_siloplacements_server("test")
  }

  cat("\n=== Launching SiloPlacements Canvas Test ===\n")
  cat("Canvas + React Table for placement management\n\n")

  # Add resource path for www directory
  shiny::addResourcePath("js", "www/js")

  shinyApp(ui, server, options = list(launch.browser = TRUE))
}
