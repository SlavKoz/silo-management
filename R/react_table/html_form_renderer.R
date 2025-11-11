# R/react_table/html_form_renderer.R
# Pure R/HTML form renderer - no external JS dependencies
# Renders forms from DSL schema as native HTML

# Import htmltools functions
if (!exists("div", mode = "function")) {
  library(htmltools)
}

# Helper operator - use f_or if available, otherwise define
render_html_form <- function(schema, uiSchema, formData, ns_prefix = "", show_header = TRUE, title_field = NULL, module_id = NULL, show_footer = TRUE, on_delete = NULL, delete_disabled = FALSE) {
  if (is.null(schema) || is.null(schema$properties)) {
    return(div("No schema provided"))
  }

  # Get column count (1-4 columns supported)
  columns <- f_or(uiSchema[["ui:options"]]$columns, 1)
  columns <- max(1, min(4, columns))  # Clamp to 1-4

  # Get field order
  order <- f_or(uiSchema[["ui:order"]], names(schema$properties))

  # Split fields into columns
  fields <- schema$properties
  field_names <- intersect(order, names(fields))

  # Initialize column lists (1-4 columns)
  column_fields <- vector("list", columns)
  for (i in 1:columns) {
    column_fields[[i]] <- list()
  }

  # Distribute fields to columns
  for (fname in field_names) {
    field_schema <- fields[[fname]]
    field_ui <- f_or(uiSchema[[fname]], list())
    field_value <- formData[[fname]]

    # Determine which column this field belongs to
    # For groups (type = "object"), check ui:options at the group level
    # For regular fields, check ui:options at the field level
    if (field_schema$type == "object") {
      field_column <- f_or(field_ui[["ui:options"]]$column, 1)
    } else {
      field_column <- f_or(field_ui[["ui:options"]]$column, 1)
    }

    field_column <- max(1, min(columns, field_column))  # Clamp to valid range

    # Add rendered field to the appropriate column
    rendered <- render_field(fname, field_schema, field_ui, field_value, ns_prefix)
    column_fields[[field_column]][[length(column_fields[[field_column]]) + 1]] <- rendered
  }

  # Build header if requested
  header_html <- NULL
  if (show_header) {
    title_value <- if (!is.null(title_field)) formData[[title_field]] else "Item"
    title_id <- paste0(ns_prefix, "header_title")

    header_html <- div(class = "form-header mb-3",
      div(class = "d-flex align-items-center justify-content-between",
        tags$h4(class = "mb-0",
          tags$input(
            type = "text",
            id = title_id,
            class = "form-control form-control-title",
            value = f_or(title_value, "Item"),
            readonly = "readonly"  # Start in locked mode
          )
        ),
        tags$button(
          type = "button",
          class = "btn btn-edit-toggle",
          id = paste0(ns_prefix, "edit_btn"),
          onclick = if (!is.null(module_id)) {
            sprintf("toggleEditMode_%s(this)", gsub("-", "_", module_id))
          } else {
            "toggleEditMode(this)"  # Fallback for legacy usage
          },
          tags$i(class = "bi bi-pencil-square"),
          tags$span(" Edit")
        )
      )
    )
  }

  # Footer with Delete button
  footer_html <- NULL
  if (show_footer) {
    delete_btn_id <- paste0(ns_prefix, "delete_btn")
    delete_click <- if (!is.null(module_id)) {
      sprintf("confirmDelete_%s(this)", gsub("-", "_", module_id))
    } else {
      "confirmDelete(this)"
    }

    footer_html <- div(class = "form-footer mt-3",
      div(class = "d-flex align-items-center justify-content-end",
        tags$button(
          type = "button",
          class = "btn btn-delete",
          id = delete_btn_id,
          onclick = delete_click,
          disabled = if (delete_disabled) "disabled" else NULL,
          `data-disabled-on-new` = "true",
          tags$i(class = "bi bi-trash"),
          tags$span(" Delete")
        )
      )
    )
  }

  # Wrap in columns dynamically with frame
  if (columns == 1) {
    # Single column - no grid needed
    div(class = "form-wrapper border rounded p-3",
      header_html,
      div(column_fields[[1]]),
      footer_html
    )
  } else {
    # Multi-column layout (2-4 columns)
    # Calculate Bootstrap column class (12 / columns)
    # Use col- (no breakpoint) so it always uses columns, not col-md- which stacks on small screens
    col_width <- 12 / columns
    col_class <- paste0("col-", col_width)

    # Build column divs
    column_divs <- lapply(1:columns, function(i) {
      # Add border-end to all columns except the last
      classes <- if (i < columns) {
        paste(col_class, "border-end")
      } else {
        col_class
      }

      div(class = classes, column_fields[[i]])
    })

    # Wrap everything in a frame
    div(class = "form-wrapper border rounded p-3",
      header_html,
      div(class = "row flex-nowrap", column_divs),
      footer_html
    )
  }
}

