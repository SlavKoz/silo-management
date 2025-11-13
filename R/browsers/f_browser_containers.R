# R/browsers/f_browser_containers.R
# (Packages are loaded in global.R)

# =========================== UI ===============================================
browser_containers_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "ui grid stackable",

        # LEFT — compact list (33%)
        div(class = "five wide column",
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by code/name…"
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
browser_containers_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_types <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_container_types(
          code_like = NULL,
          order_col = "TypeCode",
          limit     = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Format icons as HTML img tags
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        # Check if we have IconImage base64 data
        if (!is.null(df$IconImage) && !is.na(df$IconImage[i]) && nzchar(df$IconImage[i])) {
          # Render as img tag with base64 data (CSS handles sizing via object-fit)
          sprintf('<img src="data:image/png;base64,%s" />',
                  df$IconImage[i])
        } else {
          # Fallback to emoji based on BottomType
          bt <- toupper(as.character(f_or(df$BottomType[i], "")))
          if (bt == "HOPPER") "🔻" else if (bt == "FLAT") "▭" else "◻️"
        }
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_types()
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
        id = df$ContainerTypeID,
        icon = df$IconDisplay,
        title = toupper(df$TypeName),
        description = df$TypeCode,
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

    # ---- Fetch icons for picker ----
    # Note: This will be made reactive to edit mode in form module below
    fetch_icons <- function() {
      df <- try(list_icons_for_picker(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || !nrow(df)) {
        return(list(choices = c("(none)" = ""), metadata = list()))
      }

      # Create named vector: display name = id
      icons <- setNames(as.character(df$id), df$icon_name)
      choices <- c("(none)" = "", icons)

      # Build metadata with thumbnails
      metadata <- lapply(seq_len(nrow(df)), function(i) {
        list(
          id = as.character(df$id[i]),
          name = df$icon_name[i],
          thumbnail = if (!is.null(df$png_32_b64) && !is.na(df$png_32_b64[i]) && nzchar(df$png_32_b64[i])) {
            paste0("data:image/png;base64,", df$png_32_b64[i])
          } else {
            NULL
          }
        )
      })

      list(choices = choices, metadata = metadata)
    }

    # Initial icons data
    icons_data <- reactiveVal(fetch_icons())

    # ---- Schema configuration (reactive for dynamic icon list) ----
    schema_config <- reactive({
      icon_info <- icons_data()

      list(
        fields = list(
          # Column 1
          field("TypeName",       "text",     title="Name", column = 1, required = TRUE),
          field("TypeCode",       "text",     title="Code", column = 1, required = TRUE),
          field("Description",    "textarea", title="Description", column = 1),
          field("BottomType",     "select",   title="Bottom Type", enum=c("HOPPER", "FLAT"), default="HOPPER", column = 1),
          field("IconID",         "select",   title="Icon", enum=icon_info$choices, widget="icon-select", icon_metadata=icon_info$metadata, column = 1, required = TRUE),

          # Column 2 - Graphics
          field("DefaultFill",     "color",   title="Fill",      group="Graphics"),
          field("DefaultBorder",   "color",   title="Border",    group="Graphics"),
          field("DefaultBorderPx", "number", title="Border px", min=0, max=20, group="Graphics"),

          # Column 2 - Meta
          field("CreatedAt","text", title="Created", group="Meta"),
          field("UpdatedAt","text", title="Updated", group="Meta")
        ),
        groups = list(
          group("Graphics", title="Graphics", collapsible=TRUE, collapsed=TRUE, column=2),
          group("Meta",     title="Meta",     collapsible=TRUE, collapsed=TRUE, column=2)
        ),
        columns = 2,
        static_fields = c("Meta.CreatedAt", "Meta.UpdatedAt")
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
          TypeName = "",
          TypeCode = "",
          Description = "",
          BottomType = "HOPPER",
          IconID = "",
          Graphics = list(
            DefaultFill = "#cccccc",
            DefaultBorder = "#333333",
            DefaultBorderPx = 1
          ),
          Meta = list(
            CreatedAt = "",
            UpdatedAt = ""
          )
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          TypeName = "",
          TypeCode = "",
          Description = "",
          BottomType = "HOPPER",
          IconID = "",
          Graphics = list(
            DefaultFill = "#cccccc",
            DefaultBorder = "#333333",
            DefaultBorderPx = 1
          ),
          Meta = list(
            CreatedAt = "",
            UpdatedAt = ""
          )
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_container_type_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Transform to nested format
      # Note: database column "Icon" maps to form field "IconID"
      list(
        ContainerTypeID = as.integer(f_or(df1$ContainerTypeID, 0)),  # Include ID for updates
        TypeName = f_or(df1$TypeName, ""),
        TypeCode = f_or(df1$TypeCode, ""),
        Description = f_or(df1$Description, ""),
        BottomType = f_or(df1$BottomType, "HOPPER"),
        IconID = as.character(f_or(df1$Icon, "")),
        Graphics = list(
          DefaultFill = f_or(df1$DefaultFill, "#cccccc"),
          DefaultBorder = f_or(df1$DefaultBorder, "#333333"),
          DefaultBorderPx = as.numeric(f_or(df1$DefaultBorderPx, 1))
        ),
        Meta = list(
          CreatedAt = if (inherits(df1$CreatedAt, "POSIXt")) format(df1$CreatedAt, "%Y-%m-%d %H:%M:%S") else as.character(f_or(df1$CreatedAt, "")),
          UpdatedAt = if (inherits(df1$UpdatedAt, "POSIXt")) format(df1$UpdatedAt, "%Y-%m-%d %H:%M:%S") else as.character(f_or(df1$UpdatedAt, ""))
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
      title_field = "TypeName",
      show_header = TRUE,
      show_delete_button = TRUE,  # Show delete button (disabled on add new)
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database
          saved_id <- upsert_container_type(data)

          # If this was a new record, select it using the list module's method
          # (handles waiting for the item to appear after refresh)
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Container Save Error]:", error_msg, "\n")

          # Identify which field caused the error and what to clear
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key - typically the Code field
            field_to_clear <- "TypeCode"
            if (grepl("duplicate key value is \\(([^)]+)\\)", error_msg, ignore.case = TRUE)) {
              dup_value <- gsub(".*duplicate key value is \\(([^)]+)\\).*", "\\1", error_msg, ignore.case = TRUE)
              user_msg <- paste0("Cannot save: Code '", dup_value, "' already exists. Please use a different code.")
            } else {
              user_msg <- "Cannot save: This code already exists. Please use a different code."
            }
          } else if (grepl("FOREIGN KEY constraint", error_msg, ignore.case = TRUE)) {
            # Foreign key - could be Icon or other reference
            if (grepl("Icon", error_msg, ignore.case = TRUE)) {
              field_to_clear <- "IconID"
            }
            user_msg <- "Cannot save: Referenced item does not exist. Please check your selections."
          } else if (grepl("NULL", error_msg, ignore.case = TRUE) && grepl("cannot insert", error_msg, ignore.case = TRUE)) {
            # NULL constraint - try to identify field from error message
            user_msg <- "Cannot save: Required field is missing."
          } else {
            # Generic database error
            user_msg <- paste0("Database error: ", substr(error_msg, 1, 200))
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

    # Refresh dynamic selects (icons, etc.) when edit mode is entered
    observeEvent(form_module$edit_refresh_trigger(), {
      cat("[Container Browser] Edit mode triggered, refreshing icons...\n")
      icons_data(fetch_icons())
    }, ignoreInit = TRUE)

    # --- Deep-linking support ---
    # If route reactive is provided, observe URL changes
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        # Only handle if we're on the containers page
        if (length(parts) >= 1 && parts[1] == "containers") {
          # If there's an item ID, select it
          if (length(parts) >= 2) {
            type_code <- parts[2]

            # Look up ContainerTypeID for this TypeCode
            df <- raw_types()
            if (!nrow(df)) return()

            row <- df[df$TypeCode == type_code, ]
            if (nrow(row) == 0) {
              showNotification(paste0("Container '", type_code, "' not found"), type = "warning", duration = 2)
              return()
            }

            # Select the item by its numeric ID
            container_type_id <- as.integer(row$ContainerTypeID[1])
            current_selected <- selected_id()

            # Only update if different from current selection
            if (is.null(current_selected) || current_selected != container_type_id) {
              list_result$select_item(container_type_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes - BUT ONLY if we're on the containers page
      observe({
        parts <- route()

        # Only update URL if we're currently on the containers page
        if (length(parts) < 1 || parts[1] != "containers") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        # Get TypeCode for currently selected ContainerTypeID
        df <- raw_types()
        if (!nrow(df)) return()

        row <- df[df$ContainerTypeID == sid, ]
        if (nrow(row) == 0) return()

        type_code <- as.character(row$TypeCode[1])

        # Check if we need to update the route
        expected_parts <- c("containers", type_code)

        if (!identical(parts, expected_parts)) {
          # Send message to update hash
          session$sendCustomMessage("set-hash", list(h = paste0("#/containers/", type_code)))
        }
      })
    }

    return(list(selected_container_type_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_containers_ui <- browser_containers_ui
f_browser_containers_server <- function(id, pool, route = NULL) {
  browser_containers_server(id, pool, route)
}
