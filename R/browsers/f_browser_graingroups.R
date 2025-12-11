# R/browsers/f_browser_graingroups.R
# Browser for grain groups (relative colour system)

f_browser_graingroups_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "ui grid stackable",
        div(class = "six wide column",
            compact_list_ui(
              ns("list"),
              show_filter = TRUE,
              filter_placeholder = "Filter by grain group code or name",
              add_new_item = FALSE
            )
        ),
        div(class = "ten wide column",
            tagList(
              uiOutput(ns("colour_preview")),
              mod_html_form_ui(ns("form"), max_width = "100%", margin = "0")
            )
        )
    )
  )
}

f_browser_graingroups_server <- function(id, pool, route = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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
    colour_enum <- setNames(names(colour_palette),
                            paste0("\u25A0 ", names(colour_palette), " (", colour_palette, ")"))

    graingroups <- reactive({
      df <- try(list_grain_groups_full(pool = pool, active_only = TRUE, limit = 1000), silent = TRUE)
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

      descriptions <- vapply(seq_len(nrow(df)), function(i) {
        parts <- c()
        if (!is.na(df$CommodityCode[i]) && nzchar(df$CommodityCode[i])) {
          parts <- c(parts, paste0("Commodity: ", df$CommodityCode[i]))
        }
        if (!is.na(df$LightnessModifier[i])) {
          parts <- c(parts, paste0("Lightness: ", df$LightnessModifier[i]))
        }
        if (!is.na(df$MissingColour[i]) && df$MissingColour[i] == 1) {
          parts <- c(parts, "Missing Colour")
        }
        if (length(parts) == 0) return("")
        paste(parts, collapse = " • ")
      }, character(1))

      data.frame(
        id = df$GrainGroupID,
        icon = "",
        title = df$GrainGroupCode,
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
          field("GrainGroupCode", "text", title = "Grain Group Code"),
          field("GrainGroupName", "text", title = "Grain Group Name"),
          field("CommodityCode", "text", title = "Commodity Code"),
          field("CommodityName", "text", title = "Commodity Name"),
          field("LightnessModifier", "text", title = "Lightness Modifier"),
          field("ColourName", "select", title = "Colour Name", enum = colour_enum),
          field("BaseColour", "text", title = "Computed Colour"),
          field("CommodityBaseColour", "text", title = "Commodity Base Colour"),
          field("DisplayOrder", "text", title = "Display Order"),
          field("IsActive", "checkbox", title = "Active"),
          field("Notes", "textarea", title = "Notes")
        ),
        columns = 1,
        static_fields = c("GrainGroupCode", "GrainGroupName", "CommodityCode", "CommodityName",
                          "BaseColour", "CommodityBaseColour")
      )
    })

    form_data <- reactive({
      id <- selected_id()
      if (is.null(id) || !nzchar(id)) return(NULL)
      data <- try(get_grain_group(as.integer(id), pool), silent = TRUE)
      if (inherits(data, "try-error") || is.null(data)) {
        cat("[GrainGroups] Error loading grain group", id, "\n")
        return(NULL)
      }
      data$IsActive <- as.logical(data$IsActive %||% FALSE)
      data
    })

    # Colour swatch preview
    output$colour_preview <- renderUI({
      fd <- form_data()
      if (is.null(fd)) return(NULL)
      hex <- fd$BaseColour %||% ""
      name <- fd$ColourName %||% ""
      if (!nzchar(hex)) return(NULL)
      tags$div(
        style = "display:flex; align-items:center; gap:0.5rem; margin-bottom:0.5rem;",
        tags$div(style = sprintf("width:32px;height:20px;border:1px solid #ccc;border-radius:4px;background:%s;", hex)),
        tags$span(sprintf("%s %s", name, hex))
      )
    })
    outputOptions(output, "colour_preview", suspendWhenHidden = FALSE)

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

        colour_name <- values$ColourName
        base_colour <- values$BaseColour
        if (!is.null(colour_palette[[colour_name]])) {
          base_colour <- colour_palette[[colour_name]]
        } else if (!is.null(base_colour) && base_colour %in% unname(colour_palette)) {
          nm <- names(colour_palette)[match(base_colour, unname(colour_palette))]
          if (!is.na(nm)) colour_name <- nm
        }

        result <- update_grain_group_attributes(
          grain_group_id = as.integer(id),
          lightness_modifier = if (nzchar(values$LightnessModifier %||% "")) as.numeric(values$LightnessModifier) else NULL,
          colour_name = colour_name,
          display_order = if (nzchar(values$DisplayOrder %||% "")) as.integer(values$DisplayOrder) else NULL,
          notes = values$Notes,
          is_active = if (isTRUE(values$IsActive)) 1L else 0L,
          pool = pool
        )

        if (!isTRUE(result$success)) {
          showNotification(result$message, type = "error")
          return(FALSE)
        }

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
            code <- parts[2]
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
        expected <- c("graingroups", as.character(code))
        if (!identical(parts, expected)) {
          session$sendCustomMessage("set-hash", list(h = paste0("#/graingroups/", code)))
        }
      })
    }
  })
}
