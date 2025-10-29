# R/browsers/mod_browser_containers.R

suppressPackageStartupMessages({
  library(shiny)
  library(bs4Dash)
  library(jsonlite)
  library(shinyWidgets)
})

# =========================== UI ===============================================

browser_containers_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Title bar (blue) — New + Delete on the right
    div(
      class = "pane-header bg-primary text-white px-3 py-2 mb-2",
      style = "border-radius: .5rem;",
      div(
        class = "d-flex align-items-center justify-content-between flex-wrap gap-2",
        div(class = "h5 m-0", "Containers"),
        div(
          class = "header-actions d-flex align-items-center flex-wrap",
          shinyWidgets::actionBttn(
            inputId = ns("new"), label = "New",
            style = "fill", color = "success", size = "sm"
          ),
          span(class = "header-spacer"),
          shinyWidgets::actionBttn(
            inputId = ns("delete"), label = "Delete",
            style = "fill", color = "danger", size = "sm"
          )
        )
      )
    ),
    
    # Body: 40/60 layout
    div(class = "container-fluid p-0",
        div(class = "row gx-3 gy-3",
            
            # LEFT 40% — filter + list
            div(class = "col-12 col-md col-flex-40",
                div(class = "mb-2",
                    textInput(ns("q"), NULL, "", placeholder = "Filter by code/name…")
                ),
                selectInput(
                  inputId   = ns("pick"),
                  label     = NULL,
                  choices   = c(),
                  selected  = NULL,
                  multiple  = FALSE,
                  selectize = FALSE,
                  size      = 12
                )
            ),
            
            # RIGHT 60% — toolbar (Edit + Save) right-aligned, then React pane
            # RIGHT 60% — toolbar (Edit toggle + Save) right-aligned, then React pane
            # RIGHT 60% — single toggle button (Edit/Save) right-aligned, then React pane
            div(class = "col-12 col-md col-flex-60",
                div(class = "d-flex align-items-center justify-content-end mb-2 rt-toolbar",
                    # Single toggle button (starts as Edit/blue; becomes Save/green)
                    shinyWidgets::actionBttn(
                      inputId = ns("edit_save"),
                      label   = "Edit",
                      style   = "fill",
                      color   = "primary",  # blue when read-only
                      size    = "sm",
                      class   = "rt-save-bttn"
                    )
                ),
                react_table_ui(ns("tbl"), height = "70vh")
            )
            
            
        )
    )
  )
}

# ========================== SERVER ============================================

