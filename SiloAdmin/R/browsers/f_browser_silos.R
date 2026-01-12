# R/browsers/f_browser_silos.R
# Silos Browser - following shapes browser pattern

# =========================== UI ===============================================
browser_silos_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "ui grid stackable",

        # LEFT — compact list (33%)
        div(class = "five wide column",
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by name…"
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
browser_silos_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_silos <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_silos(
          area_id = NULL,
          name_like = NULL,
          active = NULL,
          order_col = "SiloName",
          limit     = 2000
        ), silent = FALSE
      )
      if (inherits(df, "try-error") || is.null(df)) {
        cat("[Silos Browser] Error loading silos:", conditionMessage(attr(df, "condition")), "\n")
        df <- data.frame()
      }
      cat("[Silos Browser] Retrieved", nrow(df), "silos\n")
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_silos()
      cat("[Silos Browser] Transforming", nrow(df), "silos for list display\n")
      if (!nrow(df)) {
        return(data.frame(
          id = character(0),
          icon = character(0),
          title = character(0),
          description = character(0),
          stringsAsFactors = FALSE
        ))
      }

      # Build description with Area and Site info
      descriptions <- vapply(seq_len(nrow(df)), function(i) {
        parts <- c()
        if (!is.na(df$AreaCode[i])) parts <- c(parts, df$AreaCode[i])
        if (!is.na(df$SiteCode[i])) parts <- c(parts, df$SiteCode[i])
        if (length(parts) == 0) return(paste0("Vol: ", round(df$VolumeM3[i], 1), "m³"))
        paste(c(parts, paste0("Vol: ", round(df$VolumeM3[i], 1), "m³")), collapse=" · ")
      }, character(1))

      result <- data.frame(
        id = df$SiloID,
        icon = "",  # No icon for now
        title = df$SiloName,
        description = descriptions,
        stringsAsFactors = FALSE
      )
      cat("[Silos Browser] Built list with", nrow(result), "items\n")
      result
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

    # ---- Reference data ----
    sites_data <- reactive({
      df <- try(list_sites(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    areas_data <- reactive({
      df <- try(list_areas(site_id = NULL, limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    container_types_data <- reactive({
      df <- try(list_container_types(limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) return(data.frame())
      df
    })

    # ---- Schema configuration ----
    schema_config <- reactive({
      # Build site choices
      sites <- sites_data()
      site_choices <- c("(select site)" = "")
      if (nrow(sites) > 0) {
        site_choices <- c(site_choices, setNames(
          as.character(sites$SiteID),
          paste0(sites$SiteCode, " - ", sites$SiteName)
        ))
      }

      # Build area choices
      areas <- areas_data()
      area_choices <- c("(select area)" = "")
      if (nrow(areas) > 0) {
        area_choices <- c(area_choices, setNames(
          as.character(areas$AreaID),
          paste0(areas$AreaCode, " - ", areas$AreaName, " (", areas$SiteCode, ")")
        ))
      }

      # Build container type choices
      types <- container_types_data()
      type_choices <- c("(select type)" = "")
      if (nrow(types) > 0) {
        type_choices <- c(type_choices, setNames(
          as.character(types$ContainerTypeID),
          types$TypeName
        ))
      }

      list(
        fields = list(
          # Column 1 - Basic Info
          field("SiloName", "text",     title="Name", column = 1, required = TRUE),
          field("VolumeM3", "number",   title="Volume (m³)", min=0, column = 1, required = TRUE),
          field("IsActive", "checkbox", title="Active", column = 1, default = TRUE),

          # Column 2 - Location & Type
          field("SiteID",          "select",   title="Site", enum=site_choices, column = 2, group="Location", required = TRUE),
          field("AreaID",          "select",   title="Area", enum=area_choices, column = 2, group="Location"),
          field("ContainerTypeID", "select",   title="Container Type", enum=type_choices, column = 2, group="Type", required = TRUE),

          # Column 2 - Layouts (read-only HTML display)
          field("Layouts", "html", title="Visible on Layouts", column = 2, group="Placements"),

          # Column 2 - Notes
          field("Notes", "textarea", title="Notes", column = 2, group="Notes")
        ),
        groups = list(
          group("Location",    title="Location",   collapsible=FALSE, collapsed=FALSE, column=2),
          group("Type",        title="Type",       collapsible=FALSE, collapsed=FALSE, column=2),
          group("Placements",  title="Placements", collapsible=FALSE, collapsed=FALSE, column=2),
          group("Notes",       title="Notes",      collapsible=TRUE,  collapsed=TRUE,  column=2)
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
          SiloName = "",
          VolumeM3 = NULL,
          IsActive = TRUE,
          Location = list(
            SiteID = "",
            AreaID = ""
          ),
          Type = list(
            ContainerTypeID = ""
          ),
          Placements = list(
            Layouts = '<span style="color: #999; font-style: italic;">Not placed on any layout</span>'
          ),
          Notes = list(
            Notes = ""
          )
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          SiloName = "",
          VolumeM3 = NULL,
          IsActive = TRUE,
          Location = list(
            SiteID = "",
            AreaID = ""
          ),
          Type = list(
            ContainerTypeID = ""
          ),
          Placements = list(
            Layouts = '<span style="color: #999; font-style: italic;">Not placed on any layout</span>'
          ),
          Notes = list(
            Notes = ""
          )
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_silo_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Fetch layouts where this silo is placed
      layouts <- try(get_silo_layouts(sid), silent = TRUE)
      layouts_html <- ""
      if (!inherits(layouts, "try-error") && !is.null(layouts) && nrow(layouts) > 0) {
        # Build HTML links for each layout
        layout_links <- vapply(seq_len(nrow(layouts)), function(i) {
          sprintf('<a href="#/placements/%d" target="_self" style="margin-right: 0.5rem; display: inline-block;">%s</a>',
                  layouts$LayoutID[i],
                  layouts$LayoutName[i])
        }, character(1))
        layouts_html <- paste(layout_links, collapse = "")
      } else {
        layouts_html <- '<span style="color: #999; font-style: italic;">Not placed on any layout</span>'
      }

      # Transform to nested format
      list(
        SiloID = as.integer(f_or(df1$SiloID, 0)),
        SiloName = f_or(df1$SiloName, ""),
        VolumeM3 = if (!is.null(df1$VolumeM3) && !is.na(df1$VolumeM3)) as.numeric(df1$VolumeM3) else NULL,
        IsActive = as.logical(f_or(df1$IsActive, TRUE)),
        Location = list(
          SiteID = if (!is.null(df1$SiteID) && !is.na(df1$SiteID)) as.character(df1$SiteID) else "",
          AreaID = if (!is.null(df1$AreaID) && !is.na(df1$AreaID)) as.character(df1$AreaID) else ""
        ),
        Type = list(
          ContainerTypeID = as.character(f_or(df1$ContainerTypeID, ""))
        ),
        Placements = list(
          Layouts = layouts_html
        ),
        Notes = list(
          Notes = f_or(df1$Notes, "")
        )
      )
    })

    # ---- Initialize HTML form module ----
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "SiloName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Save to database
          saved_id <- upsert_silo(data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the updated/new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Silo Save Error]:", error_msg, "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("CK_Silos_Volume_Positive", error_msg, ignore.case = TRUE)) {
            user_msg <- "Cannot save: Volume must be a positive value."
          } else if (grepl("NULL", error_msg, ignore.case = TRUE) && grepl("cannot insert", error_msg, ignore.case = TRUE)) {
            user_msg <- "Cannot save: Required field is missing."
          } else {
            user_msg <- paste0("Database error: ", substr(error_msg, 1, 300))
          }

          showNotification(user_msg, type = "error", duration = NULL)
          form_module$handle_save_failure(field_to_clear)

          return(FALSE)
        })
      },
      on_delete = function() {
        tryCatch({
          sid <- selected_id()
          if (is.null(sid) || is.na(sid)) {
            showNotification("No silo selected", type = "warning", duration = 3)
            return(FALSE)
          }

          # Delete from database
          delete_silo(sid)

          # Trigger list refresh
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Silo Delete Error]:", error_msg, "\n")

          # Check for FK constraint violations
          if (grepl("REFERENCE constraint", error_msg, ignore.case = TRUE)) {
            showNotification("Cannot delete: This silo is used in placements or other records. Remove those first.", type = "error", duration = NULL)
          } else {
            showNotification(paste0("Delete failed: ", substr(error_msg, 1, 200)), type = "error", duration = NULL)
          }

          return(FALSE)
        })
      }
    )

    # --- Deep-linking support ---
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        if (length(parts) >= 1 && parts[1] == "siloes") {
          if (length(parts) >= 2) {
            silo_id <- as.integer(parts[2])

            df <- raw_silos()
            if (!nrow(df)) return()

            row <- df[df$SiloID == silo_id, ]
            if (nrow(row) == 0) {
              showNotification(paste0("Silo ID '", silo_id, "' not found"), type = "warning", duration = 2)
              return()
            }

            current_selected <- selected_id()

            if (is.null(current_selected) || current_selected != silo_id) {
              list_result$select_item(silo_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      observe({
        parts <- route()
        if (length(parts) < 1 || parts[1] != "siloes") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        expected_parts <- c("siloes", as.character(sid))

        if (!identical(parts, expected_parts)) {
          session$sendCustomMessage("set-hash", list(h = paste0("#/siloes/", sid)))
        }
      })
    }

    return(list(selected_silo_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_silos_ui <- browser_silos_ui
f_browser_silos_server <- function(id, pool, route = NULL) {
  browser_silos_server(id, pool, route)
}

# Aliases for "siloes" spelling (British English variant used in app.R)
f_browser_siloes_ui <- browser_silos_ui
f_browser_siloes_server <- function(id, pool, route = NULL) {
  browser_silos_server(id, pool, route)
}
