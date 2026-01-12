# R/browsers/f_browser_offline_reasons.R
# Offline Reasons Browser

# =========================== UI ===============================================
browser_offline_reasons_ui <- function(id) {
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
browser_offline_reasons_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_reasons <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_offline_reasons(
          code_like = NULL,
          order_col = "ReasonTypeCode",
          limit = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Fetch icon data for display
      icons_df <- try(list_icons_for_picker(limit = 1000), silent = TRUE)
      if (inherits(icons_df, "try-error") || is.null(icons_df)) {
        icons_df <- data.frame(id = integer(0), icon_name = character(0), png_32_b64 = character(0))
      }

      # Create icon display column
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        icon_id <- df$Icon[i]
        if (is.na(icon_id) || is.null(icon_id)) {
          return('<div style="display:inline-block; width:32px; height:32px; background:#e5e7eb; border-radius:4px;"></div>')
        }

        # Find matching icon
        icon_row <- icons_df[icons_df$id == icon_id, ]
        if (nrow(icon_row) == 0 || is.na(icon_row$png_32_b64[1]) || !nzchar(icon_row$png_32_b64[1])) {
          return('<div style="display:inline-block; width:32px; height:32px; background:#e5e7eb; border-radius:4px;"></div>')
        }

        sprintf('<img src="data:image/png;base64,%s" style="width:32px; height:32px; border-radius:4px;" />',
                icon_row$png_32_b64[1])
      }, character(1))

      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_reasons()
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
        id = df$ReasonTypeID,
        icon = df$IconDisplay,
        title = toupper(df$ReasonTypeName),
        description = df$ReasonTypeCode,
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
      initial_selection = "first"
    )

    selected_id <- list_result$selected_id

    # ---- Get icon choices for dropdown ----
    icon_choices <- reactive({
      icons_df <- try(list_icons_for_picker(limit = 1000), silent = TRUE)
      if (inherits(icons_df, "try-error") || is.null(icons_df) || !nrow(icons_df)) {
        return(c("(none)" = ""))
      }

      choices <- setNames(
        as.character(icons_df$id),
        icons_df$icon_name
      )
      c("(none)" = "", choices)
    })

    # ---- Icon metadata for thumbnails ----
    icon_metadata <- reactive({
      icons_df <- try(list_icons_for_picker(limit = 1000), silent = TRUE)
      if (inherits(icons_df, "try-error") || is.null(icons_df) || !nrow(icons_df)) {
        return(list())
      }

      lapply(seq_len(nrow(icons_df)), function(i) {
        has_b64 <- !is.na(icons_df$png_32_b64[i]) && nzchar(as.character(icons_df$png_32_b64[i]))

        list(
          id = as.character(icons_df$id[i]),
          name = icons_df$icon_name[i],
          thumbnail = if (has_b64) paste0("data:image/png;base64,", icons_df$png_32_b64[i]) else NULL
        )
      })
    })

    # ---- Schema configuration ----
    schema_config <- reactive({
      list(
        fields = list(
          # Column 1 - Basic Info
          field("ReasonTypeCode", "text",   title="Code", column = 1, required = TRUE),
          field("ReasonTypeName", "text",   title="Name", column = 1, required = TRUE),
          field("Icon",           "select", title="Icon", enum = icon_choices(),
                widget = "icon-select", icon_metadata = icon_metadata(), column = 1)
        ),
        columns = 1
      )
    })

    # ---- Reactive form data based on selection ----
    form_data <- reactive({
      # Depend on trigger_refresh to re-fetch after save
      trigger_refresh()

      # Depend on icons_version to refresh when icons change
      if (!is.null(session$userData$icons_version)) {
        session$userData$icons_version
      }

      sid <- selected_id()

      # No selection - return empty data
      if (is.null(sid)) {
        return(list(
          ReasonTypeCode = "",
          ReasonTypeName = "",
          Icon = ""
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          ReasonTypeCode = "",
          ReasonTypeName = "",
          Icon = ""
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_offline_reason_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Return flat structure
      list(
        ReasonTypeID = as.integer(f_or(df1$ReasonTypeID, 0)),
        ReasonTypeCode = f_or(df1$ReasonTypeCode, ""),
        ReasonTypeName = f_or(df1$ReasonTypeName, ""),
        Icon = as.character(f_or(df1$Icon, ""))
      )
    })

    # ---- Initialize HTML form module ----
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "ReasonTypeName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database (data is already flat)
          saved_id <- upsert_offline_reason(data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Offline Reason Save Error]:", error_msg, "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key
            field_to_clear <- "ReasonTypeCode"
            if (grepl("duplicate key value is \\(([^)]+)\\)", error_msg, ignore.case = TRUE)) {
              dup_value <- gsub(".*duplicate key value is \\(([^)]+)\\).*", "\\1", error_msg, ignore.case = TRUE)
              user_msg <- paste0("Cannot save: Code '", dup_value, "' already exists. Please use a different code.")
            } else {
              user_msg <- "Cannot save: This code already exists. Please use a different code."
            }
          } else if (grepl("NULL", error_msg, ignore.case = TRUE) && grepl("cannot insert", error_msg, ignore.case = TRUE)) {
            # NULL constraint
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
        # TODO: Implement delete functionality with referential integrity check
        return(FALSE)
      }
    )

    return(list(selected_reason_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_offline_reasons_ui <- browser_offline_reasons_ui
f_browser_offline_reasons_server <- function(id, pool, route = NULL) {
  browser_offline_reasons_server(id, pool, route)
}
