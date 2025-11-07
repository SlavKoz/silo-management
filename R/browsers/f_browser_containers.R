# R/browsers/f_browser_containers.R
# (Packages are loaded in global.R)

# =========================== UI ===============================================
browser_containers_ui <- function(id) {
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
browser_containers_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ---- Data (full list) ----
    raw_types <- reactive({
      df <- try(
        list_container_types(
          code_like = NULL,
          order_col = "TypeCode",
          limit     = 2000
        ), silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)

      # Icon now comes from database; fallback if null
      df$Icon <- vapply(seq_len(nrow(df)), function(i) {
        ico <- df$Icon[i]
        if (is.null(ico) || is.na(ico) || !nzchar(ico)) {
          bt <- toupper(as.character(f_or(df$BottomType[i], "")))
          ico <- if (bt == "HOPPER") "🔻" else if (bt == "FLAT") "▭" else "◻️"
        }
        ico
      }, character(1))
      df
    })

    # Transform data for compact list (id, icon, title, description)
    list_items <- reactive({
      df <- raw_types()
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
        id = df$ContainerTypeID,
        icon = df$Icon,
        title = toupper(df$TypeName),
        description = df$TypeCode,
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

    # Debug: log when selection changes
    observeEvent(selected_id(), {
      cat("\n[Containers] selected_id changed to:", selected_id(), "\n")
    })

    # ---- Schema configuration (static) ----
    schema_config <- list(
      fields = list(
        # Column 1
        field("TypeName",       "text",     title="Name", column = 1),
        field("TypeCode",       "text",     title="Code", column = 1),
        field("Description",    "textarea", title="Description", column = 1),
        field("BottomType",     "select",   title="Bottom Type", enum=c("HOPPER", "FLAT"), default="HOPPER", column = 1),

        # Column 2 - Graphics
        field("DefaultFill",     "color",   title="Fill",      group="Graphics"),
        field("DefaultBorder",   "color",   title="Border",    group="Graphics"),
        field("DefaultBorderPx", "number", title="Border px", min=0, max=20, group="Graphics"),

        # Column 2 - Meta
        field("CreatedAt","text", title="Created", group="Meta"),
        field("UpdatedAt","text", title="Updated", group="Meta")
      ),
      groups = list(
        group("Graphics", title="Graphics", collapsible=TRUE, collapsed=TRUE, column=2),
        group("Meta",     title="Meta",     collapsible=TRUE, collapsed=TRUE, column=2)
      ),
      columns = 2,
      static_fields = c("Meta.CreatedAt", "Meta.UpdatedAt")
    )

    # ---- Reactive form data based on selection ----
    form_data <- reactive({
      sid <- selected_id()

      # No selection - return empty data
      if (is.null(sid)) {
        return(list(
          TypeName = "",
          TypeCode = "",
          Description = "",
          BottomType = "HOPPER",
          Graphics = list(
            DefaultFill = "#cccccc",
            DefaultBorder = "#333333",
            DefaultBorderPx = 1
          ),
          Meta = list(
            CreatedAt = "",
            UpdatedAt = ""
          )
        ))
      }

      # New record
      if (is.na(sid)) {
        return(list(
          TypeName = "",
          TypeCode = "",
          Description = "",
          BottomType = "HOPPER",
          Graphics = list(
            DefaultFill = "#cccccc",
            DefaultBorder = "#333333",
            DefaultBorderPx = 1
          ),
          Meta = list(
            CreatedAt = "",
            UpdatedAt = ""
          )
        ))
      }

      # Existing record - fetch from database
      df1 <- try(get_container_type_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) {
        return(list())
      }

      # Transform to nested format
      list(
        TypeName = f_or(df1$TypeName, ""),
        TypeCode = f_or(df1$TypeCode, ""),
        Description = f_or(df1$Description, ""),
        BottomType = f_or(df1$BottomType, "HOPPER"),
        Graphics = list(
          DefaultFill = f_or(df1$DefaultFill, "#cccccc"),
          DefaultBorder = f_or(df1$DefaultBorder, "#333333"),
          DefaultBorderPx = as.numeric(f_or(df1$DefaultBorderPx, 1))
        ),
        Meta = list(
          CreatedAt = if (inherits(df1$CreatedAt, "POSIXt")) format(df1$CreatedAt, "%Y-%m-%d %H:%M:%S") else as.character(f_or(df1$CreatedAt, "")),
          UpdatedAt = if (inherits(df1$UpdatedAt, "POSIXt")) format(df1$UpdatedAt, "%Y-%m-%d %H:%M:%S") else as.character(f_or(df1$UpdatedAt, ""))
        )
      )
    })

    # ---- Initialize HTML form module ----
    mod_html_form_server(
      id = "form",
      schema_config = schema_config,
      form_data = form_data,
      title_field = "TypeName",
      show_header = TRUE,
      show_delete_button = TRUE  # Show delete button (disabled on add new)
    )

    return(list(selected_container_type_id = selected_id))
  })
}

# Aliases with f_ prefix for consistency
f_browser_containers_ui <- browser_containers_ui
f_browser_containers_server <- browser_containers_server
