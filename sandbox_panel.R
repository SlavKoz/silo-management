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
        display: inline-block; 
        /* display: flex;
        align-items: center;
        gap: 0.3rem;*/
      }
      .canvas-toolbar select.form-control {
        padding: 0.15rem 1.5rem 0.15rem 0.5rem;
        height: 28px;
        font-size: 12px;
        line-height: 1.2;
        background-position: right 0.3rem center;
        background-size: 12px;
      }
      .canvas-toolbar input[type='text'].form-control {
        padding: 0.15rem 0.5rem;
        height: 28px;
        font-size: 12px;
        line-height: 1.2;
      }
      .canvas-toolbar input[type='number'].form-control {
        padding: 0.15rem 0.5rem;
        height: 28px;
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
      .canvas-toolbar .btn-sm {
        height: 28px;
        padding: 0.25rem 0.4rem;
        font-size: 14px;
        line-height: 1.2;
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
      div(
        class = "canvas-container",
        
        # Grid-based toolbar for perfect alignment
        tags$style(HTML("
          .toolbar-grid {
            display: grid;
            grid-template-columns: 80px 90px 220px 110px 150px 1fr 100px;
            gap: 0.3rem;
            align-items: center;
            padding: 0.3rem;
            background: #e9ecef;
            border-radius: 4px;
          }
          .toolbar-grid-bottom {
            display: grid;
            grid-template-columns: 80px 90px 220px 110px 150px 1fr 1fr 100px;
            gap: 0.3rem;
            align-items: center;
            padding: 0.3rem;
            background: #e9ecef;
            border-radius: 4px;
          }
          .toolbar-grid-placement {
            display: grid;
            grid-template-columns: 80px 90px 220px auto;
            gap: 0.3rem;
            align-items: center;
            padding: 0.3rem;
            background: #e9ecef;
            border-radius: 4px;
          }
          .toolbar-grid .form-group,
          .toolbar-grid-bottom .form-group,
          .toolbar-grid-placement .form-group {
            margin-bottom: 0;
          }
          .toolbar-grid label,
          .toolbar-grid-bottom label,
          .toolbar-grid-placement label {
            text-align: right;
          }
          .toggle-btn {
            position: relative;
            padding-left: 2.5rem;
            border: 1px solid #ddd !important;
          }
          .toggle-btn::before {
            content: '';
            position: absolute;
            left: 0.3rem;
            top: 50%;
            transform: translateY(-50%);
            width: 1.8rem;
            height: 1rem;
            background: #ccc;
            border-radius: 0.5rem;
            transition: background 0.3s;
          }
          .toggle-btn::after {
            content: '';
            position: absolute;
            left: 0.4rem;
            top: 50%;
            transform: translateY(-50%);
            width: 0.8rem;
            height: 0.8rem;
            background: white;
            border-radius: 50%;
            transition: left 0.3s;
          }
          .toggle-btn.active {
            border-color: #28a745 !important;
          }
          .toggle-btn.active::before {
            background: #28a745;
          }
          .toggle-btn.active::after {
            left: 1.3rem;
          }
          .control-group {
            display: flex;
            gap: 0.2rem;
            align-items: center;
            justify-content: center;
          }
        ")),
        
        # Top toolbar - Layouts row
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
              selectInput(
                ns("layout_id"), label = NULL, choices = NULL, width = "100%",
                selectize = TRUE
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
          
          # Column 4: Save Layout button
          actionButton(ns("save_bg_settings"), "Save Layout", icon = icon("save"), class = "btn-sm btn-success",
                       style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),
          
          # Column 5: Backgrounds button
          actionButton(ns("toggle_bg_controls"), "Backgrounds", icon = icon("chevron-up"), class = "btn-sm btn-secondary",
                       style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),
          
          # Column 6: Empty spacer
          div(),
          
          # Column 7: Delete button (far right)
          actionButton(
            ns("delete_layout_btn"), "Delete", class = "btn-sm btn-danger",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          )
        ),
        
        # JavaScript for layout input toggle
        tags$script(HTML(sprintf("
          $(document).on('keyup', '#%s', function(e) {
            if (e.key === 'Enter') {
              e.preventDefault();
              $('#%s').click();
            }
          });
          $(document).on('keydown', '#%s', function(e) {
            if (e.which === 27) { // Escape key
              $('#%s').hide();
              $('#%s').show();
              $(this).val('');
            }
          });
        ", ns("new_layout_name"), ns("save_new_btn"),
                                 ns("new_layout_name"), ns("text_container"), ns("select_container")))),
        
        # Bottom toolbar - Backgrounds row (collapsible)
        div(
          id = ns("bg_controls"),
          class = "toolbar-grid-bottom",
          style = "margin-top: 0.3rem;",
          
          # Column 1: Add New Background button
          tags$a(
            href = "#/canvases",
            target = "_blank",
            actionButton(
              ns("add_new_bg_btn"), "Add New", class = "btn-sm btn-primary",
              style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;",
              onclick = "window.open('#/canvases', '_blank'); return false;"
            )
          ),
          
          # Column 2: Background label
          tags$label(
            "Background:",
            style = "margin: 0; font-size: 13px; font-weight: normal;"
          ),
          
          # Column 3: Background selector
          selectInput(ns("canvas_id"), label = NULL, choices = NULL, width = "100%", selectize = TRUE),
          
          # Column 4: Display BG toggle button
          actionButton(
            ns("display_bg_toggle"), "Display BG", class = "btn-sm toggle-btn active",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),
          
          # Column 5: Move BG toggle button
          actionButton(
            ns("move_bg_toggle"), "Move BG", class = "btn-sm toggle-btn",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),
          
          # Column 6: Rotation controls group
          div(
            class = "control-group",
            tags$label("Rotate:", style = "margin: 0; font-size: 13px; font-weight: normal;"),
            actionButton(ns("rotate_ccw_5"), "", icon = icon("rotate-left"), class = "btn-sm", title = "Rotate -5°",
                         style = "height: 26px; padding: 0.2rem 0.4rem;"),
            numericInput(ns("bg_rotation"), label = NULL, value = 0, min = -180, max = 180, step = 1, width = "65px"),
            actionButton(ns("rotate_cw_5"), "", icon = icon("rotate-right"), class = "btn-sm", title = "Rotate +5°",
                         style = "height: 26px; padding: 0.2rem 0.4rem;")
          ),
          
          # Column 7: Zoom controls group
          div(
            class = "control-group",
            tags$label("Zoom:", style = "margin: 0; font-size: 13px; font-weight: normal;"),
            actionButton(ns("bg_scale_down"), "", icon = icon("search-minus"), class = "btn-sm", title = "Shrink BG",
                         style = "height: 26px; padding: 0.2rem 0.4rem;"),
            numericInput(ns("bg_scale"), label = NULL, value = 1, min = 0.1, max = 10, step = 0.1, width = "65px"),
            actionButton(ns("bg_scale_up"), "", icon = icon("search-plus"), class = "btn-sm", title = "Enlarge BG",
                         style = "height: 26px; padding: 0.2rem 0.4rem;")
          ),
          
          # Column 8: Empty spacer (matches Delete button position)
          div()
        ),
        
        # JavaScript for collapsible controls and toggle button
        tags$script(HTML(sprintf("
          $(document).ready(function() {
            // Collapsible controls
            $('#%s').on('click', function() {
              var controls = $('#%s');
              var icon = $(this).find('i');
              if (controls.is(':visible')) {
                controls.slideUp();
                icon.removeClass('fa-chevron-up').addClass('fa-chevron-down');
              } else {
                controls.slideDown();
                icon.removeClass('fa-chevron-down').addClass('fa-chevron-up');
              }
            });
          });
        ", ns("toggle_bg_controls"), ns("bg_controls")))),
        
        # Main toolbar - Placement & View controls
        div(
          class = "toolbar-grid-placement",
          style = "margin-bottom: 0.5rem;",
          
          # Column 1: Edit toggle
          actionButton(
            ns("edit_mode_toggle"), "Edit", class = "btn-sm toggle-btn",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),
          
          # Column 2: New label
          tags$label(
            "New:",
            style = "margin: 0; font-size: 13px; font-weight: normal;"
          ),
          
          # Column 3: Shape template selector
          selectInput(ns("shape_template_id"), label = NULL, choices = NULL, width = "100%", selectize = TRUE),
          
          # Column 4: Rest of controls
          div(
            style = "display: flex; gap: 0.3rem; align-items: center;",
            actionButton(ns("duplicate"), "Duplicate", icon = icon("copy"), class = "btn-sm btn-secondary",
                         style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;"),
            actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-sm btn-danger",
                         style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;"),
            div(style = "flex: 1;"),
            tags$label("Grid Snap:", style = "margin: 0; font-size: 13px; font-weight: normal;"),
            numericInput(ns("snap_grid"), label = NULL, value = 0, min = 0, step = 10, width = "70px"),
            actionButton(ns("zoom_in"), "", icon = icon("magnifying-glass-plus"), class = "btn-sm",
                         style = "height: 26px; padding: 0.2rem 0.4rem;"),
            actionButton(ns("zoom_out"), "", icon = icon("magnifying-glass-minus"), class = "btn-sm",
                         style = "height: 26px; padding: 0.2rem 0.4rem;"),
            actionButton(ns("fit_view"), "Fit View", icon = icon("expand"), class = "btn-sm",
                         style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px;")
          )
        ),
        
        # Canvas viewport
        div(
          class = "canvas-viewport",
          tags$canvas(id = ns("canvas"), width = 1400, height = 600),
          div(id = ns("labels"))
        )
      ),
      
      # Table below - full width
      div(style = "margin-top: 1rem;",
          mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
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
    bg_offset <- reactiveVal(list(x = 0, y = 0))  # Track current background offset from pan mode
    bg_display_state <- reactiveVal(TRUE)  # Track background display toggle state
    bg_move_state <- reactiveVal(FALSE)  # Track background move toggle state
    edit_mode_state <- reactiveVal(FALSE)  # Track edit mode toggle state
    canvas_initialized <- reactiveVal(FALSE)  # Track if canvas has been initially fitted
    
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
    
    # Handle "Add New Layout" button - toggle to text input mode
    observeEvent(input$add_new_layout_btn, {
      cat("[Canvas Test] Switching to text input mode\n")
      shinyjs::hide("select_container")
      shinyjs::show("text_container")
      # Focus on text input
      shinyjs::runjs(paste0("$('#", session$ns("new_layout_name"), "').focus();"))
    })
    
    # Handle "Save" button - create layout and toggle back to select mode
    # Handle "Save" button - create layout and toggle back to select mode
    observeEvent(input$save_new_btn, {
      layout_name <- trimws(input$new_layout_name)
      cat("[Canvas Test] Creating layout:", shQuote(layout_name), "\n")
      
      if (layout_name == "") {
        showNotification("Please enter a layout name", type = "error")
        return()
      }
      
      # Optional: prevent creating duplicate layout names (case-insensitive)    # ADDED (if you wired this earlier)
      existing <- layouts_data()                                               # ADDED
      if (nrow(existing) > 0) {                                                # ADDED
        existing_names <- trimws(existing$LayoutName)                          # ADDED
        match_idx <- match(tolower(layout_name), tolower(existing_names))      # ADDED
        if (!is.na(match_idx)) {                                               # ADDED
          showNotification(                                                    # ADDED
            paste0("A layout called ", shQuote(layout_name), " already exists."),  # ADDED
            type = "error"                                                     # ADDED
          )                                                                    # ADDED
          return()                                                             # ADDED
        }                                                                      # ADDED
      }                                                                        # ADDED
      
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
        
        showNotification(
          paste("Layout", shQuote(layout_name), "created"),
          type = "message", duration = 3
        )
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
        cat("[Canvas Test] Error:", e$message, "\n")
      })
    })
    
    # Delete current layout                                                 # ADDED
    observeEvent(input$delete_layout_btn, {                                 # ADDED
      layout_id <- current_layout_id()                                      # ADDED
      
      if (is.null(layout_id) || is.na(layout_id) || layout_id == "") {      # ADDED
        showNotification("No layout selected to delete.", type = "warning") # ADDED
        return()                                                            # ADDED
      }                                                                     # ADDED
      
      # Basic safety: don't delete layouts that still have placements       # ADDED
      placements <- try(                                                    # ADDED
        list_placements(layout_id = layout_id, limit = 1),                  # ADDED
        silent = TRUE                                                       # ADDED
      )                                                                     # ADDED
      if (!inherits(placements, "try-error") &&                             # ADDED
          !is.null(placements) && nrow(placements) > 0) {                   # ADDED
        showNotification(                                                   # ADDED
          "This layout has silo placements and cannot be deleted in this test.",  # ADDED
          type = "error",                                                   # ADDED
          duration = NULL                                                   # ADDED
        )                                                                   # ADDED
        return()                                                            # ADDED
      }                                                                     # ADDED
      
      ok <- tryCatch({                                                      # ADDED
        delete_canvas_layout(layout_id)                                     # ADDED
        TRUE                                                                # ADDED
      }, error = function(e) {                                              # ADDED
        showNotification(                                                   # ADDED
          paste("Delete failed:", conditionMessage(e)),                     # ADDED
          type = "error"                                                    # ADDED
        )                                                                   # ADDED
        cat("[Canvas Test] Delete error:", conditionMessage(e), "\n")       # ADDED
        FALSE                                                               # ADDED
      })                                                                    # ADDED
      if (!ok) return()                                                     # ADDED
      
      showNotification("Layout deleted.", type = "message")                 # ADDED
      
      # Clear current layout and refresh dropdown                           # ADDED
      current_layout_id(NULL)                                               # ADDED
      layouts_refresh(layouts_refresh() + 1)                                # ADDED
      updateSelectInput(session, "layout_id", selected = "")                # ADDED
      
      # Make sure we are in select mode, not text mode                      # ADDED
      shinyjs::hide("text_container")                                       # ADDED
      shinyjs::show("select_container")                                     # ADDED
    })                                                                      # ADDED
    
    
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
      
      # Get background offset and update reactiveVal
      bg_offset_x <- f_or(layout$BackgroundPanX, 0)
      bg_offset_y <- f_or(layout$BackgroundPanY, 0)
      bg_offset(list(x = bg_offset_x, y = bg_offset_y))
      
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
      
      cat("[Canvas Test] Loading placements for layout:", layout_id, "\n")
      
      df <- try(list_placements(layout_id = layout_id, limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        cat("[Canvas Test] Error loading placements\n")
        return(data.frame())
      }
      
      cat("[Canvas Test] Loaded", nrow(df), "placements from DB\n")
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
    
    # Populate shape template dropdown
    observe({
      templates <- shape_templates_data()
      choices <- c("(select shape)" = "")
      if (nrow(templates) > 0) {
        choices <- c(choices, setNames(
          as.character(templates$ShapeTemplateID),
          paste0(templates$TemplateCode, " (", templates$ShapeType, ")")
        ))
      }
      updateSelectInput(session, "shape_template_id", choices = choices)
    })
    
    # Update cursor based on selected shape template
    observeEvent(input$shape_template_id, {
      template_id <- input$shape_template_id
      
      if (is.null(template_id) || template_id == "") {
        # No shape selected - default cursor, disable edit mode
        session$sendCustomMessage(paste0(ns("root"), ":setShapeCursor"), list(
          shapeType = "default"
        ))
        
        # Turn off edit mode
        if (edit_mode_state()) {
          edit_mode_state(FALSE)
          shinyjs::removeClass("edit_mode_toggle", "active")
          session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = FALSE))
        }
        return()
      }
      
      # Find the template
      templates <- shape_templates_data()
      template <- templates[templates$ShapeTemplateID == as.integer(template_id), ]
      
      if (nrow(template) > 0) {
        shape_type <- template$ShapeType[1]
        
        # Build shape data with dimensions
        shape_data <- list(
          shapeType = shape_type,
          templateId = as.integer(template_id)
        )
        
        if (shape_type == "CIRCLE") {
          shape_data$radius <- as.numeric(f_or(template$Radius[1], 20))
        } else if (shape_type == "RECTANGLE") {
          shape_data$width <- as.numeric(f_or(template$Width[1], 40))
          shape_data$height <- as.numeric(f_or(template$Height[1], 40))
        } else if (shape_type == "TRIANGLE") {
          shape_data$radius <- as.numeric(f_or(template$Radius[1], 20))
        }
        
        session$sendCustomMessage(paste0(ns("root"), ":setShapeCursor"), shape_data)
        
        # Auto-enable edit mode when shape selected
        if (!edit_mode_state()) {
          edit_mode_state(TRUE)
          shinyjs::addClass("edit_mode_toggle", "active")
          session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
        }
      }
    }, ignoreInit = TRUE)
    
    # ---- Convert placements to canvas shapes ----
    observe({
      placements <- raw_placements()
      cat("[Canvas Test] Converting placements to shapes, count:", nrow(placements), "\n")
      
      if (!nrow(placements)) {
        canvas_shapes(list())
        session$sendCustomMessage(paste0(ns("root"), ":setData"), list(data = list(), autoFit = FALSE))
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
      
      cat("[Canvas Test] Sending", length(shapes), "shapes to canvas\n")
      
      # Only autofit on initial load, not on updates
      should_autofit <- !canvas_initialized()
      if (should_autofit) {
        canvas_initialized(TRUE)
        cat("[Canvas Test] Initial load - will autofit\n")
      }
      
      session$sendCustomMessage(paste0(ns("root"), ":setData"), list(data = shapes, autoFit = should_autofit))
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
    
    # Handle canvas click to add placement (namespace is auto-applied, so listen for canvas_add_at not test_canvas_add_at)
    observeEvent(input$canvas_add_at, {
      cat("[Canvas Test] *** observeEvent FIRED for canvas_add_at ***\n")
      
      click_data <- input$canvas_add_at
      cat("[Canvas Test] Received click_data:", !is.null(click_data), "\n")
      
      if (is.null(click_data)) {
        cat("[Canvas Test] click_data is NULL, returning\n")
        return()
      }
      
      cat("[Canvas Test] Adding placement at:", click_data$x, click_data$y, "template:", click_data$templateId, "\n")
      
      # Get current layout
      layout_id <- current_layout_id()
      if (is.null(layout_id) || is.na(layout_id)) {
        showNotification("No layout selected", type = "error")
        return()
      }
      
      # TODO: Open silo selector or use default
      # For now, we'll need to prompt the user to select a silo
      # Create placement with dummy silo (will be updated via form)
      new_placement <- list(
        SiloID = 1,  # Default - user will select via form
        LayoutID = layout_id,
        ShapeTemplateID = as.integer(click_data$templateId),
        CenterX = as.numeric(click_data$x),
        CenterY = as.numeric(click_data$y),
        ZIndex = 0,
        IsVisible = TRUE,
        IsInteractive = TRUE
      )
      
      tryCatch({
        new_id <- upsert_placement(new_placement)
        cat("[Canvas Test] Placement created with ID:", new_id, "\n")
        
        selected_placement_id(as.integer(new_id))
        
        # Force refresh to show new placement on canvas
        old_refresh <- trigger_refresh()
        trigger_refresh(old_refresh + 1)
        cat("[Canvas Test] Triggered refresh from", old_refresh, "to", old_refresh + 1, "\n")
        
        # Deselect shape template to revert cursor and prevent duplicate clicks
        updateSelectInput(session, "shape_template_id", selected = "")
        cat("[Canvas Test] Shape template deselected\n")
        
        showNotification("Placement added - select silo in form", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error adding placement:", conditionMessage(e)), type = "error")
        cat("[Canvas Test] Error:", conditionMessage(e), "\n")
      })
    }, ignoreInit = TRUE)
    
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
    
    # Handle canvas selection (namespace auto-applied: listen for canvas_selection not test_canvas_selection)
    observeEvent(input$canvas_selection, {
      sel_id <- input$canvas_selection
      if (!is.null(sel_id) && nzchar(sel_id)) {
        selected_placement_id(as.integer(sel_id))
      }
    }, ignoreInit = TRUE)
    
    # Handle canvas move (drag in edit mode)
    observeEvent(input$canvas_moved, {
      moved <- input$canvas_moved
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
    
    # Handle edit mode toggle button
    observeEvent(input$edit_mode_toggle, {
      # Toggle state
      new_state <- !edit_mode_state()
      edit_mode_state(new_state)
      
      # Update button class
      if (new_state) {
        shinyjs::addClass("edit_mode_toggle", "active")
      } else {
        shinyjs::removeClass("edit_mode_toggle", "active")
      }
      
      # Send to JavaScript
      session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = new_state))
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
    
    # Handle background display toggle button
    observeEvent(input$display_bg_toggle, {
      # Toggle state
      new_state <- !bg_display_state()
      bg_display_state(new_state)
      
      # Update button class
      if (new_state) {
        shinyjs::addClass("display_bg_toggle", "active")
      } else {
        shinyjs::removeClass("display_bg_toggle", "active")
      }
      
      # Send to JavaScript
      session$sendCustomMessage(paste0(ns("root"), ":setBackgroundVisible"), list(visible = new_state))
    })
    
    # Handle background move toggle button
    observeEvent(input$move_bg_toggle, {
      # Toggle state
      new_state <- !bg_move_state()
      bg_move_state(new_state)
      
      # Update button class
      if (new_state) {
        shinyjs::addClass("move_bg_toggle", "active")
      } else {
        shinyjs::removeClass("move_bg_toggle", "active")
      }
      
      # Send to JavaScript
      session$sendCustomMessage(paste0(ns("root"), ":setBackgroundPanMode"), list(on = new_state))
    })
    
    # Receive background offset updates from JavaScript (when dragging in pan mode)
    observeEvent(input$bg_offset_update, {
      offset <- input$bg_offset_update
      if (!is.null(offset)) {
        bg_offset(list(x = offset$x, y = offset$y))
      }
    }, ignoreInit = TRUE)
    
    observeEvent(input$rotate_cw_5, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- current + 5
      if (new_angle > 180) new_angle <- -180 + (new_angle - 180)
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })
    
    observeEvent(input$rotate_ccw_5, {
      current <- f_or(input$bg_rotation, 0)
      new_angle <- current - 5
      if (new_angle < -180) new_angle <- 180 + (new_angle + 180)
      updateNumericInput(session, "bg_rotation", value = new_angle)
    })
    
    # Save layout settings to database (including background)
    observeEvent(input$save_bg_settings, {
      layout_id <- current_layout_id()
      canvas_id <- input$canvas_id
      rotation <- input$bg_rotation
      scale <- input$bg_scale
      
      # Get current offset from reactiveVal (tracked via pan mode)
      offset <- bg_offset()
      
      result <- try(update_layout_background(
        layout_id = layout_id,
        canvas_id = if (canvas_id == "") NA else canvas_id,
        rotation = rotation,
        pan_x = offset$x,
        pan_y = offset$y,
        scale_x = scale,  # Uniform scaling
        scale_y = scale   # Same for both axes
      ), silent = TRUE)
      
      if (inherits(result, "try-error")) {
        showNotification("Error saving layout settings", type = "error", duration = 3)
      } else {
        showNotification("Layout settings saved", type = "message", duration = 2)
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