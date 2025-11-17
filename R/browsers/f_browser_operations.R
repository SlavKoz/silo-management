# R/browsers/f_browser_operations.R
# Operations Browser

# =========================== UI ===============================================
browser_operations_ui <- function(id) {
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
browser_operations_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_operations <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_operations(
          code_like = NULL,
          order_col = "OpCode",
          limit = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Create styled 3-letter code icon (use first 3 letters of OpCode)
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        code_3 <- toupper(substr(df$OpCode[i], 1, 3))
        sprintf(
          '<div style="display:inline-block; width:32px; height:32px; background:#7c3aed; color:#fff; font-weight:bold; font-size:11px; text-align:center; line-height:32px; border-radius:4px;">%s</div>',
          code_3
        )
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_operations()
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
        id = df$OperationID,
        icon = df$IconDisplay,
        title = toupper(df$OpName),
        description = df$OpCode,
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
          field("OpCode",           "text",     title="Code", column = 1, required = TRUE),
          field("OpName",           "text",     title="Name", column = 1, required = TRUE),
          field("RequiresParams",   "switch",   title="Requires Parameters", column = 1),
          field("ParamsSchemaJSON", "textarea", title="Parameters Schema (JSON)", column = 1)
        ),
        columns = 1
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
          OpCode = "",
          OpName = "",
          RequiresParams = FALSE,
          ParamsSchemaJSON = ""
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          OpCode = "",
          OpName = "",
          RequiresParams = FALSE,
          ParamsSchemaJSON = ""
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_operation_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Return flat structure
      list(
        OperationID = as.integer(f_or(df1$OperationID, 0)),
        OpCode = f_or(df1$OpCode, ""),
        OpName = f_or(df1$OpName, ""),
        RequiresParams = as.logical(f_or(df1$RequiresParams, FALSE)),
        ParamsSchemaJSON = f_or(df1$ParamsSchemaJSON, "")
      )
    })

    # ---- Initialize HTML form module ----
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "OpName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database (data is already flat)
          saved_id <- upsert_operation(data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Operation Save Error]:", error_msg, "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key
            field_to_clear <- "OpCode"
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

    # --- Deep-linking support ---
    # If route reactive is provided, observe URL changes
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        # Only handle if we're on the operations page (nested under actions)
        if (length(parts) >= 2 && parts[1] == "actions" && parts[2] == "operations") {
          # If there's an item ID, select it
          if (length(parts) >= 3) {
            op_code <- parts[3]

            # Look up OperationID for this OpCode
            df <- raw_operations()
            if (!nrow(df)) return()

            # Try exact match (case-insensitive)
            row <- df[!is.na(df$OpCode) & tolower(trimws(df$OpCode)) == tolower(trimws(op_code)), ]

            if (nrow(row) == 0) {
              showNotification(paste0("Operation '", op_code, "' not found"), type = "warning", duration = 2)
              return()
            }

            # Select the item by its numeric ID
            operation_id <- as.integer(row$OperationID[1])
            current_selected <- selected_id()

            # Only update if different from current selection
            if (is.null(current_selected) || current_selected != operation_id) {
              list_result$select_item(operation_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes - BUT ONLY if we're on the operations page
      observe({
        parts <- route()

        # Only update URL if we're currently on the operations page
        if (length(parts) < 2 || parts[1] != "actions" || parts[2] != "operations") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        # Get OpCode for currently selected OperationID
        df <- raw_operations()
        if (!nrow(df)) return()

        row <- df[df$OperationID == sid, ]
        if (nrow(row) == 0) return()

        op_code <- row$OpCode[1]

        # Check if we need to update the route
        expected_parts <- c("actions", "operations", op_code)

        if (!identical(parts, expected_parts)) {
          # Send message to update hash
          session$sendCustomMessage("set-hash", list(h = paste0("#/actions/operations/", op_code)))
        }
      })
    }

    return(list(selected_operation_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_operations_ui <- browser_operations_ui
f_browser_operations_server <- function(id, pool, route = NULL) {
  browser_operations_server(id, pool, route)
}
