# R/canvas_manager.R — Canvas Manager (Upload → Tray → Library)
# Flat "Icons-style" UI; Library is a grid with select/deselect-on-click.
# Save uses Icons-style SQL; Delete has a placeholder "in use" check.

library(shiny)
library(shinyjs)
library(bs4Dash)
library(magick)
library(DBI)
library(openssl)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
to_b64 <- function(raw) openssl::base64_encode(as.raw(raw))

# --- DB helpers ---------------------------------------------------------------
helpers_loaded <- FALSE
ensure_helpers <- function() {
  if (helpers_loaded) return(invisible(TRUE))
  if (dir.exists("R/db")) {
    for (f in list.files("R/db", pattern = "\\.[Rr]$", full.names = TRUE)) {
      try(source(f, local = FALSE), silent = TRUE)
    }
  }
  assign("helpers_loaded", TRUE, inherits = TRUE)
  invisible(TRUE)
}
ensure_conn <- function() {
  ensure_helpers()
  fns <- c("db_get_connection","get_db_connection","get_connection",
           "db_connect","connect_db","db_pool")
  for (fn in fns) if (exists(fn, mode = "function")) {
    conn <- try(get(fn)(), silent = TRUE)
    if (!inherits(conn, "try-error") && !is.null(conn)) return(conn)
  }
  stop("DB connection helper not found or failed.")
}

