# R/browsers/f_browser_variants.R
# Variants Browser - manage Franklin variants with custom attributes

# =========================== UI ===============================================
f_browser_variants_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Warning banner at top
    uiOutput(ns("missing_colour_warning")),

    div(class = "ui grid stackable",

        # LEFT — compact list (33%)
        div(class = "five wide column",
            # Filter dropdowns
            div(class = "ui form", style = "margin-bottom: 1rem;",
                div(class = "field",
                    tags$label("Commodity"),
                    uiOutput(ns("commodity_filter_ui"))
                ),
                div(class = "field",
                    tags$label("Grain Group"),
                    uiOutput(ns("grain_group_filter_ui"))
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

    # Warning banner for missing patterns
    output$missing_colour_warning <- renderUI({
      trigger_refresh()  # Refresh when data changes

      count <- try(count_variants_missing_pattern(pool), silent = TRUE)
      if (inherits(count, "try-error") || is.null(count) || count == 0) {
        return(NULL)
      }

      div(class = "ui info message", style = "margin: 0.5rem 0 1rem 0;",
          tags$i(class = "info circle icon"),
          div(class = "header", "Missing Pattern Data"),
          tags$p(
            sprintf("%d variant%s missing Pattern. ", count, if (count == 1) " is" else "s are"),
            "Use the checkbox below to view and edit them."
          )
      )
    })

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

    # Commodity filter dropdown
    output$commodity_filter_ui <- renderUI({
      commodities <- commodities_list()
      choices <- c("All" = "")
      if (length(commodities) > 0) {
        choices <- c(choices, setNames(commodities, commodities))
      }

      selectInput(
        ns("commodity_filter"),
        label = NULL,
        choices = choices,
        selected = selected_commodity() %||% ""
      )
    })

    # Grain group filter dropdown
    output$grain_group_filter_ui <- renderUI({
      grain_groups <- grain_groups_list()
      choices <- c("All" = "")
      if (length(grain_groups) > 0) {
        choices <- c(choices, setNames(grain_groups, grain_groups))
      }

      selectInput(
        ns("grain_group_filter"),
        label = NULL,
        choices = choices,
        selected = selected_grain_group() %||% ""
      )
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

      cat("[Variants Browser] Retrieved", nrow(df), "variants\n")
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_variants()
      cat("[Variants Browser] Transforming", nrow(df), "variants for list display\n")

      if (!nrow(df)) {
        return(data.frame(
          id = character(0),
          icon = character(0),
          title = character(0),
          description = character(0),
          stringsAsFactors = FALSE
        ))
      }

      # Build description with Grain Group, Commodity, and warning for missing pattern
      descriptions <- vapply(seq_len(nrow(df)), function(i) {
        parts <- c()
        if (!is.na(df$Commodity[i]) && nzchar(df$Commodity[i])) {
          parts <- c(parts, paste0("Commodity: ", df$Commodity[i]))
        }
        if (!is.na(df$GrainGroup[i]) && nzchar(df$GrainGroup[i])) {
          parts <- c(parts, paste0("Group: ", df$GrainGroup[i]))
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

      cat("[Variants Browser] Built list with", nrow(result), "items\n")
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
          field("Commodity", "text", title = "Commodity"),
          field("GrainGroup", "text", title = "Grain Group"),
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

      cat("[Variants Browser] Loaded variant:", variant$VariantNo, "\n")
      variant
    })

    # ---- Form module ----
    form_result <- mod_html_form_server(
      "form",
      schema_config = schema_config,
      form_data = form_data,
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