browser_containers_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # First paint: set edit class (no reactive reads inside callback)
    initial_edit <- FALSE
    session$onFlushed(function() {
      session$sendCustomMessage("react-edit-state", list(
        elId   = session$ns("tbl-root"),
        isEdit = initial_edit
      ))
    }, once = TRUE)
    
    to_like <- function(x) {
      x <- trimws(x %||% "")
      if (!nzchar(x)) NULL else paste0("%", x, "%")
    }
    
    # -------- Data: left list ---------------------------------------------------
    raw_types <- reactive({
      code_like <- to_like(input$q)
      df <- try(
        list_container_types(
          code_like = code_like,
          order_col = "TypeCode",
          limit     = 500
        ),
        silent = TRUE
      )
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      if (!nrow(df)) return(df)
      
      # Icon decoration
      df$Icon <- vapply(seq_len(nrow(df)), function(i) {
        bt   <- toupper(as.character(df$BottomType[i] %||% ""))
        code <- as.character(df$TypeCode[i] %||% "")
        ico <- tryCatch(icon_for_container(bottom_type = bt), error = function(e) NA_character_)
        if (!nzchar(ico) || is.na(ico)) {
          m <- container_type_icons()
          if (length(m) && nzchar(code) && code %in% names(m)) ico <- m[[code]]
        }
        if (!nzchar(ico) || is.na(ico)) ico <- if (bt == "HOPPER") "🔻" else if (bt == "FLAT") "▭" else "⬚"
        ico
      }, character(1))
      
      # Extra client-side filter
      q <- trimws(input$q %||% "")
      if (nzchar(q)) {
        keep <- grepl(q, df$TypeName, ignore.case = TRUE) | grepl(q, df$TypeCode, ignore.case = TRUE)
        df <- df[keep, , drop = FALSE]
      }
      df
    })
    
    selected_id <- reactiveVal(NULL)
    
    observe({
      df <- raw_types()
      if (nrow(df)) {
        labels  <- paste0(df$Icon, "  ", df$TypeCode, " — ", df$TypeName)
        values  <- as.integer(df$ContainerTypeID)
        choices <- as.list(values); names(choices) <- labels
      } else {
        choices <- setNames(list(), character())
      }
      
      prev <- isolate(selected_id())
      sel  <- if (!is.null(prev) && length(choices) && prev %in% unlist(choices, use.names = FALSE)) {
        prev
      } else if (length(choices)) {
        unlist(choices, use.names = FALSE)[1]
      } else {
        NULL
      }
      
      updateSelectInput(session, "pick", choices = choices, selected = sel)
      selected_id(sel)
    })
    
    observeEvent(input$pick, {
      if (!is.null(input$pick) && nzchar(input$pick)) {
        selected_id(as.integer(input$pick))
      }
    }, ignoreInit = TRUE)
    
    # -------- Right pane: compile schema/ui once --------------------------------
    dsl_schema <- reactiveVal(NULL)
    dsl_ui     <- reactiveVal(NULL)
    
    observeEvent(TRUE, once = TRUE, {
      icons_vec   <- container_type_icons()   # named vector CODE -> emoji
      icon_values <- unname(icons_vec)
      
      auto <- rjsf_auto_compile(
        fields = list(
          field("ContainerTypeID","integer",  title="ID"),
          field("TypeName",       "text",     title="Name"),
          field("TypeCode",       "text",     title="Code"),
          field("Description",    "textarea", title="Description", fullWidth=TRUE),
          field("BottomType",     "select",   title="Bottom Type", enum=c("HOPPER","FLAT")),
          # Graphics (collapsed)
          field("DefaultFill",     "color",   title="Fill",      group="Graphics"),
          field("DefaultBorder",   "color",   title="Border",    group="Graphics"),
          field("DefaultBorderPx", "integer", title="Border px", min=0, max=20, group="Graphics"),
          field("Icon",            "select",  title="Icon",      enum=icon_values, group="Graphics"),
          # Meta (collapsed)
          field("CreatedAt","text", title="Created", group="Meta"),
          field("UpdatedAt","text", title="Updated", group="Meta")
        ),
        groups = list(
          group("Graphics", title="Graphics", collapsible=TRUE, collapsed=TRUE, column=1),
          group("Meta",     title="Meta",     collapsible=TRUE, collapsed=TRUE, column=1)
        ),
        title      = NULL,
        columns    = 1,
        root_order = c("ContainerTypeID","TypeName","TypeCode","Description","BottomType","Graphics","Meta"),
        numeric_as = c("Graphics.DefaultBorderPx"),
        widgets    = list(
          "BottomType"       = list("ui:widget"="iconRadio",
                                    "ui:options"=list(icons=list(HOPPER="🔻", FLAT="▭"))),
          "Graphics.Icon"    = list("ui:widget"="reactSelect"),
          "ContainerTypeID"  = list("ui:field" ="plaintext"),
          "Meta.CreatedAt"   = list("ui:field" ="plaintext"),
          "Meta.UpdatedAt"   = list("ui:field" ="plaintext")
        ),
        static_fields = c("ContainerTypeID","Meta.CreatedAt","Meta.UpdatedAt"),
        hidden_fields = c()
      )
      
      dsl_schema(auto$schema)
      dsl_ui(auto$uiSchema)
    })
    
    # -------- Render: single message with nested formData -----------------------
    observeEvent({
      list(selected_id(), dsl_schema(), dsl_ui())
    }, {
      sid <- selected_id(); sch <- dsl_schema(); uiS <- dsl_ui()
      if (is.null(sid) || is.null(sch) || is.null(uiS)) return()
      
      df1 <- try(get_container_type_by_id(sid), silent = TRUE)
      if (inherits(df1, "try-error") || is.null(df1) || !nrow(df1)) return()
      
      fd <- rjsf_auto_formdata(
        df_row = df1,
        nest = list(
          "Graphics" = c("DefaultFill","DefaultBorder","DefaultBorderPx","Icon"),
          "Meta"     = c("CreatedAt","UpdatedAt")
        ),
        formatters = list(
          "Meta.CreatedAt" = function(v) if (inherits(v,"POSIXt")) format(v, "%Y-%m-%d %H:%M:%S") else as.character(v),
          "Meta.UpdatedAt" = function(v) if (inherits(v,"POSIXT")) format(v, "%Y-%m-%d %H:%M:%S") else as.character(v)
        ),
        integers  = c("Graphics.DefaultBorderPx"),
        drop_root = TRUE
      )
      
      session$sendCustomMessage("react-table-props", list(
        elId     = session$ns("tbl-root"),
        schema   = sch,
        uiSchema = uiS,
        formData = fd
      ))
    }, ignoreInit = FALSE)
    
    # -------- Edit mode: radio -> toggle green/black borders --------------------
    # ---- Edit/Save toggle state ----
    is_edit <- reactiveVal(FALSE)
    
    # Initialize is-edit class on first paint (already present in your file)
    # session$onFlushed(function() { ... }, once = TRUE)
    
    # Toggle when the single button is clicked
    observeEvent(input$edit_save, {
      new_state <- !is_edit()
      is_edit(new_state)
      
      # Flip button label/color
      shinyWidgets::updateActionBttn(
        session, "edit_save",
        label = if (new_state) "Save" else "Edit",
        color = if (new_state) "success" else "primary"  # green when saving
      )
      
      # Flip borders + interactivity in the React area
      session$sendCustomMessage("react-edit-state", list(
        elId   = session$ns("tbl-root"),
        isEdit = new_state
      ))
    }, ignoreInit = FALSE)
    
    # Clicking NEW should also enter edit mode and show Save (green)
    observeEvent(input$new, {
      is_edit(TRUE)
      shinyWidgets::updateActionBttn(session, "edit_save", label = "Save", color = "success")
      session$sendCustomMessage("react-edit-state", list(
        elId   = session$ns("tbl-root"),
        isEdit = TRUE
      ))
    })
    
    observeEvent(input$save, { showNotification("Save: stub — wire to parameterized UPSERT/UPDATE.", type = "message") })
    observeEvent(input$delete, {
      id <- selected_id()
      if (is.null(id) || is.na(id)) { showNotification("Nothing selected.", type = "warning"); return() }
      n1 <- try(count_silos_with_type(id),     silent = TRUE); if (inherits(n1, "try-error")) n1 <- NA
      n2 <- try(count_operations_for_type(id), silent = TRUE); if (inherits(n2, "try-error")) n2 <- NA
      if (!is.na(n1) && n1 > 0) { showNotification(sprintf("Cannot delete: %d silo(s) reference this type.", n1), type = "error", duration = 7); return() }
      if (!is.na(n2) && n2 > 0) { showNotification(sprintf("Cannot delete: %d operation(s) reference this type.", n2), type = "error", duration = 7); return() }
      showNotification("Delete: stub — safe to proceed. Wire DELETE with RowVer check.", type = "message")
    })
    
    return(list(
      selected_container_type_id = selected_id,
      edit_mode                   = is_edit
    ))
  })
}
