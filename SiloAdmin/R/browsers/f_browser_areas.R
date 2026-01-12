# R/browsers/f_browser_areas.R
# Areas Browser

# =========================== UI ===============================================
browser_areas_ui <- function(id) {
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
browser_areas_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_areas <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_areas(
          site_id = NULL,
          code_like = NULL,
          order_col = "AreaCode",
          limit = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Create styled 3-letter code icon (use first 3 letters of AreaCode)
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        code_3 <- toupper(substr(df$AreaCode[i], 1, 3))
        sprintf(
          '<div style="display:inline-block; width:32px; height:32px; background:#059669; color:#fff; font-weight:bold; font-size:11px; text-align:center; line-height:32px; border-radius:4px;">%s</div>',
          code_3
        )
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_areas()
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
        id = df$AreaID,
        icon = df$IconDisplay,
        title = toupper(df$AreaName),
        description = paste0(df$SiteCode, "-", df$AreaCode),
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

    # ---- Get site choices for dropdown ----
    site_choices <- reactive({
      sites_df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(sites_df, "try-error") || is.null(sites_df) || !nrow(sites_df)) {
        return(c("(no sites)" = ""))
      }

      choices <- setNames(
        as.character(sites_df$SiteID),
        paste0(sites_df$SiteCode, " - ", sites_df$SiteName)
      )
      c("(select site)" = "", choices)
    })

    # ---- Schema configuration ----
    schema_config <- reactive({
      list(
        fields = list(
          # Column 1 - Basic Info
          field("SiteID",    "select", title="Site", enum = site_choices(), column = 1, required = TRUE),
          field("AreaCode",  "text",   title="Code", column = 1, required = TRUE),
          field("AreaName",  "text",   title="Name", column = 1, required = TRUE),
          field("Notes",     "textarea", title="Notes", column = 1)
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
          SiteID = "",
          AreaCode = "",
          AreaName = "",
          Notes = ""
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          SiteID = "",
          AreaCode = "",
          AreaName = "",
          Notes = ""
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_area_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Return flat structure
      list(
        AreaID = as.integer(f_or(df1$AreaID, 0)),
        SiteID = as.character(f_or(df1$SiteID, "")),
        AreaCode = f_or(df1$AreaCode, ""),
        AreaName = f_or(df1$AreaName, ""),
        Notes = f_or(df1$Notes, "")
      )
    })

    # ---- Initialize HTML form module ----
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "AreaName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database (data is already flat)
          saved_id <- upsert_area(data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          # Increment global areas version to trigger Sites form refresh
          if (!is.null(session$userData$areas_version)) {
            session$userData$areas_version <- session$userData$areas_version + 1
          }

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Area Save Error]:", error_msg, "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key
            field_to_clear <- "AreaCode"
            if (grepl("duplicate key value is \\(([^)]+)\\)", error_msg, ignore.case = TRUE)) {
              dup_value <- gsub(".*duplicate key value is \\(([^)]+)\\).*", "\\1", error_msg, ignore.case = TRUE)
              user_msg <- paste0("Cannot save: Code '", dup_value, "' already exists for this site. Please use a different code.")
            } else {
              user_msg <- "Cannot save: This code already exists for this site. Please use a different code."
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

        # Only handle if we're on the areas page
        if (length(parts) >= 1 && parts[1] == "areas") {
          # If there's an item ID, select it
          if (length(parts) >= 2) {
            # URL-decode the area code to handle spaces and special characters
            area_code <- utils::URLdecode(parts[2])

            # Look up AreaID for this composite code (SITECODE-AREACODE)
            df <- raw_areas()
            if (!nrow(df)) return()

            # Extract site code and area code from composite
            if (grepl("-", area_code, fixed = TRUE)) {
              code_parts <- strsplit(area_code, "-", fixed = TRUE)[[1]]
              if (length(code_parts) >= 2) {
                site_code <- trimws(code_parts[1])
                area_code_part <- trimws(paste(code_parts[-1], collapse = "-"))

                # Try exact match
                row <- df[!is.na(df$SiteCode) & !is.na(df$AreaCode) &
                         trimws(df$SiteCode) == site_code &
                         trimws(df$AreaCode) == area_code_part, ]

                if (nrow(row) == 0) {
                  showNotification(paste0("Area '", area_code, "' not found"), type = "warning", duration = 2)
                  return()
                }

                # Select the item by its numeric ID
                area_id <- as.integer(row$AreaID[1])
                current_selected <- selected_id()

                # Only update if different from current selection
                if (is.null(current_selected) || current_selected != area_id) {
                  list_result$select_item(area_id)
                }
              }
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes - BUT ONLY if we're on the areas page
      observe({
        parts <- route()

        # Only update URL if we're currently on the areas page
        if (length(parts) < 1 || parts[1] != "areas") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        # Get composite code for currently selected AreaID
        df <- raw_areas()
        if (!nrow(df)) return()

        row <- df[df$AreaID == sid, ]
        if (nrow(row) == 0) return()

        composite_code <- paste0(row$SiteCode[1], "-", row$AreaCode[1])

        # URL-decode the current route part for comparison
        current_code <- if (length(parts) >= 2) utils::URLdecode(parts[2]) else NULL

        # Check if we need to update the route (compare decoded values)
        if (is.null(current_code) || current_code != composite_code) {
          # URL-encode the composite code for the URL
          encoded_code <- utils::URLencode(composite_code, reserved = TRUE)
          session$sendCustomMessage("set-hash", list(h = paste0("#/areas/", encoded_code)))
        }
      })
    }

    return(list(selected_area_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_areas_ui <- browser_areas_ui
f_browser_areas_server <- function(id, pool, route = NULL) {
  browser_areas_server(id, pool, route)
}