# ===================== UI =====================
canvasManagerUI <- function(id) {
  ns <- NS(id)
  tagList(
    useShinyjs(),
    
    # Icons-like flat styling + grid + selected state
    tags$head(tags$style(HTML("
      .cm-section-title { font-weight:600; font-size:18px; margin:6px 0 10px; }
      .cm-muted { color:#6c757d; font-size:12px; }
      .cm-panel     { background:#fff; border:1px solid #dee2e6; border-radius:8px; padding:12px; }
      .cm-panel+.cm-panel { margin-top:14px; }

      /* Grid / card look */
      .cm-grid { display:grid; grid-template-columns: repeat(auto-fill, minmax(260px,1fr)); gap:14px; }
      .cm-card {
        border:1px solid #d9dee3; border-radius:10px; background:#fff;
        padding:10px; cursor:pointer; transition:box-shadow .15s, border-color .15s;
      }
      .cm-card:hover { border-color:#bfc7cf; box-shadow:0 2px 10px rgba(0,0,0,.04); }
      .cm-card.selected { border-color:#0d6efd; box-shadow:0 0 0 2px rgba(13,110,253,.15); }
      .cm-thumb { width:100%; display:block; border-radius:6px; }
      .cm-card-title { font-weight:600; margin-top:8px; }
      .cm-meta { color:#6c757d; font-size:12px; }

      .cm-actions { display:flex; gap:8px; align-items:center; }
      .cm-actions .btn { min-width:140px; }
      .cm-actions-bar { display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; }
      .cm-form-row { display:flex; gap:14px; }
      .cm-form-col { flex:1; }
    "))),
    
    tabsetPanel(
      id = ns("tabs"),
      
      # -------- Upload --------
      tabPanel(
        title = "Upload",
        br(),
        div(class="cm-panel",
            div(class="cm-section-title","Upload Image"),
            fileInput(
              ns("upload"), label = NULL,
              accept = c("image/png","image/jpeg","image/webp","image/gif","image/svg+xml"),
              buttonLabel = "Browse…", placeholder = "No file selected"
            ),
            div(class="cm-muted",
                "Supported: PNG/JPEG/WEBP/GIF/SVG. After upload you'll move to the Tray.")
        )
      ),
      
      # -------- Tray (preview + name + save) --------
      tabPanel(
        title = "Tray",
        br(),
        div(class="cm-form-row",
            div(class="cm-form-col",
                div(class="cm-panel",
                    div(class="cm-section-title","Details"),
                    textInput(ns("name"), NULL, placeholder = "Canvas name"),
                    tableOutput(ns("meta")),
                    hr(),
                    div(class="cm-actions",
                        actionButton(ns("save"), "Save to Library", class = "btn btn-success"),
                        actionButton(ns("clear_tray"), "Clear", class = "btn btn-light")
                    )
                )
            ),
            div(class="cm-form-col",
                div(class="cm-panel",
                    div(class="cm-section-title","Preview"),
                    uiOutput(ns("preview"), inline = TRUE)
                )
            )
        )
      ),
      
      # -------- Library --------
      tabPanel(
        title = "Library",
        br(),
        div(class="cm-panel",
            div(class="cm-section-title","Stored Canvases"),
            div(class="cm-actions-bar",
                actionButton(ns("refresh_library"), "Refresh", class="btn btn-light"),
                actionButton(ns("delete_selected"), "Delete Selected", class="btn btn-danger", icon = icon("trash"))
            ),
            uiOutput(ns("library_ui"))   # server will render a .cm-grid here
        )
      )
    )
  )
}

# ===================== Server =====================
canvasManagerServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive image state
    current_img <- reactiveVal(NULL)     # magick image
    current_src <- reactiveVal(NULL)     # original filename
    selected_canvas <- reactiveVal(NULL) # library selection
    
    # Enable/disable Save (Tray) & Delete (Library)
    observe({
      on_tray  <- identical(input$tabs, "Tray")
      has_img  <- !is.null(current_img())
      has_name <- nzchar(input$name %||% "")
      if (on_tray && has_img && has_name) shinyjs::enable("save") else shinyjs::disable("save")
      
      on_lib   <- identical(input$tabs, "Library")
      if (on_lib && !is.null(selected_canvas())) shinyjs::enable("delete_selected") else shinyjs::disable("delete_selected")
    })
    
    # Upload → move to Tray
    observeEvent(input$upload, {
      f <- input$upload; req(f, file.exists(f$datapath))
      img <- try(magick::image_read(f$datapath), silent = TRUE)
      if (inherits(img, "try-error")) {
        showNotification("Failed to read uploaded image.", type = "error"); return()
      }
      current_img(img)
      current_src(f$name %||% "")
      updateTabsetPanel(session, "tabs", selected = "Tray")
    })
    
    # Clear tray
    observeEvent(input$clear_tray, {
      current_img(NULL)
      current_src(NULL)
      updateTextInput(session, "name", value = "")
    })
    
    # Preview + meta (Tray)
    output$preview <- renderUI({
      img <- current_img(); req(img)
      b64 <- to_b64(image_write(img, format = "png"))
      tags$img(
        src = paste0("data:image/png;base64,", b64),
        style = "max-width:100%; height:auto; display:block;",
        alt = "Preview"
      )
    })
    output$meta <- renderTable({
      img <- current_img(); req(img)
      info <- image_info(img)
      data.frame(
        Name      = input$name %||% "",
        Source    = current_src() %||% "",
        Width_px  = info$width,
        Height_px = info$height,
        check.names = FALSE
      )
    })
    
    # ---- Library render (grid) ----
    renderLibrary <- function() {
      conn <- try(ensure_conn(), silent = TRUE)
      if (inherits(conn, "try-error"))
        return(tags$div(class="cm-muted","DB connection failed."))
      
      df <- try(DBI::dbGetQuery(conn, "
        SELECT id, name, width_px, height_px, preview_png_b64, created_utc
        FROM [dbo].[Canvases]
        ORDER BY id DESC;"), silent = TRUE)
      
      if (inherits(df, "try-error") || !nrow(df))
        return(tags$div(class="cm-muted","No canvases yet."))
      
      tags$div(class="cm-grid",
               lapply(seq_len(nrow(df)), function(i) {
                 row <- df[i,]
                 is_sel <- identical(selected_canvas(), row$id)
                 uri <- if (!is.na(row$preview_png_b64) && nzchar(row$preview_png_b64))
                   paste0("data:image/png;base64,", row$preview_png_b64) else NULL
                 
                 tags$div(
                   class = paste("cm-card", if (is_sel) "selected" else NULL),
                   onclick = sprintf("Shiny.setInputValue('%s', %s, {priority:'event'});", ns("canvas_click"), row$id),
                   if (!is.null(uri)) tags$img(src = uri, class = "cm-thumb") else tags$div("—"),
                   tags$div(class="cm-card-title", paste0("#", row$id, " — ", row$name)),
                   tags$div(class="cm-meta", paste0(row$width_px, "×", row$height_px, " px")),
                   tags$div(class="cm-meta", paste("Created:", as.character(row$created_utc)))
                 )
               })
      )
    }
    
    output$library_ui <- renderUI({ renderLibrary() })
    observeEvent(input$refresh_library, { output$library_ui <- renderUI({ renderLibrary() }) })
    observeEvent(input$tabs, {
      if (identical(input$tabs, "Library")) {
        selected_canvas(NULL)  # reset selection on entry (like Icons)
        output$library_ui <- renderUI({ renderLibrary() })
      }
    }, ignoreInit = TRUE)
    
    # Click to select / deselect (Icons behavior)
    observeEvent(input$canvas_click, {
      id <- as.integer(input$canvas_click)
      if (!is.null(selected_canvas()) && identical(selected_canvas(), id)) {
        selected_canvas(NULL)   # deselect if clicking the same card
      } else {
        selected_canvas(id)     # select new card
      }
      output$library_ui <- renderUI({ renderLibrary() })  # update highlight
    })
    
    # ---- Save → DB (Icons-style) ----
    observeEvent(input$save, {
      img <- current_img(); nm <- input$name %||% ""
      if (is.null(img)) { showNotification("No image to save.", type="warning"); return() }
      if (!nzchar(nm))  { showNotification("Enter a canvas name.", type="warning"); return() }
      
      info      <- image_info(img)
      width_px  <- as.integer(info$width)
      height_px <- as.integer(info$height)
      
      full_b64  <- as.character(to_b64(image_write(img, format = "png")))
      prev_b64  <- as.character(to_b64(image_write(image_scale(img, "320x320>"), format = "png")))
      
      conn <- try(ensure_conn(), silent = TRUE)
      if (inherits(conn, "try-error")) { showNotification("DB connection failed.", type="error"); return() }
      
      src_type <- if (!is.null(input$upload) && file.exists(input$upload$datapath)) "upload" else "unknown"
      src_ref  <- current_src() %||% NA_character_
      overlays_json <- NA_character_
      
      sql <- "
      SET NOCOUNT ON;
      DECLARE @ins TABLE (id INT);
      INSERT INTO [dbo].[Canvases]
        (name, width_px, height_px, src_type, src_ref, bg_png_b64, overlays_json, preview_png_b64)
      OUTPUT INSERTED.id INTO @ins
      VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      SELECT id FROM @ins;
      "
      
      res <- try(DBI::dbGetQuery(conn, sql, params = list(
        nm, width_px, height_px, src_type,
        src_ref, full_b64, overlays_json, prev_b64
      )), silent = TRUE)
      
      new_id <- if (!inherits(res, "try-error") && nrow(res)) suppressWarnings(as.integer(res[[1]][1])) else NA_integer_
      
      if (is.na(new_id)) {
        showNotification("Save failed (no ID returned).", type="error", duration = 6)
      } else {
        showNotification(paste("Saved canvas #", new_id), type="message")
        updateTabsetPanel(session, "tabs", selected = "Library")
        selected_canvas(new_id) # auto-select the new one
        output$library_ui <- renderUI({ renderLibrary() })
        # clear tray
        current_img(NULL); current_src(NULL); updateTextInput(session, "name", value = "")
      }
    })
    
    # ---- Delete selected (Icons-style) ----
    observeEvent(input$delete_selected, {
      id <- selected_canvas()
      if (is.null(id)) { showNotification("Select a canvas first.", type="warning"); return() }
      
      # Placeholder "in use" check (replace later with real logic)
      in_use <- FALSE
      if (in_use) {
        showNotification("Cannot delete: canvas is in use.", type="error")
        return()
      }
      
      conn <- try(ensure_conn(), silent = TRUE)
      if (inherits(conn, "try-error")) {
        showNotification("DB connection failed.", type="error"); return()
      }
      
      sql <- "DELETE FROM [dbo].[Canvases] WHERE id = ?;"
      ok <- try(DBI::dbExecute(conn, sql, params = list(id)), silent = TRUE)
      
      if (inherits(ok, "try-error") || ok < 1) {
        showNotification("Delete failed.", type="error")
      } else {
        showNotification(paste("Deleted canvas #", id), type="message")
        selected_canvas(NULL)
        output$library_ui <- renderUI({ renderLibrary() })
      }
    })
  })
}
