# R/browsers/f_browser_sites.R
# Sites Browser

# =========================== UI ===============================================
browser_sites_ui <- function(id) {
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
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0"),

            # Map preview (shown when location data exists and not editing)
            uiOutput(ns("map_preview"))
        )
    )
  )
}

# ========================== SERVER ============================================
browser_sites_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # ---- Data (full list) ----
    raw_sites <- reactive({
      # Depend on trigger to force refresh
      trigger_refresh()
      df <- try(
        list_sites(
          code_like = NULL,
          order_col = "SiteCode",
          limit     = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Create styled 3-letter code icon
      df$IconDisplay <- vapply(seq_len(nrow(df)), function(i) {
        code_3 <- toupper(substr(df$SiteCode[i], 1, 3))
        sprintf(
          '<div style="display:inline-block; width:32px; height:32px; background:#2563eb; color:#fff; font-weight:bold; font-size:11px; text-align:center; line-height:32px; border-radius:4px;">%s</div>',
          code_3
        )
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_sites()
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
        id = df$SiteID,
        icon = df$IconDisplay,
        title = toupper(df$SiteName),
        description = df$SiteCode,
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
          field("SiteName",       "text",     title="Name", column = 1, required = TRUE),
          field("SiteCode",       "text",     title="Code", column = 1, required = TRUE),
          field("IsActive",       "switch",   title="Active", column = 1, default = TRUE),

          # Column 2 - Address
          field("AddressLine1",   "text",   title="Address Line", group="Address"),
          field("AddressLine2",   "text",   title="", group="Address"),
          field("City",           "text",   title="City", group="Address"),
          field("County",         "text",   title="County", group="Address"),
          field("Postcode",       "text",   title="Postcode", group="Address"),

          # Column 2 - Location
          field("Latitude",       "number", title="Latitude",  group="Location"),
          field("Longitude",      "number", title="Longitude", group="Location"),
          field("GoogleMapsURL",  "text",   title="Google Maps URL", group="Location"),

          # Column 2 - Areas (static display with links)
          field("AreasDisplay",   "text",   title="", group="Areas")
        ),
        groups = list(
          group("Address",  title="Address",  collapsible=TRUE, collapsed=FALSE, column=2),
          group("Location", title="Location", collapsible=TRUE, collapsed=TRUE, column=2),
          group("Areas",    title="Areas",    collapsible=TRUE, collapsed=FALSE, column=2)
        ),
        columns = 2,
        static_fields = c("Areas.AreasDisplay")
      )
    })

    # ---- Reactive form data based on selection ----
    form_data <- reactive({
      # Depend on trigger_refresh to re-fetch after save
      trigger_refresh()

      # Depend on areas_version to refresh when areas change
      if (!is.null(session$userData$areas_version)) {
        session$userData$areas_version
      }

      sid <- selected_id()

      # No selection - return empty data
      if (is.null(sid)) {
        return(list(
          SiteName = "",
          SiteCode = "",
          IsActive = TRUE,
          Address = list(
            AddressLine1 = "",
            AddressLine2 = "",
            City = "",
            County = "",
            Postcode = ""
          ),
          Location = list(
            Latitude = NA_real_,
            Longitude = NA_real_,
            GoogleMapsURL = ""
          ),
          Areas = list(
            AreasDisplay = ""
          )
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          SiteName = "",
          SiteCode = "",
          IsActive = TRUE,
          Address = list(
            AddressLine1 = "",
            AddressLine2 = "",
            City = "",
            County = "",
            Postcode = ""
          ),
          Location = list(
            Latitude = NA_real_,
            Longitude = NA_real_,
            GoogleMapsURL = ""
          ),
          Areas = list(
            AreasDisplay = ""
          )
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_site_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Fetch areas for this site
      areas_html <- ""
      site_id <- as.integer(df1$SiteID)
      site_code <- f_or(df1$SiteCode, "")

      if (!is.na(site_id) && nzchar(site_code)) {
        areas_df <- try(list_areas(site_id = site_id, limit = 100), silent = TRUE)
        if (!inherits(areas_df, "try-error") && !is.null(areas_df) && nrow(areas_df) > 0) {
          # Build HTML list of area links
          area_links <- sapply(seq_len(nrow(areas_df)), function(i) {
            composite_code <- paste0(site_code, "-", areas_df$AreaCode[i])
            area_url <- paste0("#/areas/", composite_code)
            sprintf('<a href="%s" style="color: #059669; text-decoration: none; font-weight: 500;">%s</a> <span style="color: #6b7280;">%s</span>',
                    area_url, composite_code, areas_df$AreaName[i])
          })
          areas_html <- paste(area_links, collapse = "<br>")
        } else {
          areas_html <- '<span style="color: #9ca3af; font-style: italic;">No areas defined</span>'
        }
      }

      # Transform to nested format
      list(
        SiteID = as.integer(f_or(df1$SiteID, 0)),  # Include ID for updates
        SiteName = f_or(df1$SiteName, ""),
        SiteCode = f_or(df1$SiteCode, ""),
        IsActive = as.logical(f_or(df1$IsActive, TRUE)),
        Address = list(
          AddressLine1 = f_or(df1$AddressLine1, ""),
          AddressLine2 = f_or(df1$AddressLine2, ""),
          City = f_or(df1$City, ""),
          County = f_or(df1$County, ""),
          Postcode = f_or(df1$Postcode, "")
        ),
        Location = list(
          Latitude = if (!is.null(df1$Latitude) && !is.na(df1$Latitude)) as.numeric(df1$Latitude) else NA_real_,
          Longitude = if (!is.null(df1$Longitude) && !is.na(df1$Longitude)) as.numeric(df1$Longitude) else NA_real_,
          GoogleMapsURL = f_or(df1$GoogleMapsURL, "")
        ),
        Areas = list(
          AreasDisplay = areas_html
        )
      )
    })

    # ---- Initialize HTML form module ----
    form_module <- NULL

    form_module <- mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "SiteName",
      show_header = TRUE,
      show_delete_button = TRUE,
      on_save = function(data) {
        tryCatch({
          # Check if we're in "add new" mode before saving
          is_new_record <- is.na(selected_id())

          # Flatten nested structure for database
          flat_data <- list(
            SiteID = data$SiteID,
            SiteCode = data$SiteCode,
            SiteName = data$SiteName,
            IsActive = data$IsActive,
            Latitude = data$Location$Latitude,
            Longitude = data$Location$Longitude,
            GoogleMapsURL = data$Location$GoogleMapsURL,
            AddressLine1 = data$Address$AddressLine1,
            AddressLine2 = data$Address$AddressLine2,
            City = data$Address$City,
            County = data$Address$County,
            Postcode = data$Address$Postcode
          )

          # Save to database
          saved_id <- upsert_site(flat_data)

          # If this was a new record, select it using the list module's method
          if (is_new_record && !is.null(saved_id) && !is.na(saved_id)) {
            list_result$select_item(as.integer(saved_id))
          }

          # Trigger list refresh to show the new item
          trigger_refresh(trigger_refresh() + 1)

          return(TRUE)
        }, error = function(e) {
          error_msg <- conditionMessage(e)
          cat("[Site Save Error]:", error_msg, "\n")

          # Parse error message for user-friendly display
          field_to_clear <- NULL
          user_msg <- NULL

          if (grepl("UNIQUE KEY constraint", error_msg, ignore.case = TRUE)) {
            # Duplicate key - typically the SiteCode field
            field_to_clear <- "SiteCode"
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

    # ---- Map preview ----
    output$map_preview <- renderUI({
      # Get current form data
      data <- form_data()
      sid <- selected_id()

      # Don't show map for null or new records
      if (is.null(sid) || is.na(sid)) return(NULL)

      # Check if we have location data
      lat <- data$Location$Latitude
      lon <- data$Location$Longitude

      if (is.null(lat) || is.na(lat) || is.null(lon) || is.na(lon)) {
        return(NULL)
      }

      # Validate coordinates
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        return(NULL)
      }

      # Build map URLs
      zoom <- 15
      osm_url <- sprintf("https://www.openstreetmap.org/export/embed.html?bbox=%.6f,%.6f,%.6f,%.6f&marker=%.6f,%.6f&layer=mapnik",
                         lon - 0.01, lat - 0.01, lon + 0.01, lat + 0.01, lat, lon)

      # For aerial view, use uMap with Esri satellite tiles
      aerial_url <- sprintf("https://umap.openstreetmap.fr/en/map/new/#%d/%.6f/%.6f", zoom, lat, lon)

      # Google Maps link for fullscreen
      gmaps_url <- sprintf("https://www.google.com/maps?q=%.6f,%.6f&z=%d", lat, lon, zoom)

      map_id <- ns("map_frame")

      # Render map container with controls
      tagList(
        div(
          style = "margin-top: 1rem; padding: 0.75rem; background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 4px;",

          # Header with controls
          div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;",
            div(style = "font-size: 11px; font-weight: 600; color: #374151;",
                "Location Preview"),
            div(style = "display: flex; gap: 0.5rem;",
              # Layer switcher buttons
              tags$button(
                class = "ui mini basic button",
                style = "font-size: 10px; padding: 0.3rem 0.5rem;",
                onclick = sprintf("document.getElementById('%s').src='%s'", map_id, osm_url),
                "Standard"
              ),
              tags$button(
                class = "ui mini basic button",
                style = "font-size: 10px; padding: 0.3rem 0.5rem;",
                onclick = sprintf("window.open('%s', '_blank')", gmaps_url),
                tags$i(class = "satellite icon", style = "margin: 0;"),
                "Aerial"
              ),
              tags$button(
                class = "ui mini basic icon button",
                style = "font-size: 10px; padding: 0.3rem 0.5rem;",
                onclick = sprintf("window.open('%s', '_blank')", gmaps_url),
                tags$i(class = "expand icon", style = "margin: 0;")
              )
            )
          ),

          # Map iframe
          tags$iframe(
            id = map_id,
            src = osm_url,
            width = "100%",
            height = "300",
            style = "border: 1px solid #d1d5db; border-radius: 4px;",
            frameborder = "0"
          ),

          # Coordinates display
          div(style = "font-size: 10px; color: #6b7280; margin-top: 0.5rem; text-align: center;",
              sprintf("Lat: %.6f, Lon: %.6f", lat, lon))
        )
      )
    })

    # --- Deep-linking support ---
    # If route reactive is provided, observe URL changes
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        # Only handle if we're on the sites page
        if (length(parts) >= 1 && parts[1] == "sites") {
          # If there's an item ID, select it
          if (length(parts) >= 2) {
            # URL-decode the site code to handle spaces and special characters
            site_code <- utils::URLdecode(parts[2])

            # Look up SiteID for this SiteCode
            df <- raw_sites()
            if (!nrow(df)) return()

            row <- df[df$SiteCode == site_code, ]
            if (nrow(row) == 0) {
              showNotification(paste0("Site '", site_code, "' not found"), type = "warning", duration = 2)
              return()
            }

            # Select the item by its numeric ID
            site_id <- as.integer(row$SiteID[1])
            current_selected <- selected_id()

            # Only update if different from current selection
            if (is.null(current_selected) || current_selected != site_id) {
              list_result$select_item(site_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes - BUT ONLY if we're on the sites page
      observe({
        parts <- route()

        # Only update URL if we're currently on the sites page
        if (length(parts) < 1 || parts[1] != "sites") return()

        sid <- selected_id()
        if (is.null(sid) || is.na(sid)) return()

        # Get SiteCode for currently selected SiteID
        df <- raw_sites()
        if (!nrow(df)) return()

        row <- df[df$SiteID == sid, ]
        if (nrow(row) == 0) return()

        site_code <- as.character(row$SiteCode[1])

        # URL-decode the current route part for comparison
        current_code <- if (length(parts) >= 2) utils::URLdecode(parts[2]) else NULL

        # Check if we need to update the route (compare decoded values)
        if (is.null(current_code) || current_code != site_code) {
          # URL-encode the site code for the URL
          encoded_code <- utils::URLencode(site_code, reserved = TRUE)
          session$sendCustomMessage("set-hash", list(h = paste0("#/sites/", encoded_code)))
        }
      })
    }

    return(list(selected_site_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_sites_ui <- browser_sites_ui
f_browser_sites_server <- function(id, pool, route = NULL) {
  browser_sites_server(id, pool, route)
}