render_field <- function(name, schema, ui, value, ns_prefix) {
  type <- f_or(schema$type, "string")
  title <- f_or(schema$title, name)
  widget <- f_or(ui[["ui:widget"]], NULL)
  is_plaintext <- identical(ui[["ui:field"]], "plaintext")

  # Handle object type (groups)
  if (type == "object") {
    is_collapsible <- isTRUE(ui[["ui:options"]]$collapsible)
    is_collapsed <- isTRUE(ui[["ui:options"]]$collapsed)

    if (is_collapsible) {
      # Collapsible group
      group_id <- paste0(ns_prefix, name, "_group")
      tags$details(
        open = if (!is_collapsed) NA else NULL,
        tags$summary(tags$strong(title)),
        render_object_fields(name, schema, ui, value, ns_prefix)
      )
    } else {
      # Regular fieldset
      tags$fieldset(
        tags$legend(title),
        render_object_fields(name, schema, ui, value, ns_prefix)
      )
    }
  } else {
    # Regular field - inline label and input
    div(class = "mb-3 row align-items-center",
      tags$label(`for` = paste0(ns_prefix, name),
                 class = "col-sm-4 col-form-label",
                 style = "padding-right: 0.5rem; word-wrap: break-word;",
                 title),
      div(class = "col-sm-8",
        render_input(name, schema, ui, value, is_plaintext, ns_prefix)
      )
    )
  }
}

render_object_fields <- function(parent_name, schema, ui, value, ns_prefix) {
  if (is.null(schema$properties)) return(NULL)

  lapply(names(schema$properties), function(fname) {
    field_schema <- schema$properties[[fname]]
    field_ui <- f_or(ui[[fname]], list())
    field_value <- if (!is.null(value)) value[[fname]] else NULL
    field_full_name <- paste0(parent_name, ".", fname)

    render_field(field_full_name, field_schema, field_ui, field_value, ns_prefix)
  })
}

