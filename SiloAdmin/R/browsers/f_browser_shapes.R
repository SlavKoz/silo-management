# R/browsers/f_browser_shapes.R
# Shape Templates Browser - based on containers pattern

# =========================== UI ===============================================
browser_shapes_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "ui grid stackable",

        # LEFT — compact list (33%)
        div(class = "five wide column",
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by code/type…"
            )
        ),

        # RIGHT — detail/editor using HTML form module (66%)
        div(class = "eleven wide column",
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
        )
    )
  )
}

# ========================== SERVER ============================================
browser_shapes_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_shapes <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_shape_templates(
          shape_type = NULL,
          code_like = NULL,
          order_col = "TemplateCode",
          limit     = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Calculate relative sizes within each shape type
      size_factors <- calculate_relative_sizes(df)

      # Generate SVG icons based on actual shape data
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        as.character(generate_shape_icon_svg(
          shape_type = df$ShapeType[i],
          size_factor = size_factors[i],
          fill = f_or(df$DefaultFill[i], "#D9EFFF"),
          border = f_or(df$DefaultBorder[i], "#6290FF"),
          rotation_deg = f_or(df$RotationDeg[i], 0)
        ))
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_shapes()
      if (!nrow(df)) {
        return(data.frame(
          id = character(0),
          icon = character(0),
          title = character(0),
          description = character(0),
          stringsAsFactors = FALSE
        ))
      }

      data.frame(
        id = df$ShapeTemplateID,
        icon = df$IconDisplay,
        title = toupper(df$TemplateCode),
        description = df$ShapeType,
        stringsAsFactors = FALSE
      )
    })

    # Use compact list module
    list_result <- compact_list_server(
      "list",
      items = list_items,
      add_new_item = TRUE,
      add_new_label = "<<add new>>",
      add_new_icon = "",
      initial_selection = "first"  # Auto-select first item on load
    )

    selected_id <- list_result$selected_id

    # ---- Schema configuration ----
    schema_config <- reactive({
      list(
        fields = list(
          # Column 1 - Basic Info
          field("TemplateCode", "text",     title="Code", column = 1, required = TRUE),
          field("ShapeType",    "select",   title="Type", enum=c("CIRCLE", "RECTANGLE", "TRIANGLE"), default="CIRCLE", column = 1, required = TRUE),
          field("Notes",        "textarea", title="Notes", column = 1),

          # Column 2 - Geometry (conditional based on ShapeType)
          field("Radius",       "number",   title="Radius", min=0, group="Geometry",
                requiredIf = list(field = "ShapeType", values = c("CIRCLE", "TRIANGLE"))),
          field("Width",        "number",   title="Width", min=0, group="Geometry",
                requiredIf = list(field = "ShapeType", values = "RECTANGLE")),
          field("Height",       "number",   title="Height", min=0, group="Geometry",
                requiredIf = list(field = "ShapeType", values = "RECTANGLE")),
          field("RotationDeg",  "number",   title="Rotation (deg)", min=0, max=360, default=0, group="Geometry",
                requiredIf = list(field = "ShapeType", values = c("RECTANGLE", "TRIANGLE"))),

          # Column 2 - Graphics
          field("DefaultFill",     "color",  title="Fill",      group="Graphics"),
          field("DefaultBorder",   "color",  title="Border",    group="Graphics"),
          field("DefaultBorderPx", "number", title="Border px", min=0, max=20, group="Graphics")
        ),
        groups = list(
          group("Geometry", title="Geometry", collapsible=FALSE, collapsed=FALSE, column=2),
          group("Graphics", title="Graphics", collapsible=TRUE, collapsed=TRUE, column=2)
        ),
        columns = 2,
        static_fields = character(0)
      )
    })

    # ---- Reactive form data based on selection ----
    form_data <- reactive({
      # Depend on trigger_refresh to re-fetch after save
      trigger_refresh()

      sid <- selected_id()

      # No selection - return empty data
      if (is.null(sid)) {
        return(list(
          TemplateCode = "",
          ShapeType = "CIRCLE",
          Notes = "",
          Geometry = list(
            Radius = NULL,
            Width = NULL,
            Height = NULL,
            RotationDeg = 0
          ),
          Graphics = list(
            DefaultFill = "#D9EFFF",
            DefaultBorder = "#6290FF",
            DefaultBorderPx = 1
          )
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          TemplateCode = "",
          ShapeType = "CIRCLE",
          Notes = "",
          Geometry = list(
            Radius = NULL,
            Width = NULL,
            Height = NULL,
            RotationDeg = 0
          ),
          Graphics = list(
            DefaultFill = "#D9EFFF",
            DefaultBorder = "#6290FF",
            DefaultBorderPx = 1
          )
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_shape_template_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Transform to nested format
      list(
        ShapeTemplateID = as.integer(f_or(df1$ShapeTemplateID, 0)),
        TemplateCode = f_or(df1$TemplateCode, ""),
        ShapeType = f_or(df1$ShapeType, "CIRCLE"),
        Notes = f_or(df1$Notes, ""),
        Geometry = list(
          Radius = if (!is.null(df1$Radius) && !is.na(df1$Radius)) as.numeric(df1$Radius) else NULL,
          Width = if (!is.null(df1$Width) && !is.na(df1$Width)) as.numeric(df1$Width) else NULL,
          Height = if (!is.null(df1$Height) && !is.na(df1$Height)) as.numeric(df1$Height) else NULL,
          RotationDeg = as.numeric(f_or(df1$RotationDeg, 0))
        ),
        Graphics = list(
          DefaultFill = f_or(df1$DefaultFill, "#D9EFFF"),
          DefaultBorder = f_or(df1$DefaultBorder, "#6290FF"),
          DefaultBorderPx = as.numeric(f_or(df1$DefaultBorderPx, 1))
        )
      )
    })

    # ---- Initialize HTML form module ----
    # Declare form_module first so it can be captured in callbacks
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "TemplateCode",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database
          saved_id <- upsert_shape_template(data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Shape Save Error]:", error_msg, "\n")

          # Print full error details for debugging
          cat("[Shape Save Error - Full Details]:\n")
          cat("  Error class:", class(e), "\n")
          cat("  Error message:", error_msg, "\n")
          if (!is.null(e$call)) cat("  Call:", deparse(e$call), "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key - typically the TemplateCode field
            field_to_clear <- "TemplateCode"
            if (grepl("duplicate key value is \\(([^)]+)\\)", error_msg, ignore.case = TRUE)) {
              dup_value <- gsub(".*duplicate key value is \\(([^)]+)\\).*", "\\1", error_msg, ignore.case = TRUE)
              user_msg <- paste0("Cannot save: Code '", dup_value, "' already exists. Please use a different code.")
            } else {
              user_msg <- "Cannot save: This code already exists. Please use a different code."
            }
          } else if (grepl("CK_ShapeTemplates_Geom", error_msg, ignore.case = TRUE)) {
            # Geometry constraint violation
            user_msg <- "Cannot save: Invalid geometry. CIRCLE/TRIANGLE require Radius; RECTANGLE requires Width and Height."
          } else if (grepl("CK_ShapeTemplates_Positive", error_msg, ignore.case = TRUE)) {
            # Positive values constraint
            user_msg <- "Cannot save: Radius, Width, and Height must be positive values."
          } else if (grepl("Unsupported column type", error_msg, ignore.case = TRUE)) {
            # nanodbc type error (usually from NULL instead of NA)
            user_msg <- "Cannot save: Internal data type error. Check console for details."
          } else if (grepl("NULL", error_msg, ignore.case = TRUE) && grepl("cannot insert", error_msg, ignore.case = TRUE)) {
            # NULL constraint
            user_msg <- "Cannot save: Required field is missing."
          } else {
            # Generic database error - show first 300 chars
            user_msg <- paste0("Database error: ", substr(error_msg, 1, 300))
          }

          # Show error notification
          showNotification(user_msg, type = "error", duration = NULL)

          # Re-enter edit mode and clear the offending field
          form_module$handle_save_failure(field_to_clear)

          return(FALSE)
        })
      },
      on_delete = function() {
        # TODO: Implement delete functionality
        return(FALSE)
      }
    )

    # --- Deep-linking support ---
    # If route reactive is provided, observe URL changes
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        # Only handle if we're on the shapes page
        if (length(parts) >= 1 && parts[1] == "shapes") {
          # If there's an item ID, select it
          if (length(parts) >= 2) {
            # URL-decode the template code to handle spaces and special characters
            template_code <- utils::URLdecode(parts[2])

            # Look up ShapeTemplateID for this TemplateCode
            df <- raw_shapes()
            if (!nrow(df)) return()

            row <- df[df$TemplateCode == template_code, ]
            if (nrow(row) == 0) {
              showNotification(paste0("Shape '", template_code, "' not found"), type = "warning", duration = 2)
              return()
            }

            # Select the item by its numeric ID
            shape_template_id <- as.integer(row$ShapeTemplateID[1])
            current_selected <- selected_id()

            # Only update if different from current selection
            if (is.null(current_selected) || current_selected != shape_template_id) {
              list_result$select_item(shape_template_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes - BUT ONLY if we're on the shapes page
      observe({
        parts <- route()

        # Only update URL if we're currently on the shapes page
        if (length(parts) < 1 || parts[1] != "shapes") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        # Get TemplateCode for currently selected ShapeTemplateID
        df <- raw_shapes()
        if (!nrow(df)) return()

        row <- df[df$ShapeTemplateID == sid, ]
        if (nrow(row) == 0) return()

        template_code <- as.character(row$TemplateCode[1])

        # URL-decode the current route part for comparison (to handle encoded characters)
        current_code <- if (length(parts) >= 2) utils::URLdecode(parts[2]) else NULL

        # Check if we need to update the route (compare decoded values)
        if (is.null(current_code) || current_code != template_code) {
          # URL-encode the template code for the URL
          encoded_code <- utils::URLencode(template_code, reserved = TRUE)
          # Send message to update hash
          session$sendCustomMessage("set-hash", list(h = paste0("#/shapes/", encoded_code)))
        }
      })
    }

    return(list(selected_shape_template_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_shapes_ui <- browser_shapes_ui
f_browser_shapes_server <- function(id, pool, route = NULL) {
  browser_shapes_server(id, pool, route)
}
