# =========================== UI ===============================================
browser_icons_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # Header (matches Containers)
    div(
      class = "pane-header bg-primary text-white px-3 py-2 mb-2",
      style = "border-radius: .5rem;",
      div(
        class = "d-flex align-items-center justify-content-between flex-wrap gap-2",
        div(class = "h5 m-0", "Icons"),
        div(class = "header-actions d-flex align-items-center flex-wrap")
      )
    ),
    
    # Body: plain tabs (no box, no title, no collapse)
    div(
      class = "container-fluid p-0",
      bs4Dash::tabsetPanel(
        id   = ns("tabs"),
        type = "tabs",
        
        # -------------------- SEARCH TAB (20/80) --------------------
        shiny::tabPanel(
          title = "Search",
          br(),
          fluidRow(
            # LEFT 25% (width = 3)
            column(
              width = 3,
              
              # Search row: input + small round icon button
              div(class = "d-flex align-items-center gap-2",
                  textInput(
                    ns("q"), NULL,
                    placeholder = "Search icons (e.g. dog, home, cart)",
                    width = "100%"
                  ),
                  shinyWidgets::actionBttn(
                    inputId = ns("do_search_icon"),
                    label   = NULL,
                    style   = "material-circle",
                    color   = "primary",
                    icon    = icon("search"),
                    size    = "sm",              # <- smaller
                    class   = "icons-search-btn" # <- custom class to fine-tune height
                  )
              ),
              
              # Enter-to-search (unchanged)
              tags$script(HTML(sprintf("
        $(document).on('keydown', '#%s', function(e){
          if (e.key === 'Enter') { $('#%s').trigger('click'); e.preventDefault(); }
        });
      ", ns("q"), ns("do_search_icon")))),
              
              br(), br(),
              
              # Upload (only here)
              fileInput(
                ns("svg_upload_search"), "Upload SVG",
                accept = ".svg", buttonLabel = "Browse…", placeholder = "No file"
              ),
              actionButton(ns("add_upload_to_results"), "Add to results",
                           class = "btn btn-secondary w-100")
            ),
            
            # RIGHT 75% (width = 9)
            column(
              width = 9,
              uiOutput(ns("results_ui"))
            )
          )
        )
        ,
        
        # -------------------- TRAY TAB (no upload here) --------------------
        shiny::tabPanel(
          title = "Tray",
          br(),
          textInput(ns("display_name"), "Display name", placeholder = "Short name"),
          textInput(ns("color_hex"),    "Color",        value = "#2d89ef"),
          fluidRow(
            column(6, actionButton(ns("preview"),     "Preview",         class = "btn btn-outline-primary w-100")),
            column(6, actionButton(ns("save_to_lib"), "Save to Library", class = "btn btn-success w-100", disabled = TRUE))
          ),
          uiOutput(ns("tray_preview_ui"))
        ),
        
        # -------------------- LIBRARY TAB --------------------
        shiny::tabPanel(
          title = "Library",
          br(),
          div(class = "d-flex justify-content-end mb-2",
              actionButton(ns("refresh"), "Refresh", class = "btn btn-secondary btn-sm")
          ),
          div(id = ns("library_grid"), class = "ui-grid"),
          br(),
          actionButton(ns("delete_selected"), "Delete Selected",
                       class = "btn btn-danger", disabled = TRUE)
        )
      )
    )
  )
}

# ========================== SERVER ============================================
browser_icons_server <- function(id, pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # DB connection
    conn <- NULL
    try(conn <- db_get_connection(), silent = TRUE)
    validate_conn <- reactive({ req(!is.null(conn)); conn })
    
    # State
    rv <- reactiveValues(
      last_svg_sanitized = NULL,
      last_svg_recolored = NULL,
      selected_ids       = character(0)
    )
    
    # Results (both search hits and uploads)
    results <- reactiveVal(character(0))  # vector of ids: "prefix:name" or "upload:<ts>"
    upload_meta <- reactiveVal(list())    # id -> list(png_b64, label, svg)
    
    # ---------- Search ----------
    do_search <- function() {
      q <- trimws(input$q %||% "")
      if (!nzchar(q)) return()
      ids <- iconify_search_all(q, limit = 48)  # helper returns "prefix:name"
      results(ids)
    }
    observeEvent(input$do_search_icon, do_search(), ignoreInit = TRUE)
    
    # ---------- Upload (left column) -> add to results ----------
    observeEvent(input$add_upload_to_results, {
      up <- input$svg_upload_search
      if (is.null(up$datapath)) {
        showNotification("Please choose an SVG file first.", type = "warning")
        return()
      }
      raw_svg <- paste(readLines(up$datapath, warn = FALSE), collapse = "\n")
      svg     <- sanitize_svg(raw_svg)
      if (!nzchar(svg)) {
        showNotification("Could not read SVG.", type = "error")
        return()
      }
      # build a small thumbnail
      png64 <- try(base64enc::base64encode(svg_to_png_raw(svg, size = 64)), silent = TRUE)
      if (inherits(png64, "try-error")) png64 <- ""
      
      # unique id for this upload
      uid <- paste0("upload:", format(Sys.time(), "%Y%m%d%H%M%OS3"))
      meta <- upload_meta(); meta[[uid]] <- list(
        png_b64 = png64,
        label   = basename(up$name %||% "upload.svg"),
        svg     = svg
      )
      upload_meta(meta)
      
      # prepend to results
      results(unique(c(uid, results())))
    })
    
    # ---------- Render results grid (search + uploads) ----------
    output$results_ui <- renderUI({
      ids <- results()
      if (!length(ids)) return(tags$em("Search or upload an SVG to begin."))
      
      fluidRow(
        lapply(ids, function(id) {
          # Thumb: iconify or uploaded
          img_tag <- NULL
          if (startsWith(id, "upload:")) {
            entry <- upload_meta()[[id]]
            if (!is.null(entry) && nzchar(entry$png_b64 %||% "")) {
              img_tag <- tags$img(src = paste0("data:image/png;base64,", entry$png_b64), height = 56)
            }
          } else {
            parts <- strsplit(id, ":", fixed = TRUE)[[1]]
            if (length(parts) == 2) {
              url <- sprintf("%s/%s/%s.svg?height=64", ICONIFY_BASE, parts[1], parts[2])
              img_tag <- tags$img(src = url, height = 64)
            }
          }
          if (is.null(img_tag)) img_tag <- div(class="text-muted", "(no preview)")
          
          nsid <- gsub("[^A-Za-z0-9_]", "_", id)
          column(
            2,
            div(
              class = "result-card",
              style = "border:1px solid #eee; border-radius:10px; padding:10px; text-align:center; margin-bottom:10px;",
              img_tag,
              div(style="font-size:12px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin-top:4px;",
                  htmltools::htmlEscape(id)),
              actionButton(
                inputId = ns(paste0('load_', nsid)),
                label   = "Load to tray",
                class   = "btn-primary btn-sm w-100"
              )
            )
          )
        })
      )
    })
    
    # Each "Load to tray" button -> fetch/set SVG and go to Tray
    observe({
      ids <- results()
      lapply(ids, function(id) {
        nsid <- gsub("[^A-Za-z0-9_]", "_", id)
        observeEvent(input[[paste0("load_", nsid)]], {
          svg <- ""
          if (startsWith(id, "upload:")) {
            svg <- (upload_meta()[[id]] %||% list())$svg %||% ""
          } else {
            svg <- fetch_iconify_svg(id)
          }
          req(nzchar(svg))
          rv$last_svg_sanitized <- sanitize_svg(svg)
          shinyjs::enable("preview")
          shiny::updateTabsetPanel(session, inputId = ns("tabs"), selected = "Tray")
        }, ignoreInit = TRUE, once = TRUE)
      })
    })
    
    # ---------- Tray (no upload here) ----------
    observeEvent(input$preview, {
      req(rv$last_svg_sanitized)
      color <- trimws(input$color_hex); if (!nzchar(color)) color <- "#2d89ef"
      svg_recolored <- recolor_svg(rv$last_svg_sanitized, color)
      rv$last_svg_recolored <- svg_recolored
      output$tray_preview_ui <- renderUI(HTML(svg_recolored))
      shinyjs::enable("save_to_lib")
    })
    
    observeEvent(input$save_to_lib, {
      conn <- validate_conn()
      req(rv$last_svg_recolored)
      disp <- trimws(input$display_name); if (!nzchar(disp)) disp <- "icon"
      payload <- build_payload(icon_name = disp, svg_txt = rv$last_svg_recolored)
      insert_icon(conn, payload)
      icons_refresh_library(conn, session)
      shinyjs::disable("save_to_lib")
      shiny::updateTabsetPanel(session, inputId = ns("tabs"), selected = "Library")
    })
    
    # ---------- Library ----------
    icons_refresh_library <- function(conn, session) {
      df <- fetch_icons(conn)  # id, icon_name, png_32_b64
      rows <- lapply(seq_len(nrow(df)), function(i) {
        list(
          id    = df$id[i],
          label = sprintf("%d — %s", df$id[i], df$icon_name[i]),
          img   = if (!is.na(df$png_32_b64[i]) && nzchar(df$png_32_b64[i]))
            paste0("data:image/png;base64,", df$png_32_b64[i]) else NULL
        )
      })
      session$sendCustomMessage("icons-browser.renderLibrary", list(rows = rows))
    }
    
    observeEvent(input$refresh, {
      conn <- validate_conn()
      icons_refresh_library(conn, session)
      shiny::updateTabsetPanel(session, inputId = ns("tabs"), selected = "Library")
    }, ignoreInit = FALSE)
    
    observeEvent(input$lib_selected_ids, {
      ids <- input$lib_selected_ids
      rv$selected_ids <- ids
      if (length(ids)) shinyjs::enable("delete_selected") else shinyjs::disable("delete_selected")
    })
    
    observeEvent(input$delete_selected, {
      conn <- validate_conn()
      ids <- as.integer(rv$selected_ids)
      if (!length(ids)) return()
      for (id in ids) {
        if (isTRUE(icon_is_used_somewhere(conn, id))) next
        delete_icon(conn, id)
      }
      rv$selected_ids <- character(0)
      shinyjs::disable("delete_selected")
      icons_refresh_library(conn, session)
    })
  })
}