render_input <- function(name, schema, ui, value, is_plaintext, ns_prefix) {
  input_id <- paste0(ns_prefix, name)
  type <- f_or(schema$type, "string")
  widget <- ui[["ui:widget"]]
  format <- schema$format

  # Convert value to string
  val_str <- if (!is.null(value)) as.character(value) else ""

  # Plaintext (static field) - no frame, just text, never editable
  if (is_plaintext) {
    return(div(
      class = "form-static-value",
      style = "padding: 0.375rem 0; color: #6c757d; font-size: 10px !important; line-height: 1.25rem; background: transparent;",
      `data-static` = "true",
      val_str
    ))
  }

  # Textarea
  if (!is.null(widget) && length(widget) > 0 && widget == "textarea") {
    return(tags$textarea(
      id = input_id,
      class = "form-control",
      rows = 3,
      readonly = "readonly",
      disabled = "disabled",
      val_str
    ))
  }

  # Select dropdown
  if (!is.null(schema$enum) && length(schema$enum) > 0) {
    enum_names <- f_or(schema$enumNames, schema$enum)

    # Check if this is an icon-select widget
    is_icon_select <- !is.null(widget) && length(widget) > 0 && widget == "icon-select"

    # Get icon metadata if available (passed via ui options)
    icon_metadata <- f_or(ui[["ui:options"]]$iconMetadata, list())

    options_list <- mapply(function(val, label) {
      # For icon-select, add data attribute for thumbnail
      if (is_icon_select && length(icon_metadata) > 0) {
        # Find matching icon metadata - convert both to character for comparison
        icon_info <- NULL
        val_str <- as.character(val)
        for (icon in icon_metadata) {
          if (!is.null(icon$id) && as.character(icon$id) == val_str) {
            icon_info <- icon
            break
          }
        }

        # Add thumbnail as data attribute if found
        if (!is.null(icon_info) && !is.null(icon_info$thumbnail)) {
          tags$option(
            value = val,
            selected = if (identical(val, value)) NA else NULL,
            `data-thumbnail` = icon_info$thumbnail,
            label
          )
        } else {
          tags$option(value = val, selected = if (identical(val, value)) NA else NULL, label)
        }
      } else {
        tags$option(value = val, selected = if (identical(val, value)) NA else NULL, label)
      }
    }, schema$enum, enum_names, SIMPLIFY = FALSE, USE.NAMES = FALSE)

    # Add special class for icon-select
    select_class <- if (is_icon_select) "form-select icon-select" else "form-select"

    select_element <- tags$select(
      id = input_id,
      class = select_class,
      disabled = "disabled",
      options_list
    )

    # For icon-select, create custom visual dropdown with thumbnails IN the list
    if (is_icon_select) {
      # Build custom dropdown HTML with thumbnails
      dropdown_options <- mapply(function(val, label) {
        # Find thumbnail for this option
        thumbnail_url <- ""
        if (length(icon_metadata) > 0) {
          val_str <- as.character(val)
          for (icon in icon_metadata) {
            if (!is.null(icon$id) && as.character(icon$id) == val_str) {
              thumbnail_url <- f_or(icon$thumbnail, "")
              break
            }
          }
        }

        # Build option HTML with thumbnail
        div(class = "icon-option", `data-value` = val,
          if (nzchar(thumbnail_url)) {
            tags$img(src = thumbnail_url, class = "icon-thumb", style = "width:24px;height:24px;margin-right:8px;vertical-align:middle;border:1px solid #dee2e6;border-radius:3px;")
          } else {
            tags$span(class = "icon-thumb-placeholder", style = "display:inline-block;width:24px;height:24px;margin-right:8px;background:#f0f0f0;border:1px solid #dee2e6;border-radius:3px;vertical-align:middle;")
          },
          tags$span(class = "icon-label", label)
        )
      }, schema$enum, enum_names, SIMPLIFY = FALSE, USE.NAMES = FALSE)

      # Find selected option for display
      selected_label <- "(none)"
      selected_thumbnail <- ""
      if (!is.null(value) && nzchar(value)) {
        idx <- which(schema$enum == value)
        if (length(idx) > 0) {
          selected_label <- enum_names[idx[1]]
          # Find thumbnail
          val_str <- as.character(value)
          for (icon in icon_metadata) {
            if (!is.null(icon$id) && as.character(icon$id) == val_str) {
              selected_thumbnail <- f_or(icon$thumbnail, "")
              break
            }
          }
        }
      }

      # Return custom dropdown
      return(div(class = "icon-picker-custom", id = input_id, `data-value` = value, `data-disabled` = "true",
        # Display (what user sees when closed)
        div(class = "icon-picker-display",
          if (nzchar(selected_thumbnail)) {
            tags$img(src = selected_thumbnail, class = "icon-thumb", style = "width:24px;height:24px;margin-right:8px;vertical-align:middle;border:1px solid #dee2e6;border-radius:3px;")
          } else {
            tags$span(class = "icon-thumb-placeholder", style = "display:inline-block;width:24px;height:24px;margin-right:8px;background:#f0f0f0;border:1px solid #dee2e6;border-radius:3px;vertical-align:middle;")
          },
          tags$span(class = "icon-label", selected_label),
          tags$i(class = "dropdown-arrow", style = "margin-left:auto;")
        ),
        # Dropdown list (shown when opened)
        div(class = "icon-picker-dropdown", style = "display:none;",
          dropdown_options
        )
      ))
    } else {
      return(select_element)
    }
  }

  # Number input
  if (type %in% c("number", "integer")) {
    return(tags$input(
      type = "number",
      id = input_id,
      class = "form-control",
      value = val_str,
      min = schema$minimum,
      max = schema$maximum,
      step = if (type == "integer") 1 else "any",
      readonly = "readonly",
      disabled = "disabled"
    ))
  }

  # Color picker
  if (!is.null(format) && length(format) > 0 && format == "color") {
    # Use both a visible disabled color input and a hidden input for Shiny binding
    return(tagList(
      tags$input(
        type = "color",
        id = paste0(input_id, "_display"),
        class = "form-control form-control-color",
        value = val_str,
        disabled = "disabled",
        onchange = sprintf("document.getElementById('%s').value = this.value; if(window.Shiny) Shiny.setInputValue('%s', this.value);", input_id, input_id)
      ),
      tags$input(
        type = "hidden",
        id = input_id,
        value = val_str
      )
    ))
  }

  # Default: text input
  tags$input(
    type = "text",
    id = input_id,
    class = "form-control",
    value = val_str,
    readonly = "readonly",
    disabled = "disabled"
  )
}
