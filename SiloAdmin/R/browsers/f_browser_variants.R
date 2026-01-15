# R/browsers/f_browser_variants.R
# Variants Browser - manage Franklin variants with custom attributes

# =========================== UI ===============================================
f_browser_variants_ui <- function(id) {
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

        # LEFT — compact list (33%)
        div(class = "five wide column",
            # Filter dropdowns
            div(class = "ui form", style = "margin-bottom: 1rem;",
                div(class = "field",
                    div(class = "ui right labeled input", style = "width:100%;",
                        uiOutput(ns("commodity_filter_ui")),
                        div(class = "ui basic label", "Commodity")
                    )
                ),
                div(class = "field",
                    div(class = "ui right labeled input", style = "width:100%;",
                        uiOutput(ns("grain_group_filter_ui")),
                        div(class = "ui basic label", "Grain Group")
                    )
                ),
                div(class = "field",
                    div(class = "ui checkbox",
                        checkboxInput(
                          ns("missing_pattern_only"),
                          "Show only variants without Pattern",
                          value = FALSE
                        )
                    )
                )
            ),

            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by variant number…",
              add_new_item = FALSE
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
f_browser_variants_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to trigger list refresh
    trigger_refresh <- reactiveVal(0)

    # Filter states
    selected_commodity <- reactiveVal(NULL)
    selected_grain_group <- reactiveVal(NULL)

    # ---- Reference data for filters ----
    commodities_list <- reactive({
      trigger_refresh()  # Refresh when data changes
      list_commodities(pool)
    })

    grain_groups_list <- reactive({
      trigger_refresh()
      commodity <- selected_commodity()

      if (!is.null(commodity) && nzchar(commodity)) {
        list_grain_groups_for_commodity(commodity, pool)
      } else {
        list_grain_groups(pool)
      }
    })

    pattern_types <- reactive({
      trigger_refresh()
      list_pattern_types(pool)
    })

    commodity_lookup <- reactive({
      trigger_refresh()
      df <- try(list_commodities_full(pool = pool, active_only = TRUE, limit = 2000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || !nrow(df)) return(list())
      setNames(df$CommodityName, df$CommodityCode)
    })

    grain_group_lookup <- reactive({
      trigger_refresh()
      df <- try(list_grain_groups_full(pool = pool, active_only = TRUE, limit = 3000), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df) || !nrow(df)) return(list())
      setNames(df$GrainGroupName, df$GrainGroupCode)
    })

    # Commodity filter dropdown
    output$commodity_filter_ui <- renderUI({
      commodities <- commodities_list()
      choices <- c("All" = "")
      values  <- c("")
      if (length(commodities) > 0) {
        choices <- c(choices, setNames(commodities, commodities))
        values  <- c(values, commodities)
      }

      di <- shiny.semantic::dropdown_input(
        input_id = ns("commodity_filter"),
        choices = unname(choices),
        choices_value = values,
        value = selected_commodity() %||% "",
        type = "selection"
      )
      di$attribs$class <- paste(di$attribs$class, "fluid")
      di$attribs$style <- paste(di$attribs$style %||% "", "width:100%;")
      di
    })

    # Grain group filter dropdown
    output$grain_group_filter_ui <- renderUI({
      grain_groups <- grain_groups_list()
      choices <- c("All" = "")
      values  <- c("")
      if (length(grain_groups) > 0) {
        choices <- c(choices, setNames(grain_groups, grain_groups))
        values  <- c(values, grain_groups)
      }

      di <- shiny.semantic::dropdown_input(
        input_id = ns("grain_group_filter"),
        choices = unname(choices),
        choices_value = values,
        value = selected_grain_group() %||% "",
        type = "selection"
      )
      di$attribs$class <- paste(di$attribs$class, "fluid")
      di$attribs$style <- paste(di$attribs$style %||% "", "width:100%;")
      di
    })

    # Update filter states
    observeEvent(input$commodity_filter, {
      val <- input$commodity_filter
      selected_commodity(if(!is.null(val) && nzchar(val)) val else NULL)
      # Reset grain group when commodity changes
      selected_grain_group(NULL)
    }, ignoreNULL = FALSE)

    observeEvent(input$grain_group_filter, {
      val <- input$grain_group_filter
      selected_grain_group(if(!is.null(val) && nzchar(val)) val else NULL)
    }, ignoreNULL = FALSE)

    # ---- Data (full list) ----
    raw_variants <- reactive({
      # Depend on trigger and filters
      trigger_refresh()
      commodity <- selected_commodity()
      grain_group <- selected_grain_group()
      # Only filter missing patterns when explicitly checked
      missing_only <- isTRUE(input$missing_pattern_only)

      df <- try(
        list_variants(
          pool = pool,
          commodity = commodity,
          grain_group = grain_group,
          active_only = TRUE,
          missing_pattern = if (missing_only) TRUE else NULL,
          order_col = "MissingPattern DESC, Commodity, GrainGroup, VariantNo",
          limit = 2000
        ), silent = FALSE
      )

      if (inherits(df, "try-error") || is.null(df)) {
        cat("[Variants Browser] Error loading variants:", conditionMessage(attr(df, "condition")), "\n")
        df <- data.frame()
      }

      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_variants()

      if (!nrow(df)) {
        return(data.frame(
          id = character(0),
          icon = character(0),
          title = character(0),
          description = character(0),
          stringsAsFactors = FALSE
        ))
      }

      # Build description with Grain Group, Commodity (use names), and warning for missing pattern
      descriptions <- vapply(seq_len(nrow(df)), function(i) {
        parts <- c()
        comm_code <- df$Commodity[i]
        comm_name <- if (!is.null(comm_code) && !is.na(comm_code) && nzchar(comm_code)) {
          commodity_lookup()[[comm_code]] %||% comm_code
        } else ""
        if (nzchar(comm_name)) {
          parts <- c(parts, paste0("Commodity: ", comm_name))
        }
        gg_code <- df$GrainGroup[i]
        gg_name <- if (!is.null(gg_code) && !is.na(gg_code) && nzchar(gg_code)) {
          grain_group_lookup()[[gg_code]] %||% gg_code
        } else ""
        if (nzchar(gg_name)) {
          parts <- c(parts, paste0("Group: ", gg_name))
        }
        # Add warning if missing Pattern
        if (!is.na(df$MissingPattern[i]) && df$MissingPattern[i] == 1) {
          parts <- c(parts, "Missing Pattern")
        }
        if (length(parts) == 0) return("")
        paste(parts, collapse = " · ")
      }, character(1))

      result <- data.frame(
        id = df$VariantID,
        icon = "",  # No icon for now
        title = df$VariantNo,
        description = descriptions,
        stringsAsFactors = FALSE
      )

      result
    })

    # Use compact list module (no add new, these come from Franklin)
    list_result <- compact_list_server(
      "list",
      items = list_items,
      add_new_item = FALSE,
      initial_selection = "first"
    )

    selected_id <- list_result$selected_id

    # ---- Schema configuration ----
    schema_config <- reactive({
      pattern_options <- pattern_types()

      list(
        fields = list(
          field("VariantNo", "text", title = "Variant Number"),
          field("Commodity", "html", title = "Commodity"),
          field("GrainGroup", "html", title = "Grain Group"),
          field("Pattern", "select", title = "Pattern", enum = pattern_options),
          field("Notes", "textarea", title = "Notes")
        ),
        columns = 1,
        static_fields = c("VariantNo", "Commodity", "GrainGroup")
      )
    })

    # ---- Form data ----
    form_data <- reactive({
      id <- selected_id()
      if (is.null(id) || !nzchar(id)) return(NULL)

      variant <- try(get_variant(as.integer(id), pool), silent = TRUE)

      if (inherits(variant, "try-error") || is.null(variant)) {
        cat("[Variants Browser] Error loading variant", id, "\n")
        return(NULL)
      }

      # Link Commodity and Grain Group to their browsers
      commodity_code <- variant$Commodity
      if (is.null(commodity_code) || is.na(commodity_code)) commodity_code <- ""
      grain_group_code <- variant$GrainGroup
      if (is.null(grain_group_code) || is.na(grain_group_code)) grain_group_code <- ""

      commodity_name <- if (nzchar(commodity_code)) {
        commodity_lookup()[[commodity_code]] %||% commodity_code
      } else ""
      grain_group_name <- if (nzchar(grain_group_code)) {
        grain_group_lookup()[[grain_group_code]] %||% grain_group_code
      } else ""

      variant$Commodity <- if (nzchar(commodity_code)) {
        sprintf(
          '<a href="#/commodities/%s" target="_self">%s</a>',
          htmltools::htmlEscape(commodity_code),
          htmltools::htmlEscape(commodity_name)
        )
      } else {
        ""
      }

      variant$GrainGroup <- if (nzchar(grain_group_code)) {
        sprintf(
          '<a href="#/graingroups/%s" target="_self">%s</a>',
          htmltools::htmlEscape(grain_group_code),
          htmltools::htmlEscape(grain_group_name)
        )
      } else {
        ""
      }

      variant
    })

    # ---- Form module ----
    form_result <- mod_html_form_server(
      "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "VariantNo",
      show_delete_button = FALSE,  # No delete - variants come from Franklin
      on_save = function(values) {
        id <- selected_id()
        if (is.null(id) || !nzchar(id)) {
          showNotification("No variant selected", type = "error")
          return(FALSE)
        }

        # Only update custom attributes (Pattern, Notes)
        result <- try(
          update_variant_attributes(
            variant_id = as.integer(id),
            pattern = values$Pattern,
            notes = values$Notes,
            pool = pool
          ),
          silent = TRUE
        )

        if (inherits(result, "try-error")) {
          showNotification(conditionMessage(attr(result, "condition")), type = "error")
          return(FALSE)
        }

        if (result$success) {
          trigger_refresh(trigger_refresh() + 1)
          return(TRUE)
        }

        showNotification(result$message, type = "error")
        return(FALSE)
      },
      on_delete = NULL  # No delete - variants come from Franklin
    )

    # ---- Deep-linking support ----
    if (!is.null(route) && shiny::is.reactive(route)) {
      observeEvent(route(), {
        parts <- route()

        # Only handle if we're on the variants page
        if (length(parts) >= 1 && parts[1] == "variants") {
          if (length(parts) >= 2) {
            variant_id <- suppressWarnings(as.integer(parts[2]))
            if (is.na(variant_id)) return()

            df <- raw_variants()
            if (!nrow(df)) return()

            row <- df[df$VariantID == variant_id, ]
            if (nrow(row) == 0) {
              showNotification(paste0("Variant ID '", variant_id, "' not found"), type = "warning", duration = 2)
              return()
            }

            current_selected <- selected_id()
            if (is.null(current_selected) || current_selected != variant_id) {
              list_result$select_item(variant_id)
            }
          }
        }
      }, ignoreInit = TRUE)

      # Update URL when selection changes (only while on variants page)
      observe({
        parts <- route()
        if (length(parts) < 1 || parts[1] != "variants") return()

        vid <- selected_id()
        if (is.null(vid) || is.na(vid)) return()

        expected_parts <- c("variants", as.character(vid))
        if (!identical(parts, expected_parts)) {
          session$sendCustomMessage("set-hash", list(h = paste0("#/variants/", vid)))
        }
      })
    }
  })
}
