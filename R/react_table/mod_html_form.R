# R/react_table/mod_html_form.R
# Generic HTML Form Module - Reusable across application
# Supports multiple instances on the same tab via proper namespacing

#' HTML Form Module UI
#'
#' @param id Character string for module namespace
#' @param max_width Maximum width of form container (default: "1200px")
#' @param margin Margin around form (default: "2rem auto")
#'
#' @return Shiny UI elements
mod_html_form_ui <- function(id, max_width = "1200px", margin = "2rem auto") {
  ns <- NS(id)

  tagList(
    # Bootstrap 5 from CDN (for form styling) - singleton to load once
    shiny::singleton(tags$head(
      tags$link(rel = "stylesheet",
                href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"),
      tags$link(rel = "stylesheet",
                href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css")
    )),

    # Font protection and styling CSS - scoped to this module instance
    {
      css_template <- "
      #%s .form-container {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif !important;
        font-size: 14px !important;
        padding: 1rem;
      }

      #%s .form-container input,
      #%s .form-container select,
      #%s .form-container textarea {
        font-size: 11px !important;
      }

      #%s .form-container textarea {
        font-size: 11px !important;
      }

      /* Compact inputs */
      #%s .form-control,
      #%s .form-select {
        padding: .25rem .5rem !important;
        height: 2rem !important;
        line-height: 1.25rem !important;
      }

      #%s textarea.form-control {
        height: auto !important;
      }

      #%s .form-control-color {
        width: 3rem;
        height: 2rem !important;
      }

      /* Form wrapper - outer container */
      #%s .form-wrapper {
        background: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }

      /* Fix Bootstrap row negative margins inside wrapper */
      #%s .form-wrapper .row {
        margin-left: 0 !important;
        margin-right: 0 !important;
      }

      /* Header styling */
      #%s .form-header {
        padding: 0.375rem;
        background: #f8f9fa;
        border-radius: 0.375rem;
        border: 1px solid #dee2e6;
        margin: 0 0 1rem 0;
      }

      #%s .form-control-title {
        border: none !important;
        background: transparent !important;
        padding: 0 !important;
        font-size: 3rem !important;
        font-weight: 900;
        color: #2563eb !important;
        text-transform: uppercase !important;
        height: auto !important;
        box-shadow: none !important;
        outline: none !important;
      }

      #%s .form-control-title:read-only {
        cursor: default;
        color: #2563eb !important;
      }

      /* Header title is always read-only (never editable) */

      #%s .btn-edit-toggle {
        padding: 0.25rem 0.5rem;
        background: #e9ecef;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        font-size: 12px;
        transition: all 0.2s;
      }

      #%s .btn-edit-toggle:hover {
        background: #dee2e6;
      }

      #%s .btn-edit-toggle.editing {
        background: #28a745;
        color: white;
        border-color: #28a745;
      }

      #%s .btn-edit-toggle.editing:hover {
        background: #218838;
      }

      /* Column dividers and spacing */
      #%s .border-end {
        border-right: 2px solid #dee2e6 !important;
        padding-right: 0.75rem !important;
        margin-right: 0.75rem !important;
      }

      /* Reduce spacing between inputs */
      #%s .mb-3 {
        margin-bottom: 0.5rem !important;
      }

      /* Field labels - small and not bold */
      #%s .col-form-label {
        font-size: 11px !important;
        font-weight: normal !important;
      }

      /* Footer styling */
      #%s .form-footer {
        padding: 0.375rem;
        background: #f8f9fa;
        border-radius: 0.375rem;
        border: 1px solid #dee2e6;
        margin: 1rem 0 0 0;
      }

      #%s .btn-delete {
        padding: 0.25rem 0.5rem;
        background: #dc3545;
        color: white;
        border: 1px solid #dc3545;
        border-radius: 0.25rem;
        font-size: 12px;
        transition: all 0.2s;
      }

      #%s .btn-delete:hover:not(:disabled) {
        background: #c82333;
        border-color: #bd2130;
      }

      #%s .btn-delete:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      /* Static fields - no frame */
      #%s .form-static-value {
        font-size: 10px !important;
        color: #6c757d;
        line-height: 1.25rem;
      }

      /* Group headers - same size as labels */
      #%s summary,
      #%s summary strong,
      #%s legend {
        font-size: 11px !important;
        font-weight: normal !important;
      }

      /* Fix details/summary in columns */
      #%s details {
        display: block;
        width: 100%%;
      }

      /* Icon Picker Custom - Visual dropdown with thumbnails */
      #%s .icon-picker-custom {
        position: relative;
        width: 100%%;
      }

      #%s .icon-picker-display {
        display: flex;
        align-items: center;
        padding: 0.25rem 0.5rem;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        background: white;
        cursor: pointer;
        min-height: 2rem;
      }

      #%s .icon-picker-display:hover {
        border-color: #adb5bd;
      }

      #%s .icon-picker-custom[data-disabled='true'] .icon-picker-display {
        background-color: #e9ecef !important;
        cursor: not-allowed !important;
        opacity: 0.6;
        pointer-events: none !important;
      }

      #%s .icon-picker-custom[data-disabled='false'] .icon-picker-display {
        cursor: pointer !important;
        pointer-events: auto !important;
      }

      #%s .dropdown-arrow::before {
        content: '▼';
        font-size: 0.7em;
        color: #6c757d;
      }

      #%s .icon-picker-dropdown {
        position: absolute;
        top: 100%%;
        left: 0;
        right: 0;
        max-height: 300px;
        overflow-y: auto;
        background: white;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        z-index: 1000;
        margin-top: 2px;
      }

      #%s .icon-option {
        display: flex;
        align-items: center;
        padding: 0.4rem 0.5rem;
        cursor: pointer;
        transition: background 0.2s;
      }

      #%s .icon-option:hover {
        background-color: #f8f9fa;
      }

      #%s .icon-option.selected {
        background-color: #e7f5ff;
      }

      #%s .icon-label {
        font-size: 11px;
      }
    "

      # Auto-count placeholders and generate args
      n_css <- length(gregexpr("%s", css_template, fixed = TRUE)[[1]])
      tags$style(HTML(do.call(sprintf, c(list(css_template), rep(list(ns("form")), n_css)))))
    },

    # JavaScript for edit/save toggle - scoped to this module instance
    # NOTE: Using paste0 instead of sprintf to avoid 8192 char format limit
    {
      module_id <- ns("form")
      module_id_js <- gsub("-", "_", module_id)

      js_code <- paste0("
      (function() {
        const moduleId = '", module_id, "';

        window['toggleEditMode_", module_id_js, "'] = function(btn) {
          const container = document.getElementById(moduleId);
          if (!container) {
            console.error('[toggleEditMode] Container not found:', moduleId);
            return;
          }

          const isEditing = btn.classList.contains('editing');

          if (isEditing) {
            // Trigger save event before switching to locked mode
            const baseNs = moduleId.substring(0, moduleId.lastIndexOf('-form'));
            const inputName = baseNs + '-save_clicked';
            if (window.Shiny && typeof Shiny.setInputValue === 'function') {
              Shiny.setInputValue(inputName, Date.now(), {priority: 'event'});
            }

            // Switch to locked mode
            btn.classList.remove('editing');
            btn.innerHTML = '<i class=\"bi bi-pencil-square\"></i><span> Edit</span>';
            container.classList.remove('edit-mode');

            // Make title readonly
            const titleInput = container.querySelector('.form-control-title');
            if (titleInput) titleInput.setAttribute('readonly', 'readonly');

            // Disable all form inputs - use more specific selectors
            const inputs = container.querySelectorAll('input:not(.form-control-title):not([type=\"button\"]):not([type=\"submit\"]):not([type=\"hidden\"])');
            const selects = container.querySelectorAll('select');
            const textareas = container.querySelectorAll('textarea');
            const iconPickers = container.querySelectorAll('.icon-picker-custom');

            [...inputs, ...selects, ...textareas].forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });

            // Disable icon pickers
            iconPickers.forEach(el => {
              el.setAttribute('data-disabled', 'true');
            });

          } else {
            // Switch to editing mode
            btn.classList.add('editing');
            btn.innerHTML = '<i class=\"bi bi-floppy\"></i><span> Save</span>';
            container.classList.add('edit-mode');

            // Signal to Shiny that edit mode was entered (to refresh dynamic selects)
            const baseNs = moduleId.substring(0, moduleId.lastIndexOf('-form'));
            const inputName = baseNs + '-edit_mode_entered';
            if (window.Shiny && typeof Shiny.setInputValue === 'function') {
              Shiny.setInputValue(inputName, Date.now(), {priority: 'event'});
            }

            // Header title always stays readonly (never editable)

            // Enable all form inputs (except static ones and header title)
            const inputs = container.querySelectorAll('input:not(.form-control-title):not([type=\"button\"]):not([type=\"submit\"]):not([type=\"hidden\"])');
            const selects = container.querySelectorAll('select');
            const textareas = container.querySelectorAll('textarea');
            const iconPickers = container.querySelectorAll('.icon-picker-custom');

            [...inputs, ...selects, ...textareas].forEach(el => {
              // Skip static fields
              if (!el.closest('.form-static-value') && !el.hasAttribute('data-static')) {
                el.removeAttribute('readonly');
                el.removeAttribute('disabled');
              }
            });

            // Enable icon pickers
            iconPickers.forEach(el => {
              if (!el.closest('.form-static-value') && !el.hasAttribute('data-static')) {
                el.setAttribute('data-disabled', 'false');
              }
            });
          }
        };

        // Delete confirmation function
        window['confirmDelete_", module_id_js, "'] = function(btn) {
          if (btn.disabled) return;

          const container = document.getElementById(moduleId);
          if (!container) return;

          const titleInput = container.querySelector('.form-control-title');
          const itemName = titleInput ? titleInput.value : 'this item';

          if (confirm('Are you sure you want to delete ' + itemName + '?\\n\\nThis action cannot be undone.')) {
            // Trigger Shiny input event
            const baseNs = moduleId.substring(0, moduleId.lastIndexOf('-form'));
            const inputName = baseNs + '-delete_confirmed';
            if (window.Shiny && typeof Shiny.setInputValue === 'function') {
              Shiny.setInputValue(inputName, Date.now(), {priority: 'event'});
            }
          }
        };

        // Function to update delete button state
        window['setDeleteButtonState_", module_id_js, "'] = function(disabled) {
          const container = document.getElementById(moduleId);
          if (!container) return;

          const deleteBtn = container.querySelector('.btn-delete');
          if (deleteBtn) {
            if (disabled) {
              deleteBtn.setAttribute('disabled', 'disabled');
            } else {
              deleteBtn.removeAttribute('disabled');
            }
          }
        };

        // Initialize icon pickers - function to be called when form loads
        function initializeIconPickers() {
          const container = document.getElementById(moduleId);
          if (!container) {
            console.warn('[icon-picker] Container not found:', moduleId);
            return;
          }

          const pickers = container.querySelectorAll('.icon-picker-custom');
          console.log('[icon-picker] Found', pickers.length, 'icon pickers');

          if (pickers.length === 0) {
            console.log('[icon-picker] No pickers found, will retry on form load');
            return;
          }

          pickers.forEach(function(picker) {
            // Skip if already initialized
            if (picker.hasAttribute('data-initialized')) {
              console.log('[icon-picker] Picker already initialized:', picker.id);
              return;
            }
            picker.setAttribute('data-initialized', 'true');

            const display = picker.querySelector('.icon-picker-display');
            const dropdown = picker.querySelector('.icon-picker-dropdown');
            const options = picker.querySelectorAll('.icon-option');

            if (!display || !dropdown) {
              console.warn('[icon-picker] Missing display or dropdown for picker:', picker.id);
              return;
            }

            // Toggle dropdown on display click
            const clickHandler = function(e) {
              e.preventDefault();
              e.stopPropagation();

              const isDisabled = picker.getAttribute('data-disabled') === 'true';

              if (isDisabled) {
                return;
              }

              const currentDisplay = window.getComputedStyle(dropdown).display;
              const isOpen = currentDisplay !== 'none';

              // Close all other dropdowns
              document.querySelectorAll('.icon-picker-dropdown').forEach(function(d) {
                d.style.display = 'none';
              });

              dropdown.style.display = isOpen ? 'none' : 'block';
            };

            display.addEventListener('click', clickHandler, true);

            // Option selection
            options.forEach(function(option) {
              option.addEventListener('click', function(e) {
                e.stopPropagation();
                const value = this.getAttribute('data-value');

                // Update picker value
                picker.setAttribute('data-value', value);

                // Update display
                display.innerHTML = this.innerHTML + '<i class=\"dropdown-arrow\" style=\"margin-left:auto;\"></i>';

                // Update selected class
                options.forEach(function(opt) {
                  opt.classList.remove('selected');
                });
                this.classList.add('selected');

                // Close dropdown
                dropdown.style.display = 'none';

                // Trigger Shiny input event
                if (window.Shiny && typeof Shiny.setInputValue === 'function') {
                  Shiny.setInputValue(picker.id, value, {priority: 'event'});
                }
              });
            });
          });

          // Close dropdowns when clicking outside
          document.addEventListener('click', function() {
            container.querySelectorAll('.icon-picker-dropdown').forEach(function(dropdown) {
              dropdown.style.display = 'none';
            });
          });
        }

        // Track last form wrapper to detect actual content changes (not just mutations within same form)
        let lastFormWrapper = null;

        // Initialize in locked mode when content loads
        const observer = new MutationObserver(function(mutations) {
          const container = document.getElementById(moduleId);
          const formWrapper = container ? container.querySelector('.form-wrapper') : null;

          // Check if this is genuinely new form content by comparing DOM reference
          if (formWrapper && formWrapper !== lastFormWrapper) {
            lastFormWrapper = formWrapper;

            // Lock all inputs (except hidden inputs)
            container.querySelectorAll('.form-container input:not(.form-control-title):not([type=\"hidden\"]), .form-container select, .form-container textarea').forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });

            // Lock icon pickers
            container.querySelectorAll('.icon-picker-custom').forEach(el => {
              el.setAttribute('data-disabled', 'true');
            });

            // Initialize hidden inputs with Shiny (they don't auto-bind)
            if (window.Shiny && typeof Shiny.setInputValue === 'function') {
              container.querySelectorAll('input[type=\"hidden\"]').forEach(function(hiddenInput) {
                if (hiddenInput.value && hiddenInput.id) {
                  Shiny.setInputValue(hiddenInput.id, hiddenInput.value);
                }
              });
            }

            // Check if title is empty (indicates add new mode)
            const titleInput = container.querySelector('.form-control-title');
            const isEmpty = !titleInput || !titleInput.value || titleInput.value.trim() === '';

            // Disable delete button if empty
            const deleteBtn = container.querySelector('.btn-delete');
            if (deleteBtn && isEmpty) {
              deleteBtn.setAttribute('disabled', 'disabled');
            }

            // Initialize icon pickers now that form content is loaded
            initializeIconPickers();

            // Don't disconnect - keep observing for form re-renders (e.g., when switching records)
            // The lastFormWrapper check prevents re-initialization of same content
          }
        });

        const targetNode = document.getElementById(moduleId);
        if (targetNode) {
          observer.observe(targetNode, { childList: true, subtree: true });
        }

        // Also try to initialize after a short delay (backup in case observer doesn't fire)
        setTimeout(initializeIconPickers, 500);

        // And try immediately in case form is already loaded
        setTimeout(initializeIconPickers, 50);
      })();
    ")

      tags$script(HTML(js_code))
    },

    div(id = ns("form"), style = sprintf("max-width: %s; margin: %s; padding: 0 1rem;", max_width, margin),
        div(class = "form-container",
            uiOutput(ns("form_content"))
        )
    )
  )
}

