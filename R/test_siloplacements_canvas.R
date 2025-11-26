# R/test_siloplacements_canvas.R
# Test file for SiloPlacements canvas + table browser

# UI - Canvas on top, React Table below
test_siloplacements_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),
    tags$style(HTML(sprintf("
      body {
        overflow: hidden !important;
      }

      .main-content {
        margin-left: 0 !important;
        transition: margin-left 0.5s ease;
      }

      .main-content.panel-open {
        margin-left: 400px;
      }

      .sliding-panel {
        position: fixed;
        top: 0;
        left: -400px;
        width: 400px;
        height: 100vh;
        background: white;
        box-shadow: 2px 0 8px rgba(0,0,0,0.15);
        transition: left 0.5s ease;
        z-index: 1000;
        overflow-y: auto;
      }

      .sliding-panel.open {
        left: 0;
      }

      .panel-toggle {
        position: fixed;
        top: 50%%;
        left: 0;
        transform: translateY(-50%%);
        width: 30px;
        height: 80px;
        background: #2185d0;
        color: white;
        border: none;
        border-radius: 0 4px 4px 0;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 999;
        transition: left 0.5s ease;
        font-size: 18px;
      }

      .panel-toggle.panel-open {
        left: 400px;
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

    # Main content (shifts left when panel opens)
    div(class = "main-content", id = ns("main-content"),
      # Canvas area
      div(
        class = "canvas-container",

        # Grid-based toolbar for perfect alignment
        tags$style(HTML("
          .toolbar-grid {
            display: grid;
            grid-template-columns: 80px 90px 220px 50px 180px 110px 150px 1fr 100px;
            gap: 0.3rem;
            align-items: center;
            padding: 0.3rem;
            background: #e9ecef;
            border-radius: 4px;
          }
          .toolbar-grid-bottom {
            display: grid;
            grid-template-columns: 80px 90px 220px 50px 180px 110px 150px auto 80px auto 1fr 80px auto 1fr 100px;
            gap: 0.3rem;
            align-items: center;
            padding: 0.3rem;
            background: #e9ecef;
            border-radius: 4px;
          }
          .toolbar-grid-placement {
            display: grid;
            grid-template-columns: 80px 90px 220px 50px 180px 110px 150px auto 80px auto 1fr 80px auto 1fr 100px;
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

          # Column 4: Site label
          tags$label(
            "Site:",
            style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right;"
          ),

          # Column 5: Site selector
          selectInput(
            ns("layout_site_id"), label = NULL, choices = NULL, width = "100%",
            selectize = TRUE
          ),

          # Column 6: Save Layout button
          actionButton(ns("save_bg_settings"), "Save Layout", icon = icon("save"), class = "btn-sm btn-success",
                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),

          # Column 7: Backgrounds button
          actionButton(ns("toggle_bg_controls"), "Backgrounds", icon = icon("chevron-up"), class = "btn-sm btn-secondary",
                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),

          # Column 8: Empty spacer
          div(),

          # Column 9: Delete button (far right)
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

          # Column 4: Area label
          tags$label(
            "Area:",
            style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right;"
          ),

          # Column 5: Area selector
          selectInput(
            ns("bg_area_id"), label = NULL, choices = NULL, width = "100%",
            selectize = TRUE
          ),

          # Column 6: Display BG toggle button
          actionButton(
            ns("display_bg_toggle"), "Display BG", class = "btn-sm toggle-btn active",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),

          # Column 7: Move BG toggle button
          actionButton(
            ns("move_bg_toggle"), "Move BG", class = "btn-sm toggle-btn",
            style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"
          ),

          # Column 8: Empty
          div(),

          # Column 9: Rotate label (right-aligned)
          tags$label("Rotate:", style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right; width: 100%;"),

          # Column 10: Rotate controls (centered)
          div(
            style = "display: flex; align-items: center; justify-content: center; gap: 0.3rem;",
            actionButton(ns("rotate_ccw_5"), "", icon = icon("rotate-left"), class = "btn-sm", title = "Rotate -5°",
                        style = "height: 26px; width: 26px; padding: 0; display: flex; align-items: center; justify-content: center;"),
            numericInput(ns("bg_rotation"), label = NULL, value = 0, min = -180, max = 180, step = 1, width = "32px"),
            actionButton(ns("rotate_cw_5"), "", icon = icon("rotate-right"), class = "btn-sm", title = "Rotate +5°",
                        style = "height: 26px; width: 26px; padding: 0; display: flex; align-items: center; justify-content: center;")
          ),

          # Column 11: Space
          div(),

          # Column 12: BG Size label (right-aligned)
          tags$label("BG Size:", style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right; width: 100%;"),

          # Column 13: BG Size controls (centered)
          div(
            style = "display: flex; align-items: center; justify-content: center; gap: 0.3rem;",
            actionButton(ns("bg_scale_down"), "-", class = "btn-sm", title = "Shrink BG",
                        style = "height: 26px; width: 26px; padding: 0;"),
            numericInput(ns("bg_scale"), label = NULL, value = 1, min = 0.1, max = 10, step = 0.1, width = "32px"),
            actionButton(ns("bg_scale_up"), "+", class = "btn-sm", title = "Enlarge BG",
                        style = "height: 26px; width: 26px; padding: 0;")
          ),

          # Column 14: Space
          div(),

          # Column 15: Empty spacer
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

          # Column 4: Empty spacer (aligns with Area: label above)
          div(),

          # Column 5: Move and Duplicate buttons (180px split 50/50)
          div(
            style = "display: flex; gap: 0.3rem; align-items: center;",
            actionButton(ns("move"), "Move", icon = icon("arrows-alt"), class = "btn-sm btn-info",
                        style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),
            actionButton(ns("duplicate"), "Duplicate", icon = icon("copy"), class = "btn-sm btn-secondary",
                        style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;")
          ),

          # Column 6: Fit View button (110px - matches Display BG above)
          actionButton(ns("fit_view"), "Fit View", icon = icon("expand"), class = "btn-sm btn-secondary",
                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;"),

          # Column 7: Empty (skip Move BG position)
          div(),

          # Column 8: Empty
          div(),

          # Column 9: Grid Snap label (right-aligned)
          tags$label("Grid Snap:", style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right; width: 100%;"),

          # Column 10: Grid Snap controls (centered)
          div(
            style = "display: flex; align-items: center; justify-content: center; gap: 0.3rem;",
            actionButton(ns("snap_down"), "-", class = "btn-sm", title = "Decrease Snap",
                        style = "height: 26px; width: 26px; padding: 0;"),
            numericInput(ns("snap_grid"), label = NULL, value = 0, min = 0, step = 10, width = "32px"),
            actionButton(ns("snap_up"), "+", class = "btn-sm", title = "Increase Snap",
                        style = "height: 26px; width: 26px; padding: 0;")
          ),

          # Column 11: Space
          div(),

          # Column 12: Zoom label (right-aligned)
          tags$label("Zoom:", style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right; width: 100%;"),

          # Column 13: Zoom controls with input (centered)
          div(
            style = "display: flex; align-items: center; justify-content: center; gap: 0.3rem;",
            actionButton(ns("zoom_out"), "", icon = icon("magnifying-glass-minus"), class = "btn-sm",
                        style = "height: 26px; width: 26px; padding: 0; display: flex; align-items: center; justify-content: center;"),
            numericInput(ns("zoom_level"), label = NULL, value = 100, min = 10, max = 500, step = 10, width = "32px"),
            actionButton(ns("zoom_in"), "", icon = icon("magnifying-glass-plus"), class = "btn-sm",
                        style = "height: 26px; width: 26px; padding: 0; display: flex; align-items: center; justify-content: center;")
          ),

          # Column 14: Space
          div(),

          # Column 15: Delete button (100px)
          actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-sm btn-danger",
                      style = "height: 26px; padding: 0.1rem 0.5rem; font-size: 12px; width: 100%;")
        ),

        # Warning banner (hidden by default, shown when no silos available)
        uiOutput(ns("no_silo_warning")),

        # Move operation bar (hidden by default, shown when moving an object)
        uiOutput(ns("move_operation_bar")),

        # Canvas viewport
        div(
          class = "canvas-viewport",
          tags$canvas(id = ns("canvas"), width = 1400, height = 600),
          div(id = ns("labels"))
        )
      )
    ),

    # Panel toggle arrow (on left side)
    tags$button(id = ns("panel_toggle"), class = "panel-toggle",
      tags$i(class = "fas fa-chevron-right")
    ),

    # Sliding panel (slides in from right)
    div(id = ns("sliding_panel"), class = "sliding-panel",
      div(class = "panel-header",
        uiOutput(ns("panel_header_ui")),
        actionButton(ns("close_panel_btn"), "", icon = icon("times"),
                     class = "ui icon button", style = "margin: 0;")
      ),
      div(class = "panel-content",
        uiOutput(ns("panel_content_ui"))
      )
    ),

    # JavaScript for panel toggle
    tags$script(HTML(sprintf("
      $(document).ready(function() {
        // Toggle panel function
        function togglePanel_%s(open) {
          if (open) {
            $('#%s').addClass('open');
            $('#%s').addClass('panel-open');
            $('#%s').addClass('panel-open');
            $('#%s i').removeClass('fa-chevron-right').addClass('fa-chevron-left');
          } else {
            $('#%s').removeClass('open');
            $('#%s').removeClass('panel-open');
            $('#%s').removeClass('panel-open');
            $('#%s i').removeClass('fa-chevron-left').addClass('fa-chevron-right');

            // Clear temp shape when closing panel
            if (Shiny && Shiny.setInputValue) {
              Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
            }
          }
        }

        // Close panel button
        $('#%s').on('click', function() {
          togglePanel_%s(false);
        });

        // Panel toggle arrow
        $('#%s').on('click', function() {
          var isOpen = $('#%s').hasClass('open');
          togglePanel_%s(!isOpen);
        });

        // ESC key to close
        $(document).on('keydown', function(e) {
          if (e.key === 'Escape' && $('#%s').hasClass('open')) {
            togglePanel_%s(false);
          }
        });

        // Expose toggle function globally for R to call
        window.togglePanel_%s = togglePanel_%s;
      });
    ",
      gsub("-", "_", ns("root")),
      ns("sliding_panel"), ns("main-content"), ns("panel_toggle"), ns("panel_toggle"),
      ns("sliding_panel"), ns("main-content"), ns("panel_toggle"), ns("panel_toggle"),
      ns("panel_closed"),
      ns("close_panel_btn"), gsub("-", "_", ns("root")),
      ns("panel_toggle"), ns("sliding_panel"), gsub("-", "_", ns("root")),
      ns("sliding_panel"), gsub("-", "_", ns("root")),
      gsub("-", "_", ns("root")), gsub("-", "_", ns("root"))
    )))
  )
}

# Server
test_siloplacements_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    trigger_refresh <- reactiveVal(0)
    selected_placement_id <- reactiveVal(NULL)
    pending_placement <- reactiveVal(NULL)  # Store pending placement data before DB insert
    canvas_shapes <- reactiveVal(list())
    current_layout_id <- reactiveVal(1)  # Default to layout 1
    background_image <- reactiveVal(NULL)
    layouts_refresh <- reactiveVal(0)  # Trigger to refresh layouts list
    bg_offset <- reactiveVal(list(x = 0, y = 0))  # Track current background offset from pan mode
    bg_display_state <- reactiveVal(TRUE)  # Track background display toggle state
    bg_move_state <- reactiveVal(FALSE)  # Track background move toggle state
    edit_mode_state <- reactiveVal(FALSE)  # Track edit mode toggle state
    canvas_initialized <- reactiveVal(FALSE)  # Track if canvas has been initially fitted
    panel_mode <- reactiveVal("placement")  # Track panel mode: "placement" or "silo"
    silos_refresh <- reactiveVal(0)  # Trigger to refresh silos list after creating new silo
    canvases_refresh <- reactiveVal(0)  # Trigger to refresh canvases list after updating area
    show_silo_warning <- reactiveVal(FALSE)  # Track whether to show "no silos" warning
    initial_load_complete <- reactiveVal(FALSE)  # Track whether initial layout load is complete
    move_mode_state <- reactiveVal(FALSE)  # Track whether move mode is active
    move_original_position <- reactiveVal(NULL)  # Store original position before moving (list with x, y, id)
    move_current_position <- reactiveVal(NULL)  # Track current position during move (list with x, y)

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

      if (nrow(layouts) > 0) {
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)

        # Use isolate to read current_layout_id without creating a dependency
        current_id <- isolate(current_layout_id())
        selected_val <- if (!is.null(current_id) && !is.na(current_id) &&
                           as.character(current_id) %in% choices) {
          as.character(current_id)
        } else {
          as.character(layouts$LayoutID[1])
        }

        updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)
      }
    })

    # Handle "Add New Layout" button - toggle to text input mode
    observeEvent(input$add_new_layout_btn, {
      shinyjs::hide("select_container")
      shinyjs::show("text_container")
      # Focus on text input
      shinyjs::runjs(paste0("$('#", session$ns("new_layout_name"), "').focus();"))
    })

    # Handle "Save" button - create layout and toggle back to select mode
    # Handle "Save" button - create layout and toggle back to select mode
    observeEvent(input$save_new_btn, {
      layout_name <- trimws(input$new_layout_name)

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

      if (!is.null(selected_value) && selected_value != "") {
        current_layout_id(as.integer(selected_value))
        # Reset initial load flag so new layout's area is populated
        initial_load_complete(FALSE)
        cat("[Layout Change] Reset initial_load_complete flag\n")
      }
    }, ignoreInit = TRUE)

    # Handle site selection - update layout in database
    # Note: Placements/silos/areas will auto-refresh via reactive dependencies on input$layout_site_id
    observeEvent(input$layout_site_id, {
      layout_id <- current_layout_id()
      if (is.null(layout_id) || is.na(layout_id)) return()

      site_id <- input$layout_site_id
      site_id_value <- if (is.null(site_id) || site_id == "") NA else as.integer(site_id)

      # Update layout's site in database
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
        # No need to trigger_refresh - reactives depend on input$layout_site_id directly
      }, error = function(e) {
        showNotification(paste("Error updating site:", conditionMessage(e)),
                        type = "error", duration = NULL)
      })
    }, ignoreInit = TRUE)

    # ---- Load canvases ----
    canvases_data <- reactive({
      canvases_refresh()  # Depend on refresh trigger
      df <- try(list_canvases(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # Populate canvas dropdown
    observe({
      canvases <- canvases_data()

      # Preserve current selection
      current_canvas_id <- input$canvas_id

      choices <- c("(None)" = "")
      if (nrow(canvases) > 0) {
        # Show only canvas names (area is in separate dropdown)
        choices <- c(choices, setNames(canvases$id, canvases$canvas_name))
      }

      # Update choices and restore selection
      updateSelectInput(session, "canvas_id", choices = choices, selected = current_canvas_id)
    })

    # Populate sites dropdown
    observe({
      sites <- sites_data()
      choices <- c("(None)" = "")
      if (nrow(sites) > 0) {
        choices <- c(choices, setNames(sites$SiteID, paste0(sites$SiteCode, " - ", sites$SiteName)))
      }
      updateSelectInput(session, "layout_site_id", choices = choices)
    })

    # Populate areas dropdown for background selector
    observe({
      areas <- areas_data()
      choices <- c()
      if (nrow(areas) > 0) {
        # Show all areas including "ALL" areas from database
        # Put "ALL" areas first for convenience
        all_areas <- areas[areas$AreaCode == "ALL", ]
        other_areas <- areas[areas$AreaCode != "ALL", ]

        if (nrow(all_areas) > 0) {
          choices <- c(choices, setNames(all_areas$AreaID, paste0(all_areas$AreaCode, " - ", all_areas$AreaName)))
        }
        if (nrow(other_areas) > 0) {
          choices <- c(choices, setNames(other_areas$AreaID, paste0(other_areas$AreaCode, " - ", other_areas$AreaName)))
        }
      }
      updateSelectInput(session, "bg_area_id", choices = choices)
    })

    # Save canvas area when changed
    observeEvent(input$bg_area_id, {
      canvas_id <- input$canvas_id
      if (is.null(canvas_id) || canvas_id == "") return()

      area_id <- input$bg_area_id

      # Update canvas area in database
      tryCatch({
        update_canvas_area(as.integer(canvas_id), area_id)
        canvases_refresh(canvases_refresh() + 1)  # Trigger canvas list refresh
        showNotification("Canvas area updated", type = "message", duration = 2)
      }, error = function(e) {
        showNotification(paste("Error updating canvas area:", conditionMessage(e)),
                        type = "error", duration = NULL)
      })
    }, ignoreInit = TRUE)

    # ---- Load current layout settings ----
    current_layout <- reactive({
      layout_id <- current_layout_id()
      df <- try(get_layout_by_id(layout_id), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || nrow(df) == 0) {
        return(list(
          LayoutID = layout_id,
          CanvasID = NA,
          SiteID = NA,
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
    # Priority = -1 to ensure dropdown choices are populated first (default priority = 0)
    observe(priority = -1, {
      layout <- current_layout()

      # Update canvas selection
      canvas_id <- if (is.null(layout$CanvasID) || is.na(layout$CanvasID)) "" else as.character(layout$CanvasID)
      cat("[Layout Update] Setting canvas_id to:", canvas_id, "\n")
      updateSelectInput(session, "canvas_id", selected = canvas_id)

      # Update site selection
      site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) "" else as.character(layout$SiteID)
      cat("[Layout Update] Setting site_id to:", site_id, "\n")
      updateSelectInput(session, "layout_site_id", selected = site_id)

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

      # Mark initial load as complete after a short delay (to ensure area is populated)
      if (!initial_load_complete()) {
        shiny::invalidateLater(100)
        initial_load_complete(TRUE)
        cat("[Layout Update] Initial load complete\n")
      }
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

      # Only update area selector during initial load (not when user manually changes background)
      if (!initial_load_complete()) {
        area_id <- if (is.null(df$AreaID) || is.na(df$AreaID[1])) "" else as.character(df$AreaID[1])
        cat("[Canvas Load] Initial load - setting area to:", area_id, "\n")
        updateSelectInput(session, "bg_area_id", selected = area_id)
      } else {
        cat("[Canvas Load] User action - keeping current area selection\n")
      }

      # Send base64 image to JavaScript
      bg_data <- paste0("data:image/png;base64,", df$bg_png_b64[1])
      background_image(bg_data)
      session$sendCustomMessage(paste0(ns("root"), ":setBackground"), list(image = bg_data))
    })

    # ---- Load placements from DB (filtered by current layout, site, and area) ----
    raw_placements <- reactive({
      trigger_refresh()
      layout_id <- current_layout_id()

      # Get site_id directly from input selector (not from database)
      # This ensures immediate filtering when site selector changes
      site_id <- input$layout_site_id
      site_id <- if (is.null(site_id) || site_id == "") NULL else as.integer(site_id)

      # Get area_id from currently selected canvas
      # If area has AreaCode = "ALL", pass NULL to show all silos for site
      # Read input$bg_area_id to create reactive dependency on area selector changes
      area_selector_value <- input$bg_area_id

      area_id_to_filter <- NULL
      canvas_id <- input$canvas_id
      area_code <- NA
      canvas_area_id <- NA
      if (!is.null(canvas_id) && canvas_id != "") {
        canvas_df <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
        if (!inherits(canvas_df, "try-error") && !is.null(canvas_df) && nrow(canvas_df) > 0) {
          area_code <- canvas_df$AreaCode[1]
          canvas_area_id <- canvas_df$AreaID[1]
          # Only filter by area if it's NOT an "ALL" area type
          if (!is.null(canvas_area_id) && !is.na(canvas_area_id) &&
              !is.null(area_code) && !is.na(area_code) && area_code != "ALL") {
            area_id_to_filter <- canvas_area_id
          }
        }
      }

      df <- try(list_placements(layout_id = layout_id, site_id = site_id, area_id = area_id_to_filter, limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        return(data.frame())
      }

      df
    })

    # ---- Load related data (Silos, ShapeTemplates, ContainerTypes) ----
    silos_data <- reactive({
      silos_refresh()  # Depend on refresh trigger

      # Get site_id directly from input selector (not from database)
      # This ensures immediate filtering when site selector changes
      site_id <- input$layout_site_id
      site_id <- if (is.null(site_id) || site_id == "") NULL else as.integer(site_id)

      # Get area_id from currently selected canvas
      # If area has AreaCode = "ALL", pass NULL to show all silos for site
      # Read input$bg_area_id to create reactive dependency on area selector changes
      area_selector_value <- input$bg_area_id

      area_id_to_filter <- NULL
      canvas_id <- input$canvas_id
      area_code <- NA
      canvas_area_id <- NA
      if (!is.null(canvas_id) && canvas_id != "") {
        canvas_df <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
        if (!inherits(canvas_df, "try-error") && !is.null(canvas_df) && nrow(canvas_df) > 0) {
          area_code <- canvas_df$AreaCode[1]
          canvas_area_id <- canvas_df$AreaID[1]
          # Only filter by area if it's NOT an "ALL" area type
          if (!is.null(canvas_area_id) && !is.na(canvas_area_id) &&
              !is.null(area_code) && !is.na(area_code) && area_code != "ALL") {
            area_id_to_filter <- canvas_area_id
          }
        }
      }

      df <- try(list_silos(site_id = site_id, area_id = area_id_to_filter, limit = 1000), silent = TRUE)
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

    sites_data <- reactive({
      df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    areas_data <- reactive({
      # Get site_id directly from input selector (not from database)
      # This ensures immediate filtering when site selector changes
      site_id <- input$layout_site_id
      site_id <- if (is.null(site_id) || site_id == "") NULL else as.integer(site_id)

      df <- try(list_areas(site_id = site_id, limit = 1000), silent = TRUE)
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
      cat("[Cursor] shape_template_id changed to:", template_id, "\n")

      if (is.null(template_id) || template_id == "") {
        # No shape selected - default cursor, disable edit mode
        cat("[Cursor] Clearing cursor to default (template_id empty)\n")
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

        cat("[Cursor] Sending setShapeCursor message:", shape_type, "template:", template_id, "\n")
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
        } else if (shape_type == "RECTANGLE") {
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
        } else if (shape_type == "TRIANGLE") {
          radius <- if (nrow(template) > 0 && !is.na(template$Radius[1])) as.numeric(template$Radius[1]) else 20
          list(
            id = as.character(p$PlacementID),
            type = "triangle",
            x = as.numeric(p$CenterX),
            y = as.numeric(p$CenterY),
            r = radius,
            label = silo_code,
            fill = "rgba(168, 85, 247, 0.2)",
            stroke = "rgba(168, 85, 247, 0.8)",
            strokeWidth = 2
          )
        } else {
          # Fallback to circle for unknown types
          list(
            id = as.character(p$PlacementID),
            type = "circle",
            x = as.numeric(p$CenterX),
            y = as.numeric(p$CenterY),
            r = 20,
            label = silo_code,
            fill = "rgba(59, 130, 246, 0.2)",
            stroke = "rgba(59, 130, 246, 0.8)",
            strokeWidth = 2
          )
        }
      })

      canvas_shapes(shapes)

      # Only autofit on initial load, not on updates
      should_autofit <- !canvas_initialized()
      if (should_autofit) {
        canvas_initialized(TRUE)
      }

      session$sendCustomMessage(paste0(ns("root"), ":setData"), list(data = shapes, autoFit = should_autofit))
    })

    # ---- Form schema for placement details ----
    schema_config <- reactive({
      # Get all silos
      all_silos <- silos_data()

      # Get all placements for current layout to filter out already-placed silos
      layout_id <- current_layout_id()
      placements <- raw_placements()

      # Get current silo ID if editing existing placement
      pid <- selected_placement_id()
      current_silo_id <- NULL
      if (!is.null(pid) && !is.na(pid)) {
        current_placement <- placements[placements$PlacementID == pid, ]
        if (nrow(current_placement) > 0) {
          current_silo_id <- current_placement$SiloID[1]
        }
      }

      # Filter out silos that already have placements in this layout
      # BUT keep the current silo if we're editing
      available_silos <- all_silos
      if (nrow(all_silos) > 0 && nrow(placements) > 0) {
        placed_silo_ids <- placements$SiloID

        # Exclude placed silos, except the current one
        if (!is.null(current_silo_id)) {
          available_silos <- all_silos[!all_silos$SiloID %in% placed_silo_ids | all_silos$SiloID == current_silo_id, ]
        } else {
          available_silos <- all_silos[!all_silos$SiloID %in% placed_silo_ids, ]
        }
      }

      # Build dropdown choices (unallocated silos + current silo if editing)
      silo_choices <- c("(select silo)" = "")
      if (nrow(available_silos) > 0) {
        silo_choices <- c(silo_choices, setNames(
          as.character(available_silos$SiloID),
          paste0(available_silos$SiloCode, " - ", available_silos$SiloName)
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

    # ---- Silo schema configuration (for creating new silos) ----
    silo_schema_config <- reactive({
      sites <- sites_data()
      site_choices <- c("(select site)" = "")
      if (nrow(sites) > 0) {
        site_choices <- c(site_choices, setNames(
          as.character(sites$SiteID),
          paste0(sites$SiteCode, " - ", sites$SiteName)
        ))
      }

      areas <- areas_data()
      area_choices <- c("(select area)" = "")
      if (nrow(areas) > 0) {
        area_choices <- c(area_choices, setNames(
          as.character(areas$AreaID),
          paste0(areas$AreaCode, " - ", areas$AreaName, " (", areas$SiteCode, ")")
        ))
      }

      types <- container_types_data()
      type_choices <- c("(select type)" = "")
      if (nrow(types) > 0) {
        type_choices <- c(type_choices, setNames(
          as.character(types$ContainerTypeID),
          paste0(types$TypeCode, " - ", types$TypeName)
        ))
      }

      list(
        fields = list(
          field("SiloCode", "text", title="Code", column = 1, required = TRUE),
          field("SiloName", "text", title="Name", column = 1, required = TRUE),
          field("VolumeM3", "number", title="Volume (m³)", min=0, column = 1, required = TRUE),
          field("IsActive", "checkbox", title="Active", column = 1, default = TRUE),
          field("SiteID", "select", title="Site", enum=site_choices, column = 1, required = TRUE),
          field("AreaID", "select", title="Area", enum=area_choices, column = 1),
          field("ContainerTypeID", "select", title="Container Type", enum=type_choices, column = 1, required = TRUE)
        ),
        columns = 1
      )
    })

    silo_form_data <- reactive({
      # Pre-populate Site and Area from main UI when creating new silo
      site_id <- input$layout_site_id
      area_id <- input$bg_area_id

      # Get area info to check if it's "ALL" category
      area_code <- NA
      if (!is.null(area_id) && area_id != "") {
        canvas_id <- input$canvas_id
        if (!is.null(canvas_id) && canvas_id != "") {
          canvas_df <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
          if (!inherits(canvas_df, "try-error") && !is.null(canvas_df) && nrow(canvas_df) > 0) {
            area_code <- canvas_df$AreaCode[1]
          }
        }
      }

      # Only pre-populate area if it's NOT an "ALL" category
      prepopulated_area <- ""
      if (!is.null(area_id) && area_id != "" && !is.na(area_code) && area_code != "ALL") {
        prepopulated_area <- area_id
      }

      list(
        SiloCode = "",
        SiloName = "",
        VolumeM3 = 100,
        IsActive = TRUE,
        SiteID = if (is.null(site_id) || site_id == "") "" else site_id,
        AreaID = prepopulated_area,
        ContainerTypeID = ""
      )
    })

    # ---- Form data based on selection ----
    form_data <- reactive({
      trigger_refresh()

      pid <- selected_placement_id()

      if (is.null(pid) || is.na(pid)) {
        # New placement - use pending data if available
        pending <- pending_placement()
        if (!is.null(pending)) {
          return(list(
            SiloID = if (!is.null(pending$SiloID)) as.character(pending$SiloID) else "",
            ShapeTemplateID = as.character(pending$ShapeTemplateID),
            LayoutID = pending$LayoutID,
            CenterX = pending$CenterX,
            CenterY = pending$CenterY,
            ZIndex = f_or(pending$ZIndex, 0),
            IsVisible = f_or(pending$IsVisible, TRUE),
            IsInteractive = f_or(pending$IsInteractive, TRUE)
          ))
        } else {
          # No pending data - empty form
          return(list(
            SiloID = "",
            ShapeTemplateID = "",
            LayoutID = current_layout_id(),
            CenterX = 100,
            CenterY = 100,
            ZIndex = 0,
            IsVisible = TRUE,
            IsInteractive = TRUE
          ))
        }
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
          is_new_record <- is.null(data$PlacementID) || is.na(data$PlacementID)

          saved_id <- upsert_placement(data)
          selected_placement_id(as.integer(saved_id))

          # Update the canvas shape immediately after save (before refresh)
          if (!is_new_record && !is.null(data$ShapeTemplateID) && data$ShapeTemplateID != "") {
            # Find template for saved shape
            templates <- shape_templates_data()
            template <- templates[templates$ShapeTemplateID == as.integer(data$ShapeTemplateID), ]

            if (nrow(template) > 0) {
              shape_type <- template$ShapeType[1]

              # Get silo info for label
              silos <- silos_data()
              silo <- silos[silos$SiloID == as.integer(data$SiloID), ]
              silo_code <- if (nrow(silo) > 0) silo$SiloCode[1] else paste0("S", data$SiloID)

              # Build updated shape
              updated_shape <- if (shape_type == "CIRCLE") {
                radius <- as.numeric(f_or(template$Radius[1], 20))
                list(
                  id = as.character(saved_id),
                  type = "circle",
                  x = as.numeric(data$CenterX),
                  y = as.numeric(data$CenterY),
                  r = radius,
                  label = silo_code,
                  fill = "rgba(59, 130, 246, 0.2)",
                  stroke = "rgba(59, 130, 246, 0.8)",
                  strokeWidth = 2
                )
              } else if (shape_type == "RECTANGLE") {
                width <- as.numeric(f_or(template$Width[1], 40))
                height <- as.numeric(f_or(template$Height[1], 40))
                list(
                  id = as.character(saved_id),
                  type = "rect",
                  x = as.numeric(data$CenterX) - width / 2,
                  y = as.numeric(data$CenterY) - height / 2,
                  w = width,
                  h = height,
                  label = silo_code,
                  fill = "rgba(34, 197, 94, 0.2)",
                  stroke = "rgba(34, 197, 94, 0.8)",
                  strokeWidth = 2
                )
              } else if (shape_type == "TRIANGLE") {
                radius <- as.numeric(f_or(template$Radius[1], 20))
                list(
                  id = as.character(saved_id),
                  type = "triangle",
                  x = as.numeric(data$CenterX),
                  y = as.numeric(data$CenterY),
                  r = radius,
                  label = silo_code,
                  fill = "rgba(168, 85, 247, 0.2)",
                  stroke = "rgba(168, 85, 247, 0.8)",
                  strokeWidth = 2
                )
              } else {
                NULL
              }

              if (!is.null(updated_shape)) {
                cat("[Canvas] Updating shape on save:", saved_id, "to type:", shape_type, "\n")
                session$sendCustomMessage(paste0(ns("root"), ":updateShape"), list(shape = updated_shape))
              }
            }
          }

          trigger_refresh(trigger_refresh() + 1)

          # Clear pending placement and temp shape if this was a new record
          if (is_new_record) {
            pending_placement(NULL)
            session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())
          }

          # Note: Cursor clearing on save is parked as "not must have"

          # Close panel after successful save
          shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

          showNotification("Placement saved", type = "message", duration = 2)
          return(TRUE)
        }, error = function(e) {
          showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
          return(FALSE)
        })
      },
      on_delete = function() {
        pid <- selected_placement_id()

        # If it's a new placement (NA), treat as "Reset"
        if (is.null(pid) || is.na(pid)) {
          pending_placement(NULL)
          session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

          # Close panel
          shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

          return(TRUE)
        }

        # Otherwise, it's a real delete
        tryCatch({
          delete_placement(pid)
          selected_placement_id(NULL)
          trigger_refresh(trigger_refresh() + 1)

          # Close panel after deletion
          shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

          showNotification("Placement deleted", type = "message", duration = 2)
          return(TRUE)
        }, error = function(e) {
          showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
          return(FALSE)
        })
      }
    )

    # ---- Silo form module (for creating new silos) ----
    silo_form_module <- mod_html_form_server(
      id = "silo_form",
      schema_config = silo_schema_config,
      form_data = silo_form_data,
      title_field = "SiloName",
      show_header = TRUE,
      show_delete_button = TRUE,  # Acts as Cancel button
      on_save = function(data) {
        tryCatch({
          # Save new silo
          saved_id <- upsert_silo(data)

          # Refresh silos list first
          silos_refresh(silos_refresh() + 1)

          # Get pending placement data (shape/location from canvas)
          pending <- pending_placement()
          if (!is.null(pending)) {
            # Update pending placement with newly created silo
            pending$SiloID <- as.character(saved_id)
            pending_placement(pending)
          }

          # Set to "add new" mode to show populated placement form
          selected_placement_id(NA)

          # Force form to reload AFTER updating pending data
          trigger_refresh(trigger_refresh() + 1)

          # Switch back to placement mode
          panel_mode("placement")

          showNotification("Silo created successfully", type = "message", duration = 2)
          return(TRUE)
        }, error = function(e) {
          showNotification(paste("Error creating silo:", conditionMessage(e)), type = "error", duration = NULL)
          return(FALSE)
        })
      },
      on_delete = function() {
        # Cancel silo creation - clear pending data and return to normal state
        pending_placement(NULL)
        panel_mode("placement")
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

        # Close panel
        shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

        return(TRUE)
      }
    )

    # ---- Panel header UI (conditional based on mode) ----
    output$panel_header_ui <- renderUI({
      mode <- panel_mode()
      title <- if (mode == "silo") "Create New Silo" else "Placement Details"
      h3(class = "ui header", style = "margin: 0;", title)
    })

    # ---- Panel content UI (conditional based on mode) ----
    output$panel_content_ui <- renderUI({
      mode <- panel_mode()
      if (mode == "silo") {
        # Show both silo form (edit mode) and placement form (read-only preview)
        tagList(
          div(class = "ui info message", style = "margin-bottom: 1rem;",
            tags$p(style = "margin: 0;",
              strong("No silos available."),
              " Create a new silo to place on the canvas."
            )
          ),
          # Silo creation form (edit mode)
          mod_html_form_ui(ns("silo_form"), max_width = "100%", margin = "0"),

          # Divider
          tags$hr(style = "margin: 1.5rem 0; border-top: 2px solid #dee2e6;"),

          # Placement preview (read-only, shows stored shape/location)
          div(style = "opacity: 0.6; pointer-events: none;",
            tags$h4("Placement Preview", style = "margin-bottom: 0.75rem; color: #6c757d;"),
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
          )
        )
      } else {
        mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
      }
    })

    # ---- Warning banner UI (shown when no silos available) ----
    output$no_silo_warning <- renderUI({
      if (!show_silo_warning()) return(NULL)

      div(
        style = "background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 0.75rem; margin-bottom: 0.5rem; border-radius: 4px; display: flex; align-items: center; justify-content: space-between;",
        div(
          style = "display: flex; align-items: center; gap: 0.5rem;",
          tags$i(class = "fas fa-exclamation-triangle", style = "font-size: 18px;"),
          tags$span(
            style = "font-weight: 500;",
            "No silos available to create placement."
          )
        ),
        div(
          style = "display: flex; gap: 0.5rem;",
          actionButton(ns("create_silo_btn"), "Create New Silo",
                      class = "btn-sm btn-primary",
                      style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;"),
          actionButton(ns("cancel_warning_btn"), "Cancel",
                      class = "btn-sm btn-secondary",
                      style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;")
        )
      )
    })

    # ---- Move operation bar UI (shown when moving an object) ----
    output$move_operation_bar <- renderUI({
      if (!move_mode_state()) return(NULL)

      current_pos <- move_current_position()
      if (is.null(current_pos)) return(NULL)

      tagList(
        # CSS for move bar styling
        tags$style(HTML("
          .move-bar {
            background: #cfe2ff;
            border: 1px solid #b6d4fe;
            color: #084298;
            padding: 0.3rem;
            margin-bottom: 0.5rem;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: space-between;
          }
          .move-bar .move-title {
            display: flex;
            align-items: center;
            gap: 0.5rem;
          }
          .move-bar .move-coords {
            display: flex;
            align-items: center;
            gap: 1rem;
            position: absolute;
            left: 50%;
            transform: translateX(-50%);
          }
          .move-bar .move-coord-group {
            display: flex;
            align-items: center;
            gap: 0.3rem;
          }
          .move-bar .move-coord-group label {
            margin: 0;
            font-weight: 500;
            line-height: 28px;
          }
          .move-bar .move-coord-group .form-group {
            margin-bottom: 0;
          }
          .move-bar .move-buttons {
            display: flex;
            gap: 0.5rem;
            align-items: center;
          }
        ")),
        div(
          class = "move-bar",
          # Title on left
          div(
            class = "move-title",
            tags$i(class = "fas fa-arrows-alt", style = "font-size: 18px;"),
            tags$span(style = "font-weight: 500;", "Move Mode")
          ),
          # Coordinates in center
          div(
            class = "move-coords",
            div(
              class = "move-coord-group",
              tags$label("X:"),
              numericInput(ns("move_x"), label = NULL, value = round(current_pos$x, 2),
                          width = "80px", step = 1)
            ),
            div(
              class = "move-coord-group",
              tags$label("Y:"),
              numericInput(ns("move_y"), label = NULL, value = round(current_pos$y, 2),
                          width = "80px", step = 1)
            )
          ),
          # Buttons on right
          div(
            class = "move-buttons",
            actionButton(ns("move_reset"), "Reset (Esc)",
                        class = "btn-sm btn-secondary",
                        style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;"),
            actionButton(ns("move_confirm"), "Confirm Placement",
                        class = "btn-sm btn-primary",
                        style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;")
          )
        ),
        # JavaScript for Enter key handling and Escape key
        tags$script(HTML(sprintf("
          $(document).ready(function() {
            var typingTimeout;
            var isTyping = false;

            // Track when user is typing (not using arrows)
            $('#%s, #%s').on('keydown', function(e) {
              // Arrow keys, Home, End, Page Up/Down don't set typing flag
              if (e.which >= 37 && e.which <= 40) {
                isTyping = false;
              } else if (e.which === 13) {
                // Enter key
                isTyping = false;
              } else {
                // Any other key = typing
                isTyping = true;
              }
            });

            // Handle Enter key for move_x and move_y
            $('#%s, #%s').on('keypress', function(e) {
              if (e.which === 13) {
                e.preventDefault();
                isTyping = false;
                $(this).trigger('change');
                Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
              }
            });

            // Handle change events (from arrows or blur)
            $('#%s, #%s').on('change', function(e) {
              if (!isTyping) {
                // Change from arrows, Enter, or blur after typing elsewhere
                Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
              }
              isTyping = false;
            });

            // Prevent change on blur when typing (wait for Enter)
            $('#%s, #%s').on('blur', function(e) {
              if (isTyping) {
                // User was typing and clicked away - don't trigger update
                e.preventDefault();
                e.stopPropagation();
                isTyping = false;
                return false;
              }
            });

            // Handle Escape key to reset/cancel move mode
            $(document).on('keydown.movemode', function(e) {
              if (e.key === 'Escape') {
                var moveResetBtn = $('#%s');
                if (moveResetBtn.length && moveResetBtn.is(':visible')) {
                  e.preventDefault();
                  moveResetBtn.click();
                }
              }
            });
          });

          // Clean up when move bar is removed
          $(document).on('shiny:visualchange', function() {
            if (!$('#%s').is(':visible')) {
              $(document).off('keydown.movemode');
            }
          });
        ", ns("move_x"), ns("move_y"),
           ns("move_x"), ns("move_y"), ns("move_enter_pressed"),
           ns("move_x"), ns("move_y"), ns("move_enter_pressed"),
           ns("move_x"), ns("move_y"),
           ns("move_reset"), ns("move_reset"))))
      )
    })

    # ---- Toolbar button handlers ----

    # Handle panel close - clear temp shape if not saved
    observeEvent(input$panel_closed, {
      # If there's pending placement, clear it and temp shape
      if (!is.null(pending_placement())) {
        pending_placement(NULL)
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())
      }
      # Reset to placement mode if in silo mode
      if (panel_mode() == "silo") {
        panel_mode("placement")
      }
    }, ignoreInit = TRUE)

    # Handle warning banner "Create New Silo" button
    observeEvent(input$create_silo_btn, {
      show_silo_warning(FALSE)  # Hide warning
      panel_mode("silo")  # Switch to silo mode

      # Set to "add new" mode so placement preview shows pending data
      selected_placement_id(NA)

      # Open panel
      shinyjs::runjs(sprintf("window.togglePanel_%s(true);", gsub("-", "_", ns("root"))))
    }, ignoreInit = TRUE)

    # Handle warning banner "Cancel" button
    observeEvent(input$cancel_warning_btn, {
      show_silo_warning(FALSE)  # Hide warning
      # Clear any pending placement
      pending_placement(NULL)
      session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())
    }, ignoreInit = TRUE)

    # Handle canvas click to add placement (namespace is auto-applied, so listen for canvas_add_at not test_canvas_add_at)
    observeEvent(input$canvas_add_at, {
      click_data <- input$canvas_add_at
      cat("[Canvas] canvas_add_at triggered with data:", str(click_data), "\n")

      if (is.null(click_data)) {
        return()
      }

      # Get current layout
      layout_id <- current_layout_id()
      if (is.null(layout_id) || is.na(layout_id)) {
        showNotification("No layout selected", type = "error")
        return()
      }

      # Find the template to get shape type and dimensions
      templates <- shape_templates_data()
      template <- templates[templates$ShapeTemplateID == as.integer(click_data$templateId), ]

      if (nrow(template) == 0) {
        showNotification("Template not found", type = "error")
        return()
      }

      shape_type <- template$ShapeType[1]

      # Check if silos are available (filtered by site and area from silos_data())
      all_silos <- silos_data()
      placements <- raw_placements()

      cat("[Canvas] Silos (filtered by site/area):", nrow(all_silos), "\n")
      cat("[Canvas] Total placements:", nrow(placements), "\n")

      # Filter out already-placed silos
      available_silos <- all_silos
      if (nrow(available_silos) > 0 && nrow(placements) > 0) {
        placed_silo_ids <- placements$SiloID
        available_silos <- available_silos[!available_silos$SiloID %in% placed_silo_ids, ]
      }

      cat("[Canvas] Available silos (after removing placed):", nrow(available_silos), "\n")

      # Store pending placement data (shape and location from canvas click)
      pending_placement(list(
        LayoutID = layout_id,
        ShapeTemplateID = as.integer(click_data$templateId),
        CenterX = as.numeric(click_data$x),
        CenterY = as.numeric(click_data$y),
        ZIndex = 0,
        IsVisible = TRUE,
        IsInteractive = TRUE
      ))

      # If no silos available, show warning banner and keep pending data
      if (nrow(available_silos) == 0) {
        cat("[Canvas] No silos available - showing warning banner\n")

        # Set to "add new" mode immediately so placement form shows pending data
        selected_placement_id(NA)

        show_silo_warning(TRUE)
        return()
      }

      # Build temp shape for canvas
      temp_shape <- if (shape_type == "CIRCLE") {
        radius <- as.numeric(f_or(template$Radius[1], 20))
        list(
          type = "circle",
          x = as.numeric(click_data$x),
          y = as.numeric(click_data$y),
          r = radius,
          label = "New"
        )
      } else {
        width <- as.numeric(f_or(template$Width[1], 40))
        height <- as.numeric(f_or(template$Height[1], 40))
        list(
          type = "rect",
          x = as.numeric(click_data$x) - width / 2,
          y = as.numeric(click_data$y) - height / 2,
          w = width,
          h = height,
          label = "New"
        )
      }

      # Send temp shape to canvas (dotted border)
      session$sendCustomMessage(paste0(ns("root"), ":setTempShape"), list(shape = temp_shape))

      # Set to "new placement" mode
      selected_placement_id(NA)

      # DON'T clear cursor here - keep it so user can place more shapes
      # It will be cleared after successful save

      # Open panel in edit mode for new placement
      # Send custom message to open panel and trigger edit mode after animation
      module_id_form <- ns("form")
      module_id_js <- gsub("-", "_", module_id_form)
      root_id_js <- gsub("-", "_", ns("root"))

      session$sendCustomMessage(
        type = paste0(ns("root"), ":openPanelInEditMode"),
        message = list(
          rootId = root_id_js,
          formId = module_id_form,
          formIdJs = module_id_js
        )
      )
    }, ignoreInit = TRUE)

    # Handle Move button
    observeEvent(input$move, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to move", type = "warning", duration = 2)
        return()
      }

      # Get current placement data
      df <- try(get_placement_by_id(pid), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      # Store original position
      move_original_position(list(
        id = pid,
        x = as.numeric(df$CenterX),
        y = as.numeric(df$CenterY)
      ))

      # Set current position (initially same as original)
      move_current_position(list(
        x = as.numeric(df$CenterX),
        y = as.numeric(df$CenterY)
      ))

      # Enable edit mode if not already enabled
      if (!edit_mode_state()) {
        edit_mode_state(TRUE)
        shinyjs::addClass("edit_mode_toggle", "active")
        session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
      }

      # Enable move mode
      move_mode_state(TRUE)

      # Send message to JavaScript to apply dotted border to shape
      session$sendCustomMessage(paste0(ns("root"), ":setMoveMode"), list(
        shapeId = as.character(pid),
        enabled = TRUE
      ))
    })

    # Handle Enter key press to apply coordinate changes
    observeEvent(input$move_enter_pressed, {
      if (!move_mode_state()) return()

      current <- move_current_position()
      original <- move_original_position()

      if (!is.null(current) && !is.null(original)) {
        # Get current values from inputs
        new_x <- input$move_x
        new_y <- input$move_y

        if (is.null(new_x) || is.null(new_y)) return()

        # Update current position
        current$x <- new_x
        current$y <- new_y
        move_current_position(current)

        # Update shape position on canvas
        session$sendCustomMessage(paste0(ns("root"), ":updateMovePosition"), list(
          shapeId = as.character(original$id),
          x = new_x,
          y = new_y
        ))
      }
    }, ignoreInit = TRUE)

    # Handle Reset button - exits move mode completely
    observeEvent(input$move_reset, {
      original <- move_original_position()
      if (is.null(original)) return()

      # Reset to original position
      session$sendCustomMessage(paste0(ns("root"), ":updateMovePosition"), list(
        shapeId = as.character(original$id),
        x = original$x,
        y = original$y
      ))

      # Remove dotted border
      session$sendCustomMessage(paste0(ns("root"), ":setMoveMode"), list(
        shapeId = as.character(original$id),
        enabled = FALSE
      ))

      # Exit move mode
      move_mode_state(FALSE)
      move_original_position(NULL)
      move_current_position(NULL)

      # Exit edit mode
      edit_mode_state(FALSE)
      shinyjs::removeClass("edit_mode_toggle", "active")
      session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = FALSE))
    })

    # Handle Confirm Placement button
    observeEvent(input$move_confirm, {
      original <- move_original_position()
      current <- move_current_position()

      if (is.null(original) || is.null(current)) return()

      # Get placement data and update position
      df <- try(get_placement_by_id(original$id), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      df$CenterX <- current$x
      df$CenterY <- current$y

      tryCatch({
        upsert_placement(as.list(df))

        # Exit move mode
        move_mode_state(FALSE)
        move_original_position(NULL)
        move_current_position(NULL)

        # Remove dotted border from shape
        session$sendCustomMessage(paste0(ns("root"), ":setMoveMode"), list(
          shapeId = as.character(original$id),
          enabled = FALSE
        ))

        # Refresh canvas to show final position
        trigger_refresh(trigger_refresh() + 1)

        showNotification("Placement moved successfully", type = "message", duration = 2)
      }, error = function(e) {
        showNotification(paste("Error:", conditionMessage(e)), type = "error", duration = NULL)
      })
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

    # Handle canvas selection (namespace auto-applied: listen for canvas_selection not test_canvas_selection)
    observeEvent(input$canvas_selection, {
      sel_id <- input$canvas_selection
      if (!is.null(sel_id) && nzchar(sel_id)) {
        selected_placement_id(as.integer(sel_id))

        # Don't open panel if in move mode
        if (move_mode_state()) {
          return()
        }

        # Open panel to show placement details
        shinyjs::runjs(sprintf("window.togglePanel_%s(true);", gsub("-", "_", ns("root"))))

        # Ensure button says "Delete" for existing placement
        module_id_form <- ns("form")
        shinyjs::delay(300, {
          shinyjs::runjs(sprintf("
            const deleteBtn = document.querySelector('#%s .btn-delete span');
            if (deleteBtn) {
              deleteBtn.textContent = ' Delete';
              console.log('[Canvas] Button set to Delete for existing placement');
            }
          ", module_id_form))
        })
      }
    }, ignoreInit = TRUE)

    # Handle canvas move (drag in edit mode)
    observeEvent(input$canvas_moved, {
      moved <- input$canvas_moved
      if (is.null(moved)) return()

      # If in move mode, update current position but don't save to DB
      if (move_mode_state()) {
        original <- move_original_position()
        if (!is.null(original) && as.character(moved$id) == as.character(original$id)) {
          # Update current position for the move bar
          move_current_position(list(
            x = moved$x,
            y = moved$y
          ))

          # Update the numeric inputs
          updateNumericInput(session, "move_x", value = round(moved$x, 2))
          updateNumericInput(session, "move_y", value = round(moved$y, 2))
        }
        return()  # Don't save to DB or do anything else during move mode
      }

      # Normal edit mode: Update placement position in DB
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

        # Note: Cursor clearing on edit toggle is parked as "not must have"
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

    # Handle snap grid increment/decrement buttons
    observeEvent(input$snap_up, {
      current <- f_or(input$snap_grid, 0)
      new_snap <- current + 10
      updateNumericInput(session, "snap_grid", value = new_snap)
    })

    observeEvent(input$snap_down, {
      current <- f_or(input$snap_grid, 0)
      new_snap <- max(current - 10, 0)
      updateNumericInput(session, "snap_grid", value = new_snap)
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
      site_id <- input$layout_site_id
      area_id <- input$bg_area_id
      rotation <- input$bg_rotation
      scale <- input$bg_scale

      # Get current offset from reactiveVal (tracked via pan mode)
      offset <- bg_offset()

      # Save layout background settings (site is part of layout)
      result <- try(update_layout_background(
        layout_id = layout_id,
        canvas_id = if (is.null(canvas_id) || canvas_id == "") NULL else as.integer(canvas_id),
        site_id = if (is.null(site_id) || site_id == "") NULL else as.integer(site_id),
        rotation = rotation,
        pan_x = offset$x,
        pan_y = offset$y,
        scale_x = scale,  # Uniform scaling
        scale_y = scale   # Same for both axes
      ), silent = TRUE)

      # Save canvas area (area is part of canvas, not layout)
      if (!is.null(canvas_id) && canvas_id != "") {
        area_result <- try(update_canvas_area(
          as.integer(canvas_id),
          if (is.null(area_id) || area_id == "") NULL else as.integer(area_id)
        ), silent = TRUE)
      }

      if (inherits(result, "try-error")) {
        showNotification("Error saving layout settings", type = "error", duration = 3)
      } else {
        showNotification("Layout settings saved (site + area)", type = "message", duration = 2)
      }
    })

    # Handle zoom buttons
    observeEvent(input$zoom_in, {
      cat("[Canvas] Zoom in button clicked\n")
      session$sendCustomMessage(paste0(ns("root"), ":setZoom"), list(direction = "in"))
      # Update zoom level input (approximate percentage)
      current <- f_or(input$zoom_level, 100)
      updateNumericInput(session, "zoom_level", value = round(current * 1.2))
    })

    observeEvent(input$zoom_out, {
      cat("[Canvas] Zoom out button clicked\n")
      session$sendCustomMessage(paste0(ns("root"), ":setZoom"), list(direction = "out"))
      # Update zoom level input (approximate percentage)
      current <- f_or(input$zoom_level, 100)
      updateNumericInput(session, "zoom_level", value = round(current * 0.8))
    })

    # Handle zoom level input changes
    observeEvent(input$zoom_level, {
      # This is for future integration - currently zoom is controlled by buttons
      # Could be used to set exact zoom percentage
    }, ignoreInit = TRUE)

    # Handle fit view
    observeEvent(input$fit_view, {
      cat("[Canvas] Fit view button clicked\n")
      cat("[Canvas] Sending message:", paste0(ns("root"), ":fitView"), "\n")
      session$sendCustomMessage(paste0(ns("root"), ":fitView"), list())
    })

    # ---- Update canvas shape when ShapeTemplateID changes in form ----
    # Note: form module has namespace "form", so field IDs are "form-field_X"
    observeEvent(input[["form-field_ShapeTemplateID"]], {
      pid <- selected_placement_id()
      template_id <- input[["form-field_ShapeTemplateID"]]

      cat("[Canvas] ShapeTemplateID changed to:", template_id, "for placement:", pid, "\n")

      # Skip if no template selected
      if (is.null(template_id) || template_id == "") {
        cat("[Canvas] Skipping - no template selected\n")
        return()
      }

      # Find the template to get shape type and dimensions
      templates <- shape_templates_data()
      template <- templates[templates$ShapeTemplateID == as.integer(template_id), ]

      if (nrow(template) == 0) {
        return()
      }

      shape_type <- template$ShapeType[1]

      # Handle NEW placement (temp shape)
      if (is.null(pid) || is.na(pid)) {
        pending <- pending_placement()
        if (!is.null(pending)) {
          # Update temp shape with new template
          temp_shape <- if (shape_type == "CIRCLE") {
            radius <- as.numeric(f_or(template$Radius[1], 20))
            list(
              type = "circle",
              x = as.numeric(pending$CenterX),
              y = as.numeric(pending$CenterY),
              r = radius,
              label = "New"
            )
          } else if (shape_type == "RECTANGLE") {
            width <- as.numeric(f_or(template$Width[1], 40))
            height <- as.numeric(f_or(template$Height[1], 40))
            list(
              type = "rect",
              x = as.numeric(pending$CenterX) - width / 2,
              y = as.numeric(pending$CenterY) - height / 2,
              w = width,
              h = height,
              label = "New"
            )
          } else if (shape_type == "TRIANGLE") {
            radius <- as.numeric(f_or(template$Radius[1], 20))
            list(
              type = "triangle",
              x = as.numeric(pending$CenterX),
              y = as.numeric(pending$CenterY),
              r = radius,
              label = "New"
            )
          } else {
            return()
          }

          # Update temp shape on canvas
          session$sendCustomMessage(paste0(ns("root"), ":setTempShape"), list(shape = temp_shape))

          # Update pending placement data
          pending$ShapeTemplateID <- as.integer(template_id)
          pending_placement(pending)
        }
        return()
      }

      # Handle EXISTING placement - update visual only (not DB)
      current_placements <- raw_placements()
      placement <- current_placements[current_placements$PlacementID == pid, ]

      if (nrow(placement) == 0) {
        return()
      }

      # Get silo info for label
      silos <- silos_data()
      silo <- silos[silos$SiloID == placement$SiloID, ]
      silo_code <- if (nrow(silo) > 0) silo$SiloCode[1] else paste0("S", placement$SiloID)

      # Build updated shape
      if (shape_type == "CIRCLE") {
        radius <- as.numeric(f_or(template$Radius[1], 20))
        updated_shape <- list(
          id = as.character(pid),
          type = "circle",
          x = as.numeric(placement$CenterX),
          y = as.numeric(placement$CenterY),
          r = radius,
          label = silo_code,
          fill = "rgba(59, 130, 246, 0.2)",
          stroke = "rgba(59, 130, 246, 0.8)",
          strokeWidth = 2
        )
      } else if (shape_type == "RECTANGLE") {
        width <- as.numeric(f_or(template$Width[1], 40))
        height <- as.numeric(f_or(template$Height[1], 40))
        updated_shape <- list(
          id = as.character(pid),
          type = "rect",
          x = as.numeric(placement$CenterX) - width / 2,
          y = as.numeric(placement$CenterY) - height / 2,
          w = width,
          h = height,
          label = silo_code,
          fill = "rgba(34, 197, 94, 0.2)",
          stroke = "rgba(34, 197, 94, 0.8)",
          strokeWidth = 2
        )
      } else if (shape_type == "TRIANGLE") {
        radius <- as.numeric(f_or(template$Radius[1], 20))
        updated_shape <- list(
          id = as.character(pid),
          type = "triangle",
          x = as.numeric(placement$CenterX),
          y = as.numeric(placement$CenterY),
          r = radius,
          label = silo_code,
          fill = "rgba(168, 85, 247, 0.2)",
          stroke = "rgba(168, 85, 247, 0.8)",
          strokeWidth = 2
        )
      } else {
        return()
      }

      # Send message to update this specific shape on canvas (visual only, not committed)
      cat("[Canvas] Sending updateShape message for shape", pid, "type:", shape_type, "\n")
      session$sendCustomMessage(paste0(ns("root"), ":updateShape"), list(shape = updated_shape))
    }, ignoreInit = TRUE)

    # Debug: print all inputs starting with field_
    observe({
      cat("[Canvas] form-field_ShapeTemplateID value:", input[["form-field_ShapeTemplateID"]], "\n")
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
