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
    tags$style(HTML(sprintf("
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
    ", ns("form"), ns("form"), ns("form"), ns("form"), ns("form"),
       ns("form"), ns("form"), ns("form"), ns("form"), ns("form"),
       ns("form"), ns("form"), ns("form"), ns("form"), ns("form"),
       ns("form"), ns("form"), ns("form"), ns("form"), ns("form"),
       ns("form"), ns("form"), ns("form"), ns("form"), ns("form"),
       ns("form"), ns("form"), ns("form"), ns("form"), ns("form")))),

    # JavaScript for edit/save toggle - scoped to this module instance
    tags$script(HTML(sprintf("
      (function() {
        const moduleId = '%s';

        window['toggleEditMode_%s'] = function(btn) {
          const container = document.getElementById(moduleId);
          if (!container) {
            console.error('[toggleEditMode] Container not found:', moduleId);
            return;
          }

          const isEditing = btn.classList.contains('editing');
          console.log('[toggleEditMode] Current state:', isEditing ? 'editing' : 'locked');

          if (isEditing) {
            // Switch to locked mode
            btn.classList.remove('editing');
            btn.innerHTML = '<i class=\"bi bi-pencil-square\"></i><span> Edit</span>';
            container.classList.remove('edit-mode');

            // Make title readonly
            const titleInput = container.querySelector('.form-control-title');
            if (titleInput) titleInput.setAttribute('readonly', 'readonly');

            // Disable all form inputs - use more specific selectors
            const inputs = container.querySelectorAll('input:not(.form-control-title):not([type=\"button\"]):not([type=\"submit\"])');
            const selects = container.querySelectorAll('select');
            const textareas = container.querySelectorAll('textarea');

            [...inputs, ...selects, ...textareas].forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });

            console.log('[toggleEditMode] Locked', inputs.length + selects.length + textareas.length, 'elements');
          } else {
            // Switch to editing mode
            btn.classList.add('editing');
            btn.innerHTML = '<i class=\"bi bi-floppy\"></i><span> Save</span>';
            container.classList.add('edit-mode');

            // Header title always stays readonly (never editable)

            // Enable all form inputs (except static ones and header title)
            const inputs = container.querySelectorAll('input:not(.form-control-title):not([type=\"button\"]):not([type=\"submit\"])');
            const selects = container.querySelectorAll('select');
            const textareas = container.querySelectorAll('textarea');

            [...inputs, ...selects, ...textareas].forEach(el => {
              // Skip static fields
              if (!el.closest('.form-static-value') && !el.hasAttribute('data-static')) {
                el.removeAttribute('readonly');
                el.removeAttribute('disabled');
              }
            });

            console.log('[toggleEditMode] Unlocked', inputs.length + selects.length + textareas.length, 'elements');
          }
        };

        // Delete confirmation function
        window['confirmDelete_%s'] = function(btn) {
          if (btn.disabled) return;

          const container = document.getElementById(moduleId);
          if (!container) return;

          const titleInput = container.querySelector('.form-control-title');
          const itemName = titleInput ? titleInput.value : 'this item';

          if (confirm('Are you sure you want to delete ' + itemName + '?\\n\\nThis action cannot be undone.')) {
            // Trigger Shiny input event
            if (window.Shiny) {
              Shiny.setInputValue(moduleId.replace('-form', '') + '-form-delete_confirmed', Date.now(), {priority: 'event'});
            }
          }
        };

        // Function to update delete button state
        window['setDeleteButtonState_%s'] = function(disabled) {
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

        // Initialize in locked mode when content loads
        const observer = new MutationObserver(function(mutations) {
          const container = document.getElementById(moduleId);
          if (container && container.querySelector('.form-container')) {
            // Lock all inputs
            container.querySelectorAll('.form-container input:not(.form-control-title), .form-container select, .form-container textarea').forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });

            // Check if title is empty (indicates add new mode)
            const titleInput = container.querySelector('.form-control-title');
            const isEmpty = !titleInput || !titleInput.value || titleInput.value.trim() === '';

            // Disable delete button if empty
            const deleteBtn = container.querySelector('.btn-delete');
            if (deleteBtn && isEmpty) {
              deleteBtn.setAttribute('disabled', 'disabled');
            }

            observer.disconnect();
          }
        });

        const targetNode = document.getElementById(moduleId);
        if (targetNode) {
          observer.observe(targetNode, { childList: true, subtree: true });
        }
      })();
    ", ns("form"), gsub("-", "_", ns("form")), gsub("-", "_", ns("form")), gsub("-", "_", ns("form"))))),

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
#'
#' @return Module server function
mod_html_form_server <- function(id, schema_config, form_data,
                                  title_field = NULL, show_header = TRUE,
                                  show_delete_button = TRUE) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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

      # Determine if delete button should be disabled
      # Disable if in "add new" mode (title field is empty/NA)
      is_add_new <- if (!is.null(title_field)) {
        title_val <- current_data[[title_field]]
        is.null(title_val) || is.na(title_val) || identical(title_val, "")
      } else {
        FALSE
      }

      render_html_form(
        schema = compiled_schema()$schema,
        uiSchema = compiled_schema()$uiSchema,
        formData = current_data,
        ns_prefix = ns("field_"),
        show_header = show_header,
        title_field = title_field,
        module_id = ns("form"),
        show_footer = show_delete_button,  # Show footer only if delete button enabled
        delete_disabled = is_add_new  # Disable if in add new mode
      )
    })

    # Return list of reactive values and functions for parent to use
    list(
      get_data = data,
      get_schema = compiled_schema
    )
  })
}