#' HTML Form Module Server
#'
#' @param id Character string for module namespace
#' @param schema_config Reactive or list containing form schema configuration:
#'   - fields: List of field definitions
#'   - groups: List of group definitions
#'   - columns: Number of columns (1-4)
#'   - static_fields: Vector of field paths to make static
#' @param form_data Reactive or list containing form data
#' @param title_field Character string for field to use as header title
#' @param show_header Logical, whether to show header (default: TRUE)
#' @param show_delete_button Logical, whether to show delete button (default: TRUE)
#' @param on_save Optional callback function(data) that handles saving. Should return TRUE on success.
#' @param on_delete Optional callback function() that handles deletion. Should return TRUE on success.
#'
#' @return List with:
#'   - saved_data: Reactive that fires when save completes, contains the saved data
#'   - deleted: Reactive that fires when delete completes
mod_html_form_server <- function(id, schema_config, form_data,
                                  title_field = NULL, show_header = TRUE,
                                  show_delete_button = TRUE,
                                  on_save = NULL, on_delete = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values to track save/delete events
    rv <- reactiveValues(
      saved_data = NULL,
      save_timestamp = NULL,
      deleted = FALSE,
      delete_timestamp = NULL,
      edit_refresh_trigger = 0  # Increments when edit mode is entered
    )

    # Observe edit mode entered event - used to refresh dynamic selects
    observeEvent(input$edit_mode_entered, {
      rv$edit_refresh_trigger <- rv$edit_refresh_trigger + 1
    }, ignoreInit = TRUE)

    # Load HTML renderer
    source("R/react_table/html_form_renderer.R", local = TRUE)

    # Load DSL if not already loaded
    if (!exists("rjsf_auto_compile", mode = "function")) {
      source("R/react_table/react_table_dsl.R", envir = .GlobalEnv)
      source("R/react_table/react_table_auto.R", envir = .GlobalEnv)
    }

    # Compile schema (reactive or static)
    compiled_schema <- reactive({
      config <- if (is.reactive(schema_config)) schema_config() else schema_config

      rjsf_auto_compile(
        fields = config$fields,
        groups = f_or(config$groups, list()),
        title = NULL,
        columns = f_or(config$columns, 2),
        widgets = f_or(config$widgets, list()),
        static_fields = f_or(config$static_fields, character(0))
      )
    })

    # Get form data (reactive or static)
    data <- reactive({
      if (is.reactive(form_data)) form_data() else form_data
    })

    # Render form with header
    output$form_content <- renderUI({
      current_data <- data()
      current_schema <- compiled_schema()  # Create dependency on schema changes

      # Determine if delete button should be disabled
      # Disable if in "add new" mode (title field is empty/NA)
      is_add_new <- if (!is.null(title_field)) {
        title_val <- current_data[[title_field]]
        is.null(title_val) || is.na(title_val) || identical(title_val, "")
      } else {
        FALSE
      }

      render_html_form(
        schema = current_schema$schema,
        uiSchema = current_schema$uiSchema,
        formData = current_data,
        ns_prefix = ns("field_"),
        show_header = show_header,
        title_field = title_field,
        module_id = ns("form"),
        show_footer = show_delete_button,  # Show footer only if delete button enabled
        delete_disabled = is_add_new  # Disable if in add new mode
      )
    })

    # Observe Save button click
    observeEvent(input$save_clicked, {
      if (is.null(on_save)) return()

      # Collect all form inputs
      schema <- compiled_schema()
      field_names <- names(schema$schema$properties)

      # Helper function to collect nested fields
      collect_fields <- function(prefix, prop_names) {
        result <- list()
        for (fname in prop_names) {
          input_id <- paste0("field_", if (nzchar(prefix)) paste0(prefix, ".", fname) else fname)
          input_value <- input[[input_id]]

          # Get schema for this field to check type
          field_path <- if (nzchar(prefix)) paste0(prefix, ".", fname) else fname
          field_schema <- schema$schema$properties[[fname]]

          # Handle nested objects
          if (!is.null(field_schema$properties)) {
            result[[fname]] <- collect_fields(field_path, names(field_schema$properties))
          } else {
            # Convert input value based on schema type
            if (!is.null(field_schema$type)) {
              if (field_schema$type == "number" || field_schema$type == "integer") {
                result[[fname]] <- if (!is.null(input_value) && nzchar(input_value)) as.numeric(input_value) else NULL
              } else {
                result[[fname]] <- input_value
              }
            } else {
              result[[fname]] <- input_value
            }
          }
        }
        result
      }

      collected_data <- collect_fields("", field_names)

      # Add any fields from original data that aren't in the schema (like IDs)
      original_data <- data()
      if (!is.null(original_data)) {
        for (field_name in names(original_data)) {
          # If field exists in original but not in collected, copy it over
          if (is.null(collected_data[[field_name]]) && !is.null(original_data[[field_name]])) {
            # Skip nested objects and only copy simple values
            if (!is.list(original_data[[field_name]])) {
              collected_data[[field_name]] <- original_data[[field_name]]
            }
          }
        }
      }

      # Call the on_save callback
      tryCatch({
        success <- on_save(collected_data)
        if (isTRUE(success)) {
          rv$saved_data <- collected_data
          rv$save_timestamp <- Sys.time()
        }
      }, error = function(e) {
        cat("[Save Error]:", conditionMessage(e), "\n")
      })
    }, ignoreInit = TRUE)

    # Observe Delete button click
    observeEvent(input$delete_confirmed, {
      if (!is.null(on_delete)) {
        tryCatch({
          success <- on_delete()
          if (isTRUE(success)) {
            rv$deleted <- TRUE
            rv$delete_timestamp <- Sys.time()
          }
        }, error = function(e) {
          cat("[mod_html_form] Delete error:", conditionMessage(e), "\n")
        })
      }
    }, ignoreInit = TRUE)

    # Return list of reactive values and functions for parent to use
    list(
      get_data = data,
      get_schema = compiled_schema,
      saved_data = reactive({ rv$save_timestamp; rv$saved_data }),
      deleted = reactive({ rv$delete_timestamp; rv$deleted }),
      edit_refresh_trigger = reactive({ rv$edit_refresh_trigger })  # For refreshing dynamic selects
    )
  })
}
