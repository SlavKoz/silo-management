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
    # Bootstrap 5 from CDN (for form styling)
    tags$link(rel = "stylesheet",
              href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"),

    # Bootstrap Icons for edit/save button
    tags$link(rel = "stylesheet",
              href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css"),

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
        padding: 0.75rem;
        background: #f8f9fa;
        border-radius: 0.375rem;
        border: 1px solid #dee2e6;
        margin: 0 0 1rem 0;
      }

      #%s .form-control-title {
        border: none !important;
        background: transparent !important;
        padding: 0 !important;
        font-size: 1.75rem !important;
        font-weight: 700;
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
        padding: 0.5rem 1rem;
        background: #e9ecef;
        border: 1px solid #dee2e6;
        border-radius: 0.375rem;
        font-size: 14px;
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

      /* Field labels - small and not bold */
      #%s .col-form-label {
        font-size: 11px !important;
        font-weight: normal !important;
      }

      /* Static fields - no frame */
      #%s .form-static-value {
        font-size: 10px !important;
        color: #6c757d;
        line-height: 1.25rem;
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
       ns("form"), ns("form"), ns("form")))),

    # JavaScript for edit/save toggle - scoped to this module instance
    tags$script(HTML(sprintf("
      (function() {
        const moduleId = '%s';

        window['toggleEditMode_%s'] = function(btn) {
          const container = document.getElementById(moduleId);
          if (!container) return;

          const isEditing = btn.classList.contains('editing');

          if (isEditing) {
            // Switch to locked mode
            btn.classList.remove('editing');
            btn.innerHTML = '<i class=\"bi bi-pencil-square\"></i><span> Edit</span>';
            container.classList.remove('edit-mode');

            // Make title readonly
            const titleInput = container.querySelector('.form-control-title');
            if (titleInput) titleInput.setAttribute('readonly', 'readonly');

            // Disable all form inputs
            container.querySelectorAll('.form-container input:not(.form-control-title), .form-container select, .form-container textarea').forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });
          } else {
            // Switch to editing mode
            btn.classList.add('editing');
            btn.innerHTML = '<i class=\"bi bi-floppy\"></i><span> Save</span>';
            container.classList.add('edit-mode');

            // Header title always stays readonly (never editable)

            // Enable all form inputs (except static ones and header title)
            container.querySelectorAll('.form-container input:not(.form-control-title), .form-container select, .form-container textarea').forEach(el => {
              if (!el.closest('.form-static-value')) {
                el.removeAttribute('readonly');
                el.removeAttribute('disabled');
              }
            });
          }
        };

        // Initialize in locked mode when content loads
        const observer = new MutationObserver(function(mutations) {
          const container = document.getElementById(moduleId);
          if (container && container.querySelector('.form-container')) {
            container.querySelectorAll('.form-container input:not(.form-control-title), .form-container select, .form-container textarea').forEach(el => {
              el.setAttribute('readonly', 'readonly');
              el.setAttribute('disabled', 'disabled');
            });
            observer.disconnect();
          }
        });

        const targetNode = document.getElementById(moduleId);
        if (targetNode) {
          observer.observe(targetNode, { childList: true, subtree: true });
        }
      })();
    ", ns("form"), gsub("-", "_", id)))),

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
#'
#' @return Module server function
mod_html_form_server <- function(id, schema_config, form_data,
                                  title_field = NULL, show_header = TRUE) {
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
        groups = config$groups %||% list(),
        title = NULL,
        columns = config$columns %||% 2,
        widgets = config$widgets %||% list(),
        static_fields = config$static_fields %||% character(0)
      )
    })

    # Get form data (reactive or static)
    data <- reactive({
      if (is.reactive(form_data)) form_data() else form_data
    })

    # Render form with header
    output$form_content <- renderUI({
      render_html_form(
        schema = compiled_schema()$schema,
        uiSchema = compiled_schema()$uiSchema,
        formData = data(),
        ns_prefix = ns("field_"),
        show_header = show_header,
        title_field = title_field,
        module_id = id  # Pass module ID for namespaced JavaScript
      )
    })

    # Return list of reactive values and functions for parent to use
    list(
      get_data = data,
      get_schema = compiled_schema
    )
  })
}
