# R/browsers/f_browser_siloplacements.R
# SiloPlacements Canvas Browser

# Source helpers
source("R/utils/f_siloplacements_helpers.R", local = TRUE)

# =========================== UI ===============================================
browser_siloplacements_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),

    # External CSS
    tags$link(rel = "stylesheet", href = "css/f_siloplacements.css"),

    # Canvas-specific inline styles (canvas ID needs namespace)
    tags$style(HTML(sprintf("
      #%s {
        display: block;
        width: 100%%;
        height: auto;
        cursor: crosshair;
      }
    ", ns("canvas")))),

    # Main content (shifts left when panel opens)
    div(class = "main-content", id = ns("main-content"),
      # Canvas area
      div(
        class = "canvas-container",

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
              shiny::selectInput(
                ns("layout_id"), label = NULL, choices = c(), width = "100%",
                selectize = FALSE
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
          shiny::selectInput(
            ns("layout_site_id"), label = NULL, choices = c(), width = "100%",
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
          shiny::selectInput(ns("canvas_id"), label = NULL, choices = c(), width = "100%", selectize = TRUE),

          # Column 4: Area label
          tags$label(
            "Area:",
            style = "margin: 0; font-size: 13px; font-weight: normal; text-align: right;"
          ),

          # Column 5: Area selector
          shiny::selectInput(
            ns("bg_area_id"), label = NULL, choices = c(), width = "100%",
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
          shiny::selectInput(ns("shape_template_id"), label = NULL, choices = c(), width = "100%", selectize = TRUE),

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
          )
        ),

        # Move operation bar (hidden by default, shown when moving an object)
        uiOutput(ns("move_operation_bar")),

        # Warning banner (hidden by default, shown when no silos available)
        uiOutput(ns("no_silo_warning")),

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

# ========================== SERVER ============================================
browser_siloplacements_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    cat("\n========================================\n")
    cat("[", id, "] MODULE INITIALIZATION STARTED\n")
    cat("========================================\n")
    ns <- session$ns

    # Track if this is the first time the UI becomes visible
    ui_initialized <- reactiveVal(FALSE)

    # Toggle panel visibility when edit mode changes
    observeEvent(edit_mode_state(), {
      if (edit_mode_state()) {
        # Edit mode ON - show edit panel, hide readonly panel
        shinyjs::runjs(sprintf("$('#%s').css({'visibility': '', 'position': '', 'z-index': ''})", ns("edit_panel")))
        shinyjs::runjs(sprintf("$('#%s').css({'visibility': 'hidden', 'position': 'absolute', 'z-index': '-1'})", ns("readonly_panel")))
      } else {
        # Edit mode OFF - hide edit panel, show readonly panel
        shinyjs::runjs(sprintf("$('#%s').css({'visibility': 'hidden', 'position': 'absolute', 'z-index': '-1'})", ns("edit_panel")))
        shinyjs::runjs(sprintf("$('#%s').css({'visibility': '', 'position': '', 'z-index': ''})", ns("readonly_panel")))
      }
    }, ignoreInit = TRUE)

    notify_error <- function(prefix, e, duration = NULL) {
      message(sprintf("[siloplacements] %s: %s", prefix, conditionMessage(e)))
      if (!is.null(e$call)) {
        message("  call: ", paste(deparse(e$call), collapse = " "))
      }
      showNotification(paste(prefix, conditionMessage(e)), type = "error", duration = duration)
    }
    
    # Safely coerce optional ID inputs that may be NULL/blank/NA
    as_optional_integer <- function(value) {
      if (is.null(value) || is.na(value) || identical(value, "")) return(NULL)
      as.integer(value)
    }
    
    # Same as above but returns NA instead of NULL for missing values
    as_optional_integer_na <- function(value) {
      if (is.null(value) || is.na(value) || identical(value, "")) return(NA)
      as.integer(value)
    }
    
    # Preserve blank string when pre-populating form fields
    blank_if_missing <- function(value) {
      if (is.null(value) || is.na(value) || identical(value, "")) return("")
      value
    }
    
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
    sites_refresh <- reactiveVal(0)  # Trigger to refresh sites list
    areas_refresh <- reactiveVal(0)  # Trigger to refresh areas list
    shape_templates_refresh <- reactiveVal(0)  # Trigger to refresh shape templates list
    show_silo_warning <- reactiveVal(FALSE)  # Track whether to show "no silos" warning
    initial_load_complete <- reactiveVal(FALSE)  # Track whether initial layout load is complete
    move_mode_state <- reactiveVal(FALSE)  # Track whether move mode is active
    move_original_position <- reactiveVal(NULL)  # Store original position before moving (list with x, y, id)
    move_current_position <- reactiveVal(NULL)  # Track current position during move (list with x, y)
    move_is_duplicate <- reactiveVal(FALSE)  # Track if current move is for a duplicate operation
    pending_duplicate_data <- reactiveVal(NULL)  # Store duplicate data (temp shape, coords) when waiting for silo creation
    selection_source <- reactiveVal("dropdown")  # Track if selection came from "canvas" or "dropdown" (default is dropdown)

    # ---- Reusable Move Mode Functions ----

    # Enter move mode for a placement (works for existing or temp placements)
    enter_move_mode <- function(placement_id, center_x, center_y, is_duplicate = FALSE) {
      # Store original position
      move_original_position(list(
        id = placement_id,
        x = as.numeric(center_x),
        y = as.numeric(center_y)
      ))

      # Set current position (initially same as original)
      move_current_position(list(
        x = as.numeric(center_x),
        y = as.numeric(center_y)
      ))

      # Track if this is a duplicate operation
      move_is_duplicate(is_duplicate)

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
        shapeId = as.character(placement_id),
        enabled = TRUE
      ))
    }

    # Exit move mode (reset or cancel)
    exit_move_mode <- function(reset_position = TRUE) {
      original <- move_original_position()
      if (is.null(original)) return()

      if (reset_position) {
        # Reset to original position
        session$sendCustomMessage(paste0(ns("root"), ":updateMovePosition"), list(
          shapeId = as.character(original$id),
          x = original$x,
          y = original$y
        ))
      }

      # Remove dotted border
      session$sendCustomMessage(paste0(ns("root"), ":setMoveMode"), list(
        shapeId = as.character(original$id),
        enabled = FALSE
      ))

      # If this was a duplicate operation, remove temp shape
      if (move_is_duplicate()) {
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())
        # Also clear pending duplicate data
        pending_duplicate_data(NULL)
        pending_placement(NULL)
      }

      # Exit move mode
      move_mode_state(FALSE)
      move_original_position(NULL)
      move_current_position(NULL)
      move_is_duplicate(FALSE)

      # Exit edit mode
      edit_mode_state(FALSE)
      shinyjs::removeClass("edit_mode_toggle", "active")
      session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = FALSE))
    }

    # ---- Load layouts ----
    layouts_data <- reactive({
      layouts_refresh()  # Depend on refresh trigger
      df <- try(list_canvas_layouts(limit = 100), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # Populate layout dropdown
    observe({
      cat("[", id, "] Populating layout dropdown observer fired\n")
      layouts <- layouts_data()
      cat("[", id, "] Found", nrow(layouts), "layouts\n")

      if (nrow(layouts) > 0) {
        cat("[", id, "] Building choices for layout dropdown\n")
        choices <- setNames(layouts$LayoutID, layouts$LayoutName)

        # Use isolate to read current_layout_id without creating a dependency
        current_id <- isolate(current_layout_id())
        cat("[", id, "] Current layout ID:", current_id, "\n")

        selected_val <- if (!is.null(current_id) && !is.na(current_id) &&
                           as.character(current_id) %in% choices) {
          as.character(current_id)
        } else {
          as.character(layouts$LayoutID[1])
        }
        cat("[", id, "] Selected value:", selected_val, "\n")
        cat("[", id, "] Calling updateSelectInput for layout_id with", length(choices), "choices\n")

        updateSelectInput(session, "layout_id", choices = choices, selected = selected_val)

        cat("[", id, "] Layout dropdown updateSelectInput called\n")
      } else {
        cat("[", id, "] No layouts found\n")
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
        notify_error("Error creating layout", e)
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
      }
    }, ignoreInit = TRUE)

    # Handle site selection - update layout in database
    # Note: Placements/silos/areas will auto-refresh via reactive dependencies on input$layout_site_id
    observeEvent(input$layout_site_id, {
      layout_id <- current_layout_id()
      if (is.null(layout_id) || is.na(layout_id)) return()

      site_id_value <- as_optional_integer_na(input$layout_site_id)

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
        notify_error("Error updating site", e)
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
      cat("[", id, "] Populating canvas dropdown observer fired\n")
      canvases <- canvases_data()
      cat("[", id, "] Found", nrow(canvases), "canvases\n")

      # Preserve current selection
      current_canvas_id <- input$canvas_id

      choices <- c("(None)" = "")
      if (nrow(canvases) > 0) {
        # Show only canvas names (area is in separate dropdown)
        choices <- c(choices, setNames(canvases$id, canvases$canvas_name))
      }

      # Update choices and restore selection
      updateSelectInput(session, "canvas_id", choices = choices, selected = current_canvas_id)
      cat("[", id, "] Canvas dropdown updated with", length(choices), "choices\n")
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
        notify_error("Error updating canvas area", e)
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
      updateSelectInput(session, "canvas_id", selected = canvas_id)

      # Update area selection based on the canvas (if canvas is set)
      if (!is.null(canvas_id) && canvas_id != "") {
        canvas_data <- try(get_canvas_by_id(as.integer(canvas_id)), silent = TRUE)
        if (!inherits(canvas_data, "try-error") && !is.null(canvas_data) && nrow(canvas_data) > 0) {
          area_id <- if (is.null(canvas_data$AreaID) || is.na(canvas_data$AreaID[1])) "" else as.character(canvas_data$AreaID[1])
          updateSelectInput(session, "bg_area_id", selected = area_id)
        }
      }

      # Update site selection
      site_id <- if (is.null(layout$SiteID) || is.na(layout$SiteID)) "" else as.character(layout$SiteID)
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
        updateSelectInput(session, "bg_area_id", selected = area_id)
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
      site_id <- as_optional_integer(input$layout_site_id)

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
      site_id <- as_optional_integer(input$layout_site_id)

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
      shape_templates_refresh()  # Depend on refresh trigger
      df <- try(list_shape_templates(limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    container_types_data <- reactive({
      df <- try(list_container_types(limit = 500), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })
    
    # Lightweight observer to log dataset sizes whenever we re-fetch core data
    log_data_snapshot <- function(tag = "") {
      
      safe_nrow <- function(expr) {
        tryCatch({
          df <- isolate(expr())
          if (is.null(df)) 0 else nrow(df)
        }, error = function(e) {
          cat("[", id, "] Data snapshot error:", conditionMessage(e), "\n")
          NA_integer_
        })
      }
      cat("[", id, "] Data snapshot", if (nzchar(tag)) paste0(" (", tag, ")"), ":\n", sep = "")
      cat("  layouts:", safe_nrow(layouts_data), "| canvases:", safe_nrow(canvases_data),
          "| sites:", safe_nrow(sites_data), "| areas:", safe_nrow(areas_data),
          "| silos:", safe_nrow(silos_data), "| shape templates:", safe_nrow(shape_templates_data), "\n")
    }
    
    observeEvent(
      list(
        layouts_refresh(), canvases_refresh(), silos_refresh(),
        sites_refresh(), areas_refresh(), shape_templates_refresh()
      ),
      {
        log_data_snapshot("refresh")
      },
      ignoreInit = TRUE
    )
    

    sites_data <- reactive({
      sites_refresh()  # Depend on refresh trigger
      df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    areas_data <- reactive({
      areas_refresh()  # Depend on refresh trigger
      # Get site_id directly from input selector (not from database)
      # This ensures immediate filtering when site selector changes
      site_id <- as_optional_integer(input$layout_site_id)

      df <- try(list_areas(site_id = site_id, limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) data.frame() else df
    })

    # Detect when user navigates to this route (for app with router)
    # The route parameter is a reactiveVal that changes when navigation occurs
    if (!is.null(route) && is.function(route)) {
      observe({
        current_route <- route()
        cat("[", id, "] Route changed to:", paste(current_route, collapse="/"), "\n")

        # Check if this route is for placements (current_route should be c("placements"))
        if (length(current_route) > 0 && current_route[1] == "placements") {
          if (!ui_initialized()) {
            cat("[", id, "] First navigation to placements, triggering refresh\n")
            ui_initialized(TRUE)

            # Trigger all refresh reactives to populate dropdowns
            isolate({
              layouts_refresh(layouts_refresh() + 1)
              canvases_refresh(canvases_refresh() + 1)
              silos_refresh(silos_refresh() + 1)
              sites_refresh(sites_refresh() + 1)
              areas_refresh(areas_refresh() + 1)
              shape_templates_refresh(shape_templates_refresh() + 1)
            })

            log_data_snapshot("route entry")
          }
        }
      })
    }

    # When running standalone (test), trigger refresh on flush
    # When running in app with router, rely on route-based refresh instead
    if (is.null(route) || !is.function(route)) {
      cat("[", id, "] Standalone mode - using onFlushed trigger\n")
      session$onFlushed(function() {
        cat("[", id, "] onFlushed callback triggered (standalone mode)\n")
        isolate({
          layouts_refresh(layouts_refresh() + 1)
          canvases_refresh(canvases_refresh() + 1)
          silos_refresh(silos_refresh() + 1)
          sites_refresh(sites_refresh() + 1)
          areas_refresh(areas_refresh() + 1)
          shape_templates_refresh(shape_templates_refresh() + 1)
        })
        log_data_snapshot("onFlushed")
      }, once = TRUE)
    } else {
      cat("[", id, "] Router mode - refresh will trigger on navigation\n")
    }

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
        session$sendCustomMessage(paste0(ns("root"), ":setData"), list(data = list(), autoFit = FALSE, selectedId = NULL))
        return()
      }

      silos <- silos_data()
      templates <- shape_templates_data()

      # Build shapes for canvas using helper function
      shapes <- build_canvas_shapes(placements, silos, templates)

      canvas_shapes(shapes)

      # Only autofit on initial load, not on updates
      should_autofit <- !canvas_initialized()
      if (should_autofit) {
        canvas_initialized(TRUE)
      }

      # Get current selection for highlighting
      selected_id <- selected_placement_id()

      session$sendCustomMessage(
        paste0(ns("root"), ":setData"),
        list(
          data = shapes,
          autoFit = should_autofit,
          selectedId = if (!is.null(selected_id) && !is.na(selected_id)) as.character(selected_id) else NULL
        )
      )
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
        SiteID = blank_if_missing(site_id),
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
          notify_error("Error saving placement", e)
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
          notify_error("Error deleting placement", e)
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

            # Set to "add new" mode to show populated placement form
            selected_placement_id(NA)

            # Force form to reload AFTER updating pending data
            trigger_refresh(trigger_refresh() + 1)

            # Switch back to placement mode (resume placement process)
            panel_mode("placement")

            showNotification("Silo created successfully", type = "message", duration = 2)
          } else {
            # No pending placement - process was abandoned
            # Just close the panel, don't switch to placement mode
            shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

            showNotification("Silo created successfully", type = "message", duration = 2)
          }

          return(TRUE)
        }, error = function(e) {
          notify_error("Error creating silo", e)
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
        # Check if there's pending placement data
        has_pending <- !is.null(pending_placement())

        # Show silo form, and placement preview only if there's pending data
        tagList(
          if (has_pending) {
            div(class = "ui info message", style = "margin-bottom: 1rem;",
              tags$p(style = "margin: 0;",
                strong("No silos available."),
                " Create a new silo to place on the canvas."
              )
            )
          },
          # Silo creation form (edit mode)
          mod_html_form_ui(ns("silo_form"), max_width = "100%", margin = "0"),

          # Only show placement preview if there's pending data
          if (has_pending) {
            tagList(
              # Divider
              tags$hr(style = "margin: 1.5rem 0; border-top: 2px solid #dee2e6;"),

              # Placement preview (read-only, shows stored shape/location)
              div(style = "opacity: 0.6; pointer-events: none;",
                tags$h4("Placement Preview", style = "margin-bottom: 0.75rem; color: #6c757d;"),
                mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
              )
            )
          }
        )
      } else {
        # Placement mode - show both but hide based on edit mode
        tagList(
          # Editable form (hidden when edit mode OFF)
          div(
            id = ns("edit_panel"),
            style = "visibility: hidden; position: absolute; z-index: -1;",
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0"),
            # Move and Duplicate buttons at bottom left
            div(style = "margin-top: 1rem; padding: 0 1rem; display: flex; gap: 0.5rem;",
              actionButton(ns("panel_move"), "Move", icon = icon("arrows-alt"),
                          class = "btn-sm btn-info",
                          style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;"),
              actionButton(ns("panel_duplicate"), "Duplicate", icon = icon("copy"),
                          class = "btn-sm btn-secondary",
                          style = "height: 28px; padding: 0.25rem 0.75rem; font-size: 12px;")
            )
          ),
          # Read-only view (hidden when edit mode ON)
          div(
            id = ns("readonly_panel"),
            style = "",
            # Object selector
            div(style = "padding: 1rem;",
              # Checkboxes
              checkboxInput(ns("show_inactive"), "Show inactive silos", value = FALSE),
              checkboxInput(ns("search_all_sites"), "Search other sites and areas", value = FALSE),

              # Searchable dropdown
              shiny::selectInput(
                ns("object_selector"),
                "Select placement:",
                choices = c(),
                width = "100%",
                selectize = TRUE
              )
            ),

            # Banner for different layout
            uiOutput(ns("layout_warning_banner")),

            # Details sections (collapsible)
            div(style = "padding: 0 1rem 1rem 1rem;",
              uiOutput(ns("object_details"))
            )
          )
        )
      }
    })

    # ---- Object selector (non-edit mode) ----

    # Populate object selector dropdown based on filters
    observe({
      cat("[", id, "] Object selector observer fired\n")
      # Depend on canvas selection so the dropdown refreshes after clicks
      canvas_pid <- selected_placement_id()

      # Read reactive inputs FIRST to establish dependencies
      show_inactive <- input$show_inactive
      search_all <- input$search_all_sites
      current_layout <- current_layout_id()

      # Only update when in non-edit mode
      if (edit_mode_state()) {
        cat("[", id, "] Skipping object selector - edit mode active\n")
        return()
      }

      source <- selection_source()

      # Default NULL inputs to FALSE so the selector can still populate even
      # if the initial checkbox values haven't arrived from the client yet.
      if (is.null(show_inactive)) {
        show_inactive <- FALSE
      }
      if (is.null(search_all)) {
        search_all <- FALSE
      }
      if (is.null(current_layout)) {
        cat("[", id, "] Skipping object selector - current layout missing\n")
        return()
      }

      cat("[", id, "] Building object selector query\n")

      # Get all silos with optional placement info
      query <- paste0("
        SELECT
          s.SiloID,
          s.SiloCode,
          s.SiloName,
          s.IsActive,
          si.SiteID,
          si.SiteCode,
          si.SiteName,
          sa.AreaID,
          sa.AreaCode,
          sa.AreaName,
          p.PlacementID,
          p.LayoutID,
          p.CenterX,
          p.CenterY
        FROM Silos s
        LEFT JOIN Sites si ON s.SiteID = si.SiteID
        LEFT JOIN SiteAreas sa ON s.AreaID = sa.AreaID
        LEFT JOIN SiloPlacements p ON s.SiloID = p.SiloID AND p.LayoutID = ", current_layout, "
      ")

      # Add filter conditions
      where_clauses <- c()

      if (!show_inactive) {
        where_clauses <- c(where_clauses, "s.IsActive = 1")
      }

      if (!search_all) {
        # Filter by current layout's site and area
        current_layout_data <- try(get_layout_by_id(current_layout), silent = TRUE)
        if (!inherits(current_layout_data, "try-error") && nrow(current_layout_data) > 0) {
          site_id <- current_layout_data$SiteID[1]
          if (!is.null(site_id) && !is.na(site_id)) {
            where_clauses <- c(where_clauses, paste0("s.SiteID = ", site_id))
          }
        }
      }

      if (length(where_clauses) > 0) {
        query <- paste0(query, " WHERE ", paste(where_clauses, collapse = " AND "))
      }

      query <- paste0(query, " ORDER BY si.SiteName, sa.AreaName, s.SiloCode")

      all_silos <- try(DBI::dbGetQuery(db_pool(), query), silent = FALSE)

      if (inherits(all_silos, "try-error")) {
        cat("[Object Selector] Query error:", as.character(all_silos), "\n")
        updateSelectInput(session, "object_selector", choices = c("No silos found" = ""))
        return()
      }

      if (nrow(all_silos) == 0) {
        cat("[", id, "] Object selector: no silos returned for current filters\n")
        updateSelectInput(session, "object_selector", choices = c("No silos found" = ""))
        return()
      }

      # Get current layout's site for comparison
      current_layout_data <- try(get_layout_by_id(current_layout), silent = TRUE)
      current_site_id <- NULL
      if (!inherits(current_layout_data, "try-error") && nrow(current_layout_data) > 0) {
        current_site_id <- current_layout_data$SiteID[1]
      }

      # Build choices: "SiteName / AreaName / SiloCode - SiloName"
      # Mark items not from current site or without placement with brackets
      choice_labels <- sapply(1:nrow(all_silos), function(i) {
        site_name <- if (!is.na(all_silos$SiteName[i])) all_silos$SiteName[i] else "Unknown Site"
        area_part <- if (!is.na(all_silos$AreaName[i])) paste0(" / ", all_silos$AreaName[i]) else ""
        silo_part <- paste0(" / ", all_silos$SiloCode[i], " - ", all_silos$SiloName[i])

        base_label <- paste0(site_name, area_part, silo_part)

        # Mark items from other sites OR without placement in current layout with brackets
        from_different_site <- isTRUE(!is.null(current_site_id) && !is.na(all_silos$SiteID[i]) &&
                               all_silos$SiteID[i] != current_site_id)
        no_placement <- isTRUE(is.na(all_silos$PlacementID[i]))

        if (from_different_site || no_placement) {
          base_label <- paste0("[", base_label, "]")
        }

        base_label
      })

      # Use PlacementID only if from current site AND has placement
      # Otherwise use "silo_" prefix to prevent centering
      choice_values <- sapply(1:nrow(all_silos), function(i) {
        from_current_site <- isTRUE(!is.null(current_site_id) && !is.na(all_silos$SiteID[i]) &&
                             all_silos$SiteID[i] == current_site_id)
        has_placement <- isTRUE(!is.na(all_silos$PlacementID[i]))

        if (from_current_site && has_placement) {
          as.character(all_silos$PlacementID[i])
        } else {
          paste0("silo_", all_silos$SiloID[i])
        }
      })

      choices <- setNames(choice_values, choice_labels)

      # Determine which selection to use (isolate dropdown to avoid circular updates)
      current_selection <- isolate(input$object_selector)

      if (!is.null(canvas_pid) && !is.na(canvas_pid) && as.character(canvas_pid) %in% choices) {
        # Use canvas selection if available
        updateSelectInput(session, "object_selector", choices = c("Select..." = "", choices), selected = as.character(canvas_pid))
      } else if (!is.null(current_selection) && current_selection != "" && current_selection %in% choices) {
        # Keep current dropdown selection if canvas selection is not available
        updateSelectInput(session, "object_selector", choices = c("Select..." = "", choices), selected = current_selection)
      } else {
        # No valid selection
        updateSelectInput(session, "object_selector", choices = c("Select..." = "", choices))
      }
      cat("[", id, "] Object selector updated with", length(choices), "choices\n")
    })

    # Handle object selector selection (when dropdown changed)
    observeEvent(input$object_selector, {
      selection <- input$object_selector

      if (is.null(selection) || selection == "") {
        return()
      }

      # Check if this is a silo without placement (starts with "silo_")
      if (grepl("^silo_", selection)) {
        # Don't try to select on canvas, just clear selection
        selected_placement_id(NA)
        return()
      }

      # It's a real placement ID
      placement_id <- selection

      # Check if this selection was triggered by canvas click (don't center in that case)
      source <- isolate(selection_source())

      # Get placement layout and coordinates
      query <- sprintf("SELECT LayoutID, CenterX, CenterY FROM SiloPlacements WHERE PlacementID = %s", placement_id)
      layout_data <- try(DBI::dbGetQuery(db_pool(), query), silent = TRUE)

      if (inherits(layout_data, "try-error") || nrow(layout_data) == 0) {
        return()
      }

      placement_layout_id <- layout_data$LayoutID[1]
      current_layout <- current_layout_id()

      # Only select on canvas if same layout
      if (placement_layout_id == current_layout) {
        selected_placement_id(as.integer(placement_id))
        trigger_refresh(trigger_refresh() + 1)

        # Center canvas on the selected shape (only if selection did NOT come from canvas click)
        if (source != "canvas") {
          center_x <- as.numeric(layout_data$CenterX[1])
          center_y <- as.numeric(layout_data$CenterY[1])
          session$sendCustomMessage(paste0(ns("root"), ":centerOnShape"), list(x = center_x, y = center_y))
        }
      }

      # Reset source to dropdown for next time
      selection_source("dropdown")
    }, ignoreInit = TRUE)

    # Render layout warning banner
    output$layout_warning_banner <- renderUI({
      selection <- input$object_selector

      if (is.null(selection) || selection == "") return(NULL)

      # Check if this is a silo without placement
      if (grepl("^silo_", selection)) {
        return(div(
          style = "background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; padding: 0.75rem; margin: 0.5rem 1rem; border-radius: 4px;",
          tags$i(class = "fas fa-info-circle", style = "margin-right: 0.5rem;"),
          "This silo does not have a placement on the current layout yet"
        ))
      }

      # Get layout info for existing placement
      query <- sprintf("
        SELECT l.LayoutName, p.LayoutID
        FROM SiloPlacements p
        INNER JOIN CanvasLayouts l ON p.LayoutID = l.LayoutID
        WHERE p.PlacementID = %s
      ", selection)

      placement_data <- try(DBI::dbGetQuery(db_pool(), query), silent = TRUE)

      if (inherits(placement_data, "try-error") || nrow(placement_data) == 0) return(NULL)

      current_layout <- current_layout_id()
      layout_name <- placement_data$LayoutName[1]
      placement_layout_id <- placement_data$LayoutID[1]

      if (placement_layout_id != current_layout) {
        div(
          style = "background: #fff3cd; border: 1px solid #ffc107; color: #856404; padding: 0.75rem; margin: 0.5rem 1rem; border-radius: 4px;",
          tags$i(class = "fas fa-info-circle", style = "margin-right: 0.5rem;"),
          sprintf("Use %s layout to see this placement on canvas", layout_name)
        )
      }
    })

    # Render object details
    output$object_details <- renderUI({
      selection <- input$object_selector

      if (is.null(selection) || selection == "") {
        return(div(style = "padding: 2rem; text-align: center; color: #999;", "Select a silo to view details"))
      }

      # Check if this is a silo without placement
      if (grepl("^silo_", selection)) {
        silo_id <- sub("^silo_", "", selection)

        # Get silo details only
        query <- sprintf("
          SELECT
            s.SiloCode,
            s.SiloName,
            s.VolumeM3,
            s.Notes AS SiloNotes,
            ct.TypeCode AS ContainerTypeCode,
            ct.TypeName AS ContainerTypeName,
            ct.Description AS ContainerDescription,
            sa.AreaCode,
            sa.AreaName,
            si.SiteCode,
            si.SiteName
          FROM Silos s
          INNER JOIN ContainerTypes ct ON s.ContainerTypeID = ct.ContainerTypeID
          LEFT JOIN SiteAreas sa ON s.AreaID = sa.AreaID
          LEFT JOIN Sites si ON s.SiteID = si.SiteID
          WHERE s.SiloID = %s
        ", silo_id)

        data <- try(DBI::dbGetQuery(db_pool(), query), silent = TRUE)

        if (inherits(data, "try-error") || nrow(data) == 0) {
          return(div("Error loading silo details"))
        }

        return(tagList(
          # Silo details (no placement info)
          div(style = "padding: 0.5rem 1rem; border-left: 3px solid #dee2e6; margin-bottom: 1rem;",
            tags$h4(paste0(data$SiloCode, " - ", data$SiloName)),
            tags$p(tags$strong("Site: "), ifelse(!is.na(data$SiteName), data$SiteName, "N/A")),
            tags$p(tags$strong("Area: "), ifelse(!is.na(data$AreaName), data$AreaName, "N/A")),
            tags$p(tags$strong("Type: "), paste0(data$ContainerTypeCode, " - ", data$ContainerTypeName)),
            tags$p(tags$strong("Volume: "), paste0(data$VolumeM3, " m³")),
            if (!is.na(data$SiloNotes) && nzchar(data$SiloNotes)) {
              tags$p(tags$strong("Notes: "), data$SiloNotes)
            }
          )
        ))
      }

      # Get full details for placement
      query <- sprintf("
        SELECT
          p.CenterX,
          p.CenterY,
          s.SiloCode,
          s.SiloName,
          s.VolumeM3,
          s.Notes AS SiloNotes,
          ct.TypeCode AS ContainerTypeCode,
          ct.TypeName AS ContainerTypeName,
          ct.Description AS ContainerDescription,
          st.TemplateCode,
          sa.AreaCode,
          sa.AreaName,
          si.SiteCode,
          si.SiteName
        FROM SiloPlacements p
        INNER JOIN Silos s ON p.SiloID = s.SiloID
        INNER JOIN ContainerTypes ct ON s.ContainerTypeID = ct.ContainerTypeID
        INNER JOIN ShapeTemplates st ON p.ShapeTemplateID = st.ShapeTemplateID
        LEFT JOIN SiteAreas sa ON s.AreaID = sa.AreaID
        LEFT JOIN Sites si ON s.SiteID = si.SiteID
        WHERE p.PlacementID = %s
      ", selection)

      data <- try(DBI::dbGetQuery(db_pool(), query), silent = TRUE)

      if (inherits(data, "try-error") || nrow(data) == 0) {
        return(div("Error loading placement details"))
      }

      tagList(
        # Placement section (collapsed)
        tags$details(
          tags$summary(style = "font-weight: bold; cursor: pointer; padding: 0.5rem; background: #f8f9fa; border-radius: 4px; margin-bottom: 0.5rem;",
            "Placement"
          ),
          div(style = "padding: 0.5rem 1rem; border-left: 3px solid #dee2e6; margin-bottom: 1rem;",
            tags$p(tags$strong("Shape: "), data$TemplateCode),
            tags$p(tags$strong("Center X: "), round(data$CenterX, 2)),
            tags$p(tags$strong("Center Y: "), round(data$CenterY, 2))
          )
        ),

        # Silo section (expanded by default)
        tags$details(
          open = "open",
          tags$summary(style = "font-weight: bold; cursor: pointer; padding: 0.5rem; background: #f8f9fa; border-radius: 4px; margin-bottom: 0.5rem;",
            "Silo"
          ),
          div(style = "padding: 0.5rem 1rem; border-left: 3px solid #dee2e6; margin-bottom: 1rem;",
            tags$p(tags$strong("Code: "), data$SiloCode),
            tags$p(tags$strong("Name: "), data$SiloName),
            tags$p(tags$strong("Container Type: "), data$ContainerTypeName),
            tags$p(tags$strong("Volume (m³): "), data$VolumeM3),
            if (!is.na(data$SiloNotes) && nchar(data$SiloNotes) > 0) {
              tags$p(tags$strong("Description: "), data$SiloNotes)
            },
            tags$p(tags$strong("Area: "), paste0(data$AreaCode, " - ", data$AreaName)),
            tags$p(tags$strong("Site: "), paste0(data$SiteCode, " - ", data$SiteName))
          )
        ),

        # Container Type section (collapsed)
        tags$details(
          tags$summary(style = "font-weight: bold; cursor: pointer; padding: 0.5rem; background: #f8f9fa; border-radius: 4px; margin-bottom: 0.5rem;",
            "Container Type"
          ),
          div(style = "padding: 0.5rem 1rem; border-left: 3px solid #dee2e6; margin-bottom: 1rem;",
            tags$p(tags$strong("Type Code: "), data$ContainerTypeCode),
            tags$p(tags$strong("Type Name: "), data$ContainerTypeName),
            if (!is.na(data$ContainerDescription) && nchar(data$ContainerDescription) > 0) {
              tags$p(tags$strong("Description: "), data$ContainerDescription)
            }
          )
        )
      )
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
            "No unallocated siloes available at this site. Please create one and try again."
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
                if (Shiny && Shiny.setInputValue) {
                  Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
                }
              }
            });

            // Handle change events (from arrows or blur)
            $('#%s, #%s').on('change', function(e) {
              if (!isTyping) {
                // Change from arrows, Enter, or blur after typing elsewhere
                if (Shiny && Shiny.setInputValue) {
                  Shiny.setInputValue('%s', Math.random(), {priority: 'event'});
                }
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
      # If there's pending placement BUT no pending duplicate, clear it
      if (!is.null(pending_placement()) && is.null(pending_duplicate_data())) {
        pending_placement(NULL)
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())
      }
      # Reset to placement mode if in silo mode
      if (panel_mode() == "silo") {
        panel_mode("placement")
      }
    }, ignoreInit = TRUE)

    # Watch for panel mode changes - restore duplicate move mode after silo creation
    observeEvent(panel_mode(), {
      # If switching back to placement mode and there's pending duplicate data
      if (panel_mode() == "placement" && !is.null(pending_duplicate_data())) {
        dup_data <- pending_duplicate_data()

        # Restore temp shape on canvas
        session$sendCustomMessage(paste0(ns("root"), ":setTempShape"), list(shape = dup_data$temp_shape))

        # Re-enter move mode
        enter_move_mode(dup_data$placement_id, dup_data$offset_x, dup_data$offset_y, is_duplicate = TRUE)

        # Keep pending placement for form population
        # Don't clear it yet - user still needs to complete the duplicate

        showNotification("Position the duplicate, then confirm", type = "message", duration = 4)
      }
    }, ignoreInit = TRUE)

    # Handle warning banner "Create New Silo" button
    observeEvent(input$create_silo_btn, {
      show_silo_warning(FALSE)  # Hide warning

      # Ensure all pending data is cleared - user starts from scratch
      pending_placement(NULL)
      pending_duplicate_data(NULL)
      selected_placement_id(NA)
      panel_mode("silo")

      # Open panel in silo mode (panel is already closed when warning is shown)
      shinyjs::runjs(sprintf("window.togglePanel_%s(true);", gsub("-", "_", ns("root"))))
    }, ignoreInit = TRUE)

    # Handle warning banner "Cancel" button
    observeEvent(input$cancel_warning_btn, {
      show_silo_warning(FALSE)  # Hide warning
      # Clear any pending placement and duplicate data
      pending_placement(NULL)
      pending_duplicate_data(NULL)
      session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

      # Exit move mode if active
      if (move_mode_state()) {
        exit_move_mode(reset_position = TRUE)
      }
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

      # If no silos available, ABORT the process - show warning and do NOT create placement
      if (nrow(available_silos) == 0) {
        cat("[Canvas] No silos available - aborting add placement process\n")

        # Clear any temp shapes on canvas
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

        # Reset cursor to default (user is no longer in add mode)
        session$sendCustomMessage(paste0(ns("root"), ":setShapeCursor"), list(
          shapeType = "default"
        ))

        # Turn off edit mode
        if (edit_mode_state()) {
          edit_mode_state(FALSE)
          shinyjs::removeClass("edit_mode_toggle", "active")
          session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = FALSE))
        }

        # Clear all pending data - user must restart after creating silo
        pending_placement(NULL)
        pending_duplicate_data(NULL)
        selected_placement_id(NA)
        panel_mode("silo")

        # Show warning banner
        show_silo_warning(TRUE)
        return()
      }

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

    # Handle Move button (toolbar)
    observeEvent(input$move, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to move", type = "warning", duration = 2)
        return()
      }

      # Get current placement data
      df <- try(get_placement_by_id(pid), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      # Auto-enable edit mode if not already on
      if (!edit_mode_state()) {
        edit_mode_state(TRUE)
        shinyjs::addClass("edit_mode_toggle", "active")
        session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
      }

      # Close right panel if open
      shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

      # Enter move mode using reusable function
      enter_move_mode(pid, df$CenterX, df$CenterY, is_duplicate = FALSE)
    })

    # Handle Move button (right panel)
    observeEvent(input$panel_move, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to move", type = "warning", duration = 2)
        return()
      }

      # Get current placement data
      df <- try(get_placement_by_id(pid), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      # Auto-enable edit mode if not already on
      if (!edit_mode_state()) {
        edit_mode_state(TRUE)
        shinyjs::addClass("edit_mode_toggle", "active")
        session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
      }

      # Close right panel
      shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

      # Enter move mode using reusable function
      enter_move_mode(pid, df$CenterX, df$CenterY, is_duplicate = FALSE)
    })

    # Handle Duplicate button (right panel)
    observeEvent(input$panel_duplicate, {
      pid <- selected_placement_id()
      if (is.null(pid) || is.na(pid)) {
        showNotification("Select a placement to duplicate", type = "warning", duration = 2)
        return()
      }

      # Auto-enable edit mode if not already on
      if (!edit_mode_state()) {
        edit_mode_state(TRUE)
        shinyjs::addClass("edit_mode_toggle", "active")
        session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
      }

      # Check if spare silos are available before proceeding
      all_silos <- silos_data()
      placements <- raw_placements()

      # Filter out already-placed silos (need a DIFFERENT silo for duplicate)
      available_silos <- all_silos
      if (nrow(available_silos) > 0 && nrow(placements) > 0) {
        placed_silo_ids <- placements$SiloID
        available_silos <- available_silos[!available_silos$SiloID %in% placed_silo_ids, ]
      }

      # If no silos available, close panel and show error
      if (nrow(available_silos) == 0) {
        # Close right panel
        shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

        # Clear any temp shapes on canvas
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

        # Clear all pending data - abort the duplicate process completely
        pending_placement(NULL)
        pending_duplicate_data(NULL)
        selected_placement_id(NA)
        panel_mode("silo")

        # Show warning on the banner
        show_silo_warning(TRUE)
        return()
      }

      # Close right panel
      shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

      # Trigger the main duplicate handler (reuse existing logic)
      # This is equivalent to clicking the toolbar duplicate button
      shinyjs::click("duplicate")
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
      exit_move_mode(reset_position = TRUE)
    })

    # Handle Confirm Placement button
    observeEvent(input$move_confirm, {
      original <- move_original_position()
      current <- move_current_position()
      is_dup <- move_is_duplicate()

      if (is.null(original) || is.null(current)) return()

      # Get placement data
      df <- try(get_placement_by_id(original$id), silent = TRUE)
      if (inherits(df, "try-error") || !nrow(df)) return()

      if (is_dup) {
        # DUPLICATE OPERATION: Prepare pending data (don't save yet - user must select silo and enter name)
        pending_data <- list(
          LayoutID = df$LayoutID,
          ShapeTemplateID = df$ShapeTemplateID,
          CenterX = current$x,
          CenterY = current$y,
          ZIndex = df$ZIndex,
          IsVisible = df$IsVisible,
          IsInteractive = df$IsInteractive
          # Note: No SiloID - user must select a different silo
          # Note: No Name - user must enter name
        )

        # Store as pending placement
        pending_placement(pending_data)

        # Clear temp shape
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

        # Set to "add new" mode (NA means creating new placement)
        selected_placement_id(NA)

        # Exit move mode but keep edit mode enabled
        move_mode_state(FALSE)
        move_original_position(NULL)
        move_current_position(NULL)
        move_is_duplicate(FALSE)

        # Clear pending duplicate data (duplicate is now confirmed)
        pending_duplicate_data(NULL)

        # Clear canvas selection
        session$sendCustomMessage(paste0(ns("root"), ":setData"), list(
          data = list(),
          autoFit = FALSE,
          selectedId = NULL
        ))

        # Refresh to show placements without temp shape
        trigger_refresh(trigger_refresh() + 1)

        # Open panel in edit mode with pending data (only if silo warning is not showing)
        if (!show_silo_warning()) {
          shinyjs::runjs(sprintf("window.togglePanel_%s(true);", gsub("-", "_", ns("root"))))
          showNotification("Select silo, enter name, and save", type = "message", duration = 3)
        } else {
          showNotification("Create silo first, then complete the duplicate", type = "warning", duration = 4)
        }
      } else {
        # NORMAL MOVE: Update existing placement position
        df$CenterX <- current$x
        df$CenterY <- current$y

        tryCatch({
          upsert_placement(as.list(df))

          # Remove dotted border
          session$sendCustomMessage(paste0(ns("root"), ":setMoveMode"), list(
            shapeId = as.character(original$id),
            enabled = FALSE
          ))

          # Exit move mode and edit mode
          move_mode_state(FALSE)
          move_original_position(NULL)
          move_current_position(NULL)

          edit_mode_state(FALSE)
          shinyjs::removeClass("edit_mode_toggle", "active")
          session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = FALSE))

          # Refresh canvas
          trigger_refresh(trigger_refresh() + 1)

          showNotification("Placement moved successfully", type = "message", duration = 2)
        }, error = function(e) {
          notify_error("Error moving placement", e)
        })
      }
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

      # Auto-enable edit mode if not already on
      if (!edit_mode_state()) {
        edit_mode_state(TRUE)
        shinyjs::addClass("edit_mode_toggle", "active")
        session$sendCustomMessage(paste0(ns("root"), ":setEditMode"), list(on = TRUE))
      }

      # Check if spare silos are available
      all_silos <- silos_data()
      placements <- raw_placements()

      # Filter out already-placed silos (need a DIFFERENT silo for duplicate)
      available_silos <- all_silos
      if (nrow(available_silos) > 0 && nrow(placements) > 0) {
        placed_silo_ids <- placements$SiloID
        # MUST be a different silo (don't allow reusing same silo due to UNIQUE constraint)
        available_silos <- available_silos[!available_silos$SiloID %in% placed_silo_ids, ]
      }

      # If no silos available, show warning banner and DO NOT initiate duplicate
      if (nrow(available_silos) == 0) {
        # Close right panel if open (so warning bar is not obstructed)
        shinyjs::runjs(sprintf("window.togglePanel_%s(false);", gsub("-", "_", ns("root"))))

        # Clear any temp shapes on canvas
        session$sendCustomMessage(paste0(ns("root"), ":clearTempShape"), list())

        # Clear all pending data - abort the duplicate process completely
        pending_placement(NULL)
        pending_duplicate_data(NULL)
        selected_placement_id(NA)
        panel_mode("silo")

        # Show warning banner - do not enter move mode, do not show temp shape
        show_silo_warning(TRUE)
        return()
      }

      # Get shape template to build temp shape
      template <- try(get_shape_template_by_id(df$ShapeTemplateID), silent = TRUE)
      if (inherits(template, "try-error") || !nrow(template)) return()

      shape_type <- template$ShapeType[1]

      # Calculate offset position (minimal offset of 20px)
      offset_x <- as.numeric(df$CenterX) + 20
      offset_y <- as.numeric(df$CenterY) + 20

      # Build temp shape for canvas
      temp_shape <- if (shape_type == "CIRCLE") {
        radius <- as.numeric(f_or(template$Radius[1], 20))
        list(
          type = "circle",
          x = offset_x,
          y = offset_y,
          r = radius,
          label = "DUPL"
        )
      } else if (shape_type == "RECTANGLE") {
        width <- as.numeric(f_or(template$Width[1], 40))
        height <- as.numeric(f_or(template$Height[1], 40))
        list(
          type = "rect",
          x = offset_x - width / 2,
          y = offset_y - height / 2,
          w = width,
          h = height,
          label = "DUPL"
        )
      } else if (shape_type == "TRIANGLE") {
        radius <- as.numeric(f_or(template$Radius[1], 20))
        list(
          type = "triangle",
          x = offset_x,
          y = offset_y,
          r = radius,
          label = "DUPL"
        )
      }

      # Show temp shape on canvas
      session$sendCustomMessage(paste0(ns("root"), ":setTempShape"), list(shape = temp_shape))

      # Enter move mode with duplicate flag
      enter_move_mode(pid, offset_x, offset_y, is_duplicate = TRUE)

      showNotification("Position the duplicate, then confirm", type = "message", duration = 3)
    })


    # ---- Canvas interactions ----

    # Handle canvas selection (namespace auto-applied: listen for canvas_selection not test_canvas_selection)
    observeEvent(input$canvas_selection, {
      sel_id <- input$canvas_selection
      if (!is.null(sel_id) && nzchar(sel_id)) {
        # Mark that this selection came from canvas
        selection_source("canvas")
        selected_placement_id(as.integer(sel_id))

        # Don't open panel if in move mode or if silo warning is showing
        if (move_mode_state() || show_silo_warning()) {
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

    # Handle canvas move (only in move mode)
    observeEvent(input$canvas_moved, {
      moved <- input$canvas_moved
      if (is.null(moved)) return()

      # Only handle if in move mode - edit mode no longer allows drag-to-move
      # Use Move button to enter move mode instead
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
      }
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
        canvas_id = as_optional_integer(canvas_id),
        site_id = as_optional_integer(site_id),
        rotation = rotation,
        pan_x = offset$x,
        pan_y = offset$y,
        scale_x = scale,  # Uniform scaling
        scale_y = scale   # Same for both axes
      ), silent = TRUE)

      # Save canvas area (area is part of canvas, not layout)
      if (!is.null(canvas_id) && !is.na(canvas_id) && canvas_id != "") {
        area_result <- try(update_canvas_area(
          as.integer(canvas_id),
          as_optional_integer(area_id)
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

      # Skip if no template selected
      if (is.null(template_id) || template_id == "") {
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
      session$sendCustomMessage(paste0(ns("root"), ":updateShape"), list(shape = updated_shape))
    }, ignoreInit = TRUE)

    # Initial load - trigger first refresh (run once only)
    observeEvent(session$clientData$url_hostname, once = TRUE, {
      trigger_refresh(trigger_refresh() + 1)
    })

  })
}

# Standalone runner
# Test runner (for standalone testing - not needed in main app)
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
    browser_siloplacements_ui("test")
  )

  server <- function(input, output, session) {
    browser_siloplacements_server("test", pool = db_pool())
  }

  cat("\n=== Launching SiloPlacements Canvas Test ===\n")
  cat("Canvas + React Table for placement management\n\n")

  # Add resource paths for www directory
  shiny::addResourcePath("js", "www/js")
  shiny::addResourcePath("css", "www/css")

  shinyApp(ui, server, options = list(launch.browser = TRUE))
}
