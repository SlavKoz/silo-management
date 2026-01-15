# R/browsers/f_browser_graingroups.R
# Browser for grain groups (relative colour system)

f_browser_graingroups_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(tags$style(HTML("
      .ui.dropdown,
      .ui.dropdown .text,
      .ui.dropdown .menu .item { font-size: 13px; }
      /* Make labeled dropdown full width (match Aux) */
      .ui.right.labeled.input { display: flex; align-items: stretch; width: 100%; }
      .ui.right.labeled.input > .ui.dropdown { flex: 1 1 auto; min-width: 0; width: 100%; }
      .ui.right.labeled.input > .label { flex: 0 0 auto; }
    "))),
    div(class = "ui grid stackable",
        div(class = "six wide column",
            tagList(
              # Commodity filter dropdown with right label
              div(style = "margin-bottom: 0.5rem;",
                  div(class = "ui right labeled input", style = "width:100%;",
                      uiOutput(ns("commodity_filter_ui")),
                      div(class = "ui basic label", "Commodity")
                  )
              ),
              compact_list_ui(
                ns("list"),
                show_filter = TRUE,
                filter_placeholder = "Filter by grain group code or name",
                add_new_item = FALSE
              )
            )
        ),
        div(class = "ten wide column",
            mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
        )
    )
  )
}

f_browser_graingroups_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    refresh <- reactiveVal(0)
    gg_version <- session$userData$graingroups_version

    # Load commodities for filter dropdown
    commodities <- reactive({
      df <- try(list_commodities_full(pool = pool, active_only = TRUE, limit = 1000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) {
        return(data.frame())
      }
      df
    })

    # Render commodity filter dropdown
    output$commodity_filter_ui <- renderUI({
      df <- commodities()
      if (!nrow(df)) {
        return(shiny.semantic::dropdown_input(
          input_id = ns("commodity_filter"),
          choices = c("All Commodities"),
          choices_value = c(""),
          value = "",
          type = "fluid selection"
        ))
      }

      choices <- c("All Commodities" = "")
      commodity_choices <- setNames(df$CommodityCode, df$CommodityCode)
      choices <- c(choices, commodity_choices)

      di <- shiny.semantic::dropdown_input(
        input_id = ns("commodity_filter"),
        choices = unname(choices),
        choices_value = unname(c("", df$CommodityCode)),
        value = "",
        type = "selection"
      )
      di$attribs$class <- paste(di$attribs$class, "fluid")
      di$attribs$style <- paste(di$attribs$style %||% "", "width:100%;")
      di
    })

    graingroups <- reactive({
      refresh()
      if (!is.null(gg_version) && is.reactive(gg_version)) gg_version()

      # Get commodity filter value
      comm_code <- input$commodity_filter %||% ""

      df <- try(list_grain_groups_full(
        pool = pool,
        active_only = TRUE,
        commodity_code = if (nzchar(comm_code)) comm_code else NULL,
        limit = 1000
      ), silent = TRUE)

      if (inherits(df, "try-error") || is.null(df)) {
        cat("[GrainGroups] Error loading grain groups:", conditionMessage(attr(df, "condition")), "\n")
        return(data.frame())
      }
      df
    })

    list_items <- reactive({
      df <- graingroups()
      if (!nrow(df)) {
        return(data.frame(id = character(0), icon = character(0), title = character(0), description = character(0), stringsAsFactors = FALSE))
      }

      # Build title as "Code - Name"
      titles <- vapply(seq_len(nrow(df)), function(i) {
        paste(df$GrainGroupCode[i], "-", df$GrainGroupName[i])
      }, character(1))

      # Build description showing commodity code
      descriptions <- vapply(seq_len(nrow(df)), function(i) {
        if (!is.na(df$CommodityCode[i]) && nzchar(df$CommodityCode[i])) {
          df$CommodityCode[i]
        } else {
          ""
        }
      }, character(1))

      icons <- vapply(seq_len(nrow(df)), function(i) {
        hex <- df$BaseColour[i]
        if (is.na(hex) || !nzchar(hex)) return("")
        sprintf("<div style='width:14px;height:14px;border:1px solid #ccc;border-radius:3px;background:%s;'></div>", htmltools::htmlEscape(hex))
      }, character(1))

      data.frame(
        id = df$GrainGroupID,
        icon = icons,
        title = titles,
        description = descriptions,
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
      list(
        fields = list(
          # Column 1 - Basic Info
          field("GrainGroupCode", "text", title = "Grain Group Code", column = 1),
          field("GrainGroupName", "text", title = "Grain Group Name", column = 1),
          field("CommodityName", "html", title = "Commodity", column = 1),
          field("Notes", "textarea", title = "Notes", column = 1),

          # Column 2 - Visual Details group (collapsed)
          field("ColourSwatch", "html", title = "Colour Preview", column = 2, group = "VisualDetails"),
          field("BaseColour", "text", title = "Computed Colour (hex)", column = 2, group = "VisualDetails"),
          field("CommodityBaseColour", "text", title = "Commodity Base Colour (hex)", column = 2, group = "VisualDetails"),
          field("LightnessModifier", "text", title = "Lightness Modifier", column = 2, group = "VisualDetails"),
          field("DisplayOrder", "text", title = "Display Order", column = 2, group = "VisualDetails"),
          field("IsActive", "switch", title = "Active", column = 2, group = "VisualDetails"),

          # Column 2 - Variants
          field("Variants", "html", title = "Variants", column = 2)
        ),
        groups = list(
          group("VisualDetails", title = "Visual Details", collapsible = TRUE, collapsed = TRUE, column = 2)
        ),
        columns = 2,
        static_fields = c("GrainGroupCode", "GrainGroupName", "CommodityName",
                          "VisualDetails.ColourSwatch", "VisualDetails.BaseColour", "VisualDetails.CommodityBaseColour", "Variants")
      )
    })

    form_data <- reactive({
      # refresh dependency if commodities update triggers colour recompute elsewhere
      refresh_trigger <- NULL  # placeholder for future triggers
      id <- selected_id()
      if (is.null(id) || !nzchar(id)) return(NULL)
      data <- try(get_grain_group(as.integer(id), pool), silent = TRUE)
      if (inherits(data, "try-error") || is.null(data)) {
        cat("[GrainGroups] Error loading grain group", id, "\n")
        return(NULL)
      }

      # Build a computed colour label using commodity hue + lightness
      hue_name <- data$CommodityColourName %||% data$ColourName %||% ""
      lm <- data$LightnessModifier
      label <- hue_name
      if (!is.null(lm) && !is.na(lm) && nzchar(hue_name)) {
        label <- sprintf("%s x%.2f", hue_name, lm)
      } else if (!is.null(lm) && !is.na(lm)) {
        label <- sprintf("x%.2f", lm)
      }
      swatch <- ""
      if (nzchar(data$BaseColour %||% "")) {
        swatch <- sprintf("<div style='width:14px;height:14px;border:1px solid #ccc;border-radius:3px;background:%s;display:inline-block;vertical-align:middle;margin-right:6px;'></div>", htmltools::htmlEscape(data$BaseColour))
      }
      colour_swatch <- if (nzchar(label) || nzchar(swatch)) sprintf("%s<span>%s</span>", swatch, label) else ""

      # Build hyperlinked commodity name
      commodity_code <- data$CommodityCode %||% ""
      commodity_name <- data$CommodityName %||% ""
      commodity_html <- if (nzchar(commodity_code) && nzchar(commodity_name)) {
        sprintf('<a href="#/commodities/%s" target="_self">%s</a>', commodity_code, htmltools::htmlEscape(commodity_name))
      } else {
        htmltools::htmlEscape(commodity_name)
      }

      # Build variants HTML as a list
      grain_group_code <- data$GrainGroupCode
      df_variants <- try(list_variants(pool = pool, grain_group = grain_group_code, active_only = TRUE, limit = 200), silent = TRUE)
      variants_html <- ""
      if (!inherits(df_variants, "try-error") && !is.null(df_variants) && nrow(df_variants) > 0) {
        # Build HTML list items for each variant
        variant_items <- vapply(seq_len(nrow(df_variants)), function(i) {
          sprintf('<li><a href="#/variants/%s" target="_self">%s</a></li>',
                  df_variants$VariantNo[i],
                  df_variants$VariantNo[i])
        }, character(1))
        variants_html <- sprintf('<ul style="margin: 0; padding-left: 1.5rem;">%s</ul>',
                                  paste(variant_items, collapse = ""))
      } else {
        variants_html <- '<span style="color: #999; font-style: italic;">No variants found</span>'
      }

      # Build nested structure for groups
      list(
        GrainGroupID = data$GrainGroupID,
        GrainGroupCode = data$GrainGroupCode,
        GrainGroupName = data$GrainGroupName,
        CommodityName = commodity_html,
        CommodityID = data$CommodityID,  # Keep for save handler
        Notes = data$Notes %||% "",
        VisualDetails = list(
          LightnessModifier = if (!is.null(data$LightnessModifier) && !is.na(data$LightnessModifier)) as.character(data$LightnessModifier) else "",
          ColourSwatch = colour_swatch,
          BaseColour = data$BaseColour %||% "",
          CommodityBaseColour = data$CommodityBaseColour %||% "",
          DisplayOrder = data$DisplayOrder %||% "",
          IsActive = as.logical(data$IsActive %||% FALSE)
        ),
        Variants = variants_html
      )
    })

    # Add colour swatch column to compact list (as a colored block)
    observe({
      df <- graingroups()
      if (!nrow(df)) return()
      shades <- as.list(setNames(df$BaseColour, df$GrainGroupID))
      session$sendCustomMessage("compact-list-set-colours", list(
        id = ns("list"),
        colours = shades
      ))
    })

    mod_html_form_server(
      "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "GrainGroupName",
      show_delete_button = FALSE,
      on_save = function(values) {
        id <- selected_id()
        if (is.null(id) || !nzchar(id)) {
          showNotification("No grain group selected", type = "error")
          return(FALSE)
        }

        result <- update_grain_group_attributes(
          grain_group_id = as.integer(id),
          lightness_modifier = if (nzchar(values$VisualDetails$LightnessModifier %||% "")) as.numeric(values$VisualDetails$LightnessModifier) else NULL,
          colour_name = NULL,  # colour name is computed/display-only
          display_order = if (nzchar(values$VisualDetails$DisplayOrder %||% "")) as.integer(values$VisualDetails$DisplayOrder) else NULL,
          notes = values$Notes,
          is_active = if (isTRUE(values$VisualDetails$IsActive)) 1L else 0L,
          pool = pool
        )

        if (!isTRUE(result$success)) {
          showNotification(result$message, type = "error")
          return(FALSE)
        }

        # Recompute computed colours for this commodity
        current <- form_data()
        commodity_id <- suppressWarnings(as.integer(current$CommodityID %||% NA))
        cid_param <- if (is.na(commodity_id)) NULL else commodity_id
        try(DBI::dbExecute(pool, "EXEC dbo.sp_RecalculateGrainGroupColours @CommodityID = ?", params = list(cid_param)), silent = TRUE)

        if (!is.null(gg_version) && is.reactive(gg_version)) {
          gg_version(gg_version() + 1)
        }
        refresh(refresh() + 1)
        showNotification("Saved", type = "message")
        TRUE
      },
      on_delete = NULL
    )

    # Deep-linking support
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()
        if (length(parts) >= 1 && parts[1] == "graingroups") {
          if (length(parts) >= 2) {
            # URL-decode the grain group code to handle spaces and special characters
            code <- utils::URLdecode(parts[2])
            df <- graingroups()
            if (!nrow(df)) return()
            row <- df[df$GrainGroupCode == code, ]
            if (!nrow(row)) {
              showNotification(paste0("Grain Group '", code, "' not found"), type = "warning", duration = 2)
              return()
            }
            gid <- row$GrainGroupID[1]
            if (!identical(selected_id(), gid)) {
              list_result$select_item(gid)
            }
          }
        }
      }, ignoreInit = TRUE)

      observe({
        parts <- route()
        if (length(parts) < 1 || parts[1] != "graingroups") return()
        gid <- selected_id()
        if (is.null(gid) || is.na(gid)) return()
        df <- graingroups()
        if (!nrow(df)) return()
        row <- df[df$GrainGroupID == gid, ]
        if (!nrow(row)) return()
        code <- row$GrainGroupCode[1]

        # URL-decode the current route part for comparison
        current_code <- if (length(parts) >= 2) utils::URLdecode(parts[2]) else NULL

        # Check if we need to update the route (compare decoded values)
        if (is.null(current_code) || current_code != code) {
          # URL-encode the grain group code for the URL
          encoded_code <- utils::URLencode(code, reserved = TRUE)
          session$sendCustomMessage("set-hash", list(h = paste0("#/graingroups/", encoded_code)))
        }
      })
    }
  })
}
