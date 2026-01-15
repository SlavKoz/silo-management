# R/browsers/f_browser_commodities.R
# Browser for commodities (colour system v2)

f_browser_commodities_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "ui grid stackable",
        div(class = "six wide column",
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by commodity code or name",
              add_new_item = FALSE
            )
        ),
        div(class = "ten wide column",
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
        )
    )
  )
}

f_browser_commodities_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Palette for display-friendly colours (name -> hex)
    colour_palette <- c(
      "Blue"       = "#1D4ED8",
      "Sky"        = "#0284C7",
      "Teal"       = "#0D9488",
      "Green"      = "#059669",
      "Lime"       = "#65A30D",
      "Gold"       = "#D97706",
      "Orange"     = "#EA580C",
      "Red"        = "#DC2626",
      "Rose"       = "#E11D48",
      "Purple"     = "#7C3AED",
      "Indigo"     = "#4338CA",
      "Brown"      = "#92400E",
      "Gray"       = "#4B5563",
      "Slate"      = "#334155",
      "Black"      = "#111827"
    )
    colour_enum <- names(colour_palette)

    refresh <- reactiveVal(0)
    gg_version <- session$userData$graingroups_version

    # ---- Fetch icons for picker ----
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

    commodities <- reactive({
      refresh()
      df <- try(list_commodities_full(pool = pool, active_only = TRUE, limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        cat("[Commodities] Error loading commodities:", conditionMessage(attr(df, "condition")), "\n")
        return(data.frame())
      }
      df
    })

    list_items <- reactive({
      df <- commodities()
      if (!nrow(df)) {
        return(data.frame(id = character(0), icon = character(0), title = character(0), description = character(0), stringsAsFactors = FALSE))
      }

      # Build title as "Code - Name"
      titles <- vapply(seq_len(nrow(df)), function(i) {
        paste(df$CommodityCode[i], "-", df$CommodityName[i])
      }, character(1))

      icons <- vapply(seq_len(nrow(df)), function(i) {
        hex <- df$BaseColour[i]
        if (is.na(hex) || !nzchar(hex)) return("")
        sprintf("<div style='width:14px;height:14px;border:1px solid #ccc;border-radius:3px;background:%s;'></div>", htmltools::htmlEscape(hex))
      }, character(1))

      data.frame(
        id = df$CommodityID,
        icon = icons,
        title = titles,
        description = "",
        stringsAsFactors = FALSE
      )
    })

    list_result <- compact_list_server(
      "list",
      items = list_items,
      add_new_item = FALSE,
      initial_selection = "first"
    )

    selected_id <- list_result$selected_id

    schema_config <- reactive({
      icon_info <- icons_data()

      list(
        fields = list(
          # Column 1 - Basic Info
          field("CommodityCode", "text", title = "Commodity Code", column = 1),
          field("CommodityName", "text", title = "Commodity Name", column = 1),
          field("IsMajor", "switch", title = "Major Commodity", column = 1),
          field("Notes", "textarea", title = "Notes", column = 1),

          # Column 2 - Visual Details group (collapsed)
          field("IconID", "select", title = "Icon", enum = icon_info$choices, widget = "icon-select", icon_metadata = icon_info$metadata, column = 2, group = "VisualDetails"),
          field("ColourName", "select", title = "Colour", enum = colour_enum, column = 2, group = "VisualDetails"),
          field("ColourSwatch", "html", title = "Colour Preview", column = 2, group = "VisualDetails"),
          field("BaseColour", "text", title = "Base Colour (hex)", column = 2, group = "VisualDetails"),
          field("DisplayOrder", "text", title = "Display Order", column = 2, group = "VisualDetails"),
          field("IsActive", "switch", title = "Active", column = 2, group = "VisualDetails"),

          # Column 2 - Grain Groups (no group wrapper)
          field("GrainGroups", "html", title = "Grain Groups", column = 2)
        ),
        groups = list(
          group("VisualDetails", title = "Visual Details", collapsible = TRUE, collapsed = TRUE, column = 2)
        ),
        columns = 2,
        static_fields = c("CommodityCode", "CommodityName", "BaseColour", "ColourSwatch", "GrainGroups")
      )
    })

    form_data <- reactive({
      refresh()  # refresh trigger after save
      id <- selected_id()
      if (is.null(id) || !nzchar(id)) return(NULL)
      data <- try(get_commodity(as.integer(id), pool), silent = TRUE)
      if (inherits(data, "try-error") || is.null(data)) {
        cat("[Commodities] Error loading commodity", id, "\n")
        return(NULL)
      }

      # Build colour swatch
      swatch <- ""
      if (nzchar(data$BaseColour %||% "")) {
        swatch <- sprintf("<div style='width:14px;height:14px;border:1px solid #ccc;border-radius:3px;background:%s;display:inline-block;vertical-align:middle;margin-right:6px;'></div>", htmltools::htmlEscape(data$BaseColour))
      }
      label <- data$ColourName %||% ""
      colour_swatch <- if (nzchar(swatch) || nzchar(label)) sprintf("%s<span>%s</span>", swatch, htmltools::htmlEscape(label)) else ""

      # Build grain groups HTML as a list
      code <- data$CommodityCode
      df_gg <- try(list_grain_groups_full(pool = pool, active_only = TRUE, commodity_code = code, limit = 200), silent = TRUE)
      grain_groups_html <- ""
      if (!inherits(df_gg, "try-error") && !is.null(df_gg) && nrow(df_gg) > 0) {
        # Build HTML list items for each grain group
        gg_items <- vapply(seq_len(nrow(df_gg)), function(i) {
          sprintf('<li><a href="#/graingroups/%s" target="_self">%s - %s</a></li>',
                  df_gg$GrainGroupCode[i],
                  df_gg$GrainGroupCode[i],
                  df_gg$GrainGroupName[i])
        }, character(1))
        grain_groups_html <- sprintf('<ul style="margin: 0; padding-left: 1.5rem;">%s</ul>',
                                      paste(gg_items, collapse = ""))
      } else {
        grain_groups_html <- '<span style="color: #999; font-style: italic;">No grain groups found</span>'
      }

      # Build nested structure for groups
      list(
        CommodityID = data$CommodityID,
        CommodityCode = data$CommodityCode,
        CommodityName = data$CommodityName,
        IsMajor = as.logical(data$IsMajor %||% FALSE),
        Notes = data$Notes %||% "",
        VisualDetails = list(
          IconID = as.character(f_or(data$Icon, "")),
          ColourName = data$ColourName %||% "",
          ColourSwatch = colour_swatch,
          BaseColour = data$BaseColour %||% "",
          DisplayOrder = data$DisplayOrder %||% "",
          IsActive = as.logical(data$IsActive %||% FALSE)
        ),
        GrainGroups = grain_groups_html
      )
    })

    # Add colour swatch column to compact list (as a colored block)
    observe({
      df <- commodities()
      if (!nrow(df)) return()
      shades <- as.list(setNames(df$BaseColour, df$CommodityID))
      session$sendCustomMessage("compact-list-set-colours", list(
        id = ns("list"),
        colours = shades
      ))
    })

    form_module <- mod_html_form_server(
      "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "CommodityName",
      show_delete_button = FALSE,
      on_save = function(values) {
        id <- selected_id()
        if (is.null(id) || !nzchar(id)) {
          showNotification("No commodity selected", type = "error")
          return(FALSE)
        }

        # Extract values from nested group structure
        colour_name <- values$VisualDetails$ColourName
        base_colour <- values$VisualDetails$BaseColour
        # Keep name/hex aligned
        if (!is.null(colour_name) && nzchar(colour_name) && !is.null(colour_palette[[colour_name]])) {
          base_colour <- colour_palette[[colour_name]]
        } else if (!is.null(base_colour) && base_colour %in% unname(colour_palette)) {
          nm <- names(colour_palette)[match(base_colour, unname(colour_palette))]
          if (!is.na(nm)) colour_name <- nm
        }

        result <- update_commodity_attributes(
          commodity_id = as.integer(id),
          base_colour = base_colour,
          colour_name = colour_name,
          display_order = if (nzchar(values$VisualDetails$DisplayOrder %||% "")) as.integer(values$VisualDetails$DisplayOrder) else NULL,
          notes = values$Notes,
          is_active = if (isTRUE(values$VisualDetails$IsActive)) 1L else 0L,
          is_major = if (isTRUE(values$IsMajor)) 1L else 0L,
          icon = if (nzchar(values$VisualDetails$IconID %||% "")) values$VisualDetails$IconID else NULL,
          pool = pool
        )

        if (!isTRUE(result$success)) {
          showNotification(result$message, type = "error")
          return(FALSE)
        }

        # Recompute dependent grain group colours
        try(DBI::dbExecute(pool, "EXEC dbo.sp_RecalculateGrainGroupColours @CommodityID = ?", params = list(as.integer(id))), silent = TRUE)

        # Bump shared version so grain groups browser can refresh
        if (!is.null(gg_version) && is.reactive(gg_version)) {
          gg_version(gg_version() + 1)
        }

        refresh(refresh() + 1)
        showNotification("Saved", type = "message")
        TRUE
      },
      on_delete = NULL
    )

    # Refresh dynamic selects (icons) when edit mode is entered
    observeEvent(form_module$edit_refresh_trigger(), {
      icons_data(fetch_icons())
    }, ignoreInit = TRUE)

    # Deep-linking support
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()
        if (length(parts) >= 1 && parts[1] == "commodities") {
          if (length(parts) >= 2) {
            # URL-decode the commodity code to handle spaces and special characters
            code <- utils::URLdecode(parts[2])
            df <- commodities()
            if (!nrow(df)) return()
            row <- df[df$CommodityCode == code, ]
            if (!nrow(row)) {
              showNotification(paste0("Commodity '", code, "' not found"), type = "warning", duration = 2)
              return()
            }
            cid <- row$CommodityID[1]
            if (!identical(selected_id(), cid)) {
              list_result$select_item(cid)
            }
          }
        }
      }, ignoreInit = TRUE)

      observe({
        parts <- route()
        if (length(parts) < 1 || parts[1] != "commodities") return()
        cid <- selected_id()
        if (is.null(cid) || is.na(cid)) return()
        df <- commodities()
        if (!nrow(df)) return()
        row <- df[df$CommodityID == cid, ]
        if (!nrow(row)) return()
        code <- row$CommodityCode[1]

        # URL-decode the current route part for comparison
        current_code <- if (length(parts) >= 2) utils::URLdecode(parts[2]) else NULL

        # Check if we need to update the route (compare decoded values)
        if (is.null(current_code) || current_code != code) {
          # URL-encode the commodity code for the URL
          encoded_code <- utils::URLencode(code, reserved = TRUE)
          session$sendCustomMessage("set-hash", list(h = paste0("#/commodities/", encoded_code)))
        }
      })
    }

  })
}
