# R/browsers/f_browser_canvas.R
# Canvas background image browser - simplified version based on icons

f_browser_canvas_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Scoped CSS
    f_scoped_css(ns("root"), c(
      # Panel visibility
      ".steps-panel{display:none;}",
      ".steps-panel.active{display:block;}",

      # Upload panel - centered
      ".upload-container{max-width:520px; margin:2rem auto; text-align:center;}",
      ".upload-container .ui.segment{padding:3rem;}",

      # Tray - equal columns
      ".tray-grid{margin-top:.5rem;}",
      ".tray-grid .column{padding:.5rem!important;}",
      ".tray-left, .tray-right{height:100%; min-height:300px;}",
      ".tray-left .ui.segment{height:100%; display:flex; align-items:center; padding:1.5rem!important;}",
      ".tray-left .ui.form{width:100%;}",
      ".tray-right .ui.segment{height:100%; display:flex; flex-direction:column; align-items:center; justify-content:center; background:#fafafa; padding:1.5rem!important;}",

      # Preview styling
      paste0("#", ns("canvas_preview_container"),
             "{width:100%; max-width:400px; margin:auto;",
             " border:2px dashed #d4d4d5; border-radius:12px; background:#fff;",
             " display:flex; align-items:center; justify-content:center; padding:1rem; overflow:hidden;}"),
      paste0("#", ns("canvas_preview_container"), " img",
             "{max-width:100%; max-height:300px; width:auto; height:auto; display:block;}"),
      ".dimension-info{margin-top:1rem; font-size:0.9em; color:#666;}",

      # Results grid (for library)
      ".results-grid.ui.grid{margin-top:.25rem;}",
      ".results-grid .column{padding:.4rem!important;}",
      ".result-card{border:1px solid #e9ecef;border-radius:.5rem;padding:8px;text-align:center;transition:all 0.2s;}",
      ".result-card:hover{border-color:#2185d0; box-shadow:0 2px 4px rgba(0,0,0,0.1);}",
      ".result-card img{max-width:100%;max-height:120px;object-fit:contain;display:block;margin:0 auto 6px;}",
      ".result-card .label{font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin:4px 2px 6px;}",
      ".result-card .ui.button{font-size:.8rem;padding:.3rem .5rem; margin-top:4px;}"
    )),

    div(id = ns("root"),

        # Steps header
        div(class = "ui three steps",
            a(class = "active step", `data-step` = "upload",
              tags$i(class = "upload icon"),
              div(class = "content",
                  div(class = "title", "Upload"),
                  div(class = "description", "Select image")
              )
            ),
            a(class = "step", `data-step` = "tray",
              tags$i(class = "inbox icon"),
              div(class = "content",
                  div(class = "title", "Tray"),
                  div(class = "description", "Review & save")
              )
            ),
            a(class = "step", `data-step` = "library",
              tags$i(class = "book icon"),
              div(class = "content",
                  div(class = "title", "Library"),
                  div(class = "description", "Saved canvases")
              )
            )
        ),

        # UPLOAD PANEL
        div(id = ns("panel-upload"), class = "steps-panel active", `data-panel` = "upload",
            div(class = "upload-container",
                div(class = "ui segment",
                    tags$i(class = "file image outline icon huge", style = "color:#ccc;margin-bottom:1rem;"),
                    tags$h3(class = "ui header", "Upload Canvas Background"),
                    tags$p("Select a PNG or JPG image file to use as a canvas background"),
                    div(style = "display:none;",
                        fileInput(ns("image_upload"), NULL, accept = c(".png", ".jpg", ".jpeg"))
                    ),
                    actionButton(ns("btn_upload"), "Choose File",
                                class = "ui large black button",
                                tags$i(class = "upload icon"))
                )
            )
        ),

        # TRAY PANEL
        div(id = ns("panel-tray"), class = "steps-panel", `data-panel` = "tray",
            div(class = "ui two column equal width stackable grid tray-grid",

                # LEFT: Form
                div(class = "column tray-left",
                    div(class = "ui segment",
                        div(class = "ui form",
                            # Name
                            div(class = "field",
                                tags$label("Canvas Name"),
                                textInput(ns("canvas_name"), NULL, placeholder = "Enter name for this canvas")
                            ),
                            # Size info (static display)
                            div(class = "field",
                                tags$label("Image Information"),
                                div(class = "ui segment",
                                    style = "background:#f9f9f9; padding:0.75rem;",
                                    uiOutput(ns("size_info_display"))
                                )
                            ),
                            # Save button
                            div(class = "field",
                                actionButton(ns("btn_save"), "Save to Library",
                                           class = "fluid ui black button")
                            )
                        )
                    )
                ),

                # RIGHT: Preview
                div(class = "column tray-right",
                    div(class = "ui segment",
                        div(id = ns("canvas_preview_container"),
                            div(style = "color:#999; font-size:0.95em; text-align:center;",
                                tags$i(class = "eye slash outline icon large"),
                                tags$div("Preview will appear here")
                            )
                        ),
                        div(class = "dimension-info",
                            textOutput(ns("dimension_display"))
                        )
                    )
                )
            )
        ),

        # LIBRARY PANEL
        div(id = ns("panel-library"), class = "steps-panel", `data-panel` = "library",
            div(class = "ui right aligned basic segment",
                actionButton(ns("btn_refresh"), "Refresh", class = "ui small button")
            ),
            uiOutput(ns("library_ui"))
        ),

        # JavaScript - Steps navigation
        tags$script(HTML(sprintf("
(function(){
  var rootId = '%s';
  var root = document.getElementById(rootId);
  if (!root) return;

  function activate(step){
    root.querySelectorAll('.ui.steps .step').forEach(function(el){
      el.classList.toggle('active', el.dataset.step === step);
    });
    root.querySelectorAll('.steps-panel').forEach(function(p){
      p.classList.toggle('active', p.dataset.panel === step);
    });
    if (window.Shiny) {
      Shiny.setInputValue('%s', step, {priority: 'event'});
    }
  }

  root._setStep = activate;

  root.addEventListener('click', function(e){
    var step = e.target.closest('.ui.steps .step');
    if (step && root.contains(step)) {
      e.preventDefault();
      activate(step.dataset.step);
    }
  });

  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('canvas-set-step', function(msg){
      if (msg.rootId === rootId || !msg.rootId) {
        activate(msg.step || 'upload');
      }
    });
  }

  activate('upload');
})();
", ns("root"), ns("current_step")))),

        # JavaScript - Upload button trigger
        tags$script(HTML(sprintf("
(function(){
  var btn = document.getElementById('%s');
  var input = document.getElementById('%s');
  if (btn && input) {
    btn.addEventListener('click', function(){ input.click(); });
  }
})();
", ns("btn_upload"), ns("image_upload")))),

        # JavaScript - Preview update handler
        tags$script(HTML(sprintf("
(function(){
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('canvas-update-preview', function(msg){
      var container = document.getElementById(msg.targetId);
      if (!container) return;
      container.innerHTML = msg.html || '';
    });
  }
})();
")))
    )
  )
}


# ================== SERVER ==================

f_browser_canvas_server <- function(id, pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # State
    rv <- reactiveValues(
      current_image = NULL,  # Base64 PNG
      width_px = NULL,
      height_px = NULL,
      file_size_kb = NULL
    )

    library_data <- reactiveVal(NULL)

    # DB connection
    conn <- NULL
    conn_error <- NULL
    tryCatch({
      conn <- db_pool()
      if (is.null(conn)) {
        conn_error <- "db_pool() returned NULL"
      }
    }, error = function(e) {
      conn_error <<- conditionMessage(e)
    })

    # Init: disable buttons
    session$onFlushed(function(){
      shinyjs::disable("btn_save")

      # Check connection
      if (!is.null(conn)) {
        # Check table schema
        schema_check <- tryCatch({
          check_canvases_table(conn)
        }, error = function(e) {
          list(exists = FALSE, message = paste("Schema check failed:", conditionMessage(e)))
        })

        if (!isTRUE(schema_check$exists)) {
          showNotification(
            HTML(paste0(
              "<strong>Canvases table not found!</strong><br/>",
              "Please run the SQL script at:<br/>",
              "<code>R/db/schema_canvases.sql</code>"
            )),
            type = "error",
            duration = NULL
          )
        }

        # Load library on startup
        refresh_library()
      } else {
        showNotification(
          "Database connection failed. You can browse but cannot save.",
          type = "warning",
          duration = NULL
        )
      }
    }, once = TRUE)

    # Size info display (in form)
    output$size_info_display <- renderUI({
      if (is.null(rv$width_px) || is.null(rv$height_px)) {
        div(style = "color:#999;", "No image loaded")
      } else {
        tagList(
          div(style = "margin-bottom:0.5rem;",
              tags$strong("Dimensions: "),
              sprintf("%d × %d pixels", rv$width_px, rv$height_px)
          ),
          if (!is.null(rv$file_size_kb)) {
            div(
              tags$strong("File Size: "),
              sprintf("%.1f KB", rv$file_size_kb)
            )
          }
        )
      }
    })

    # Force size info to render even when panel is hidden
    outputOptions(output, "size_info_display", suspendWhenHidden = FALSE)

    # Dimension display (below preview) - simplified
    output$dimension_display <- renderText({
      if (is.null(rv$width_px) || is.null(rv$height_px)) {
        ""
      } else {
        sprintf("%d × %d pixels", rv$width_px, rv$height_px)
      }
    })

    # LIBRARY UI
    output$library_ui <- renderUI({
      df <- library_data()

      if (is.null(df)) {
        return(div(class = "ui info message", "Loading canvases..."))
      }

      if (is.data.frame(df) && nrow(df) == 0) {
        return(div(class = "ui warning message", "No canvases saved yet"))
      }

      if (!is.data.frame(df)) {
        return(div(class = "ui error message", "Error loading library"))
      }

      # Grid of canvases
      div(class = "ui doubling stackable grid results-grid",
          lapply(seq_len(nrow(df)), function(i) {
            safe_id <- gsub("[^A-Za-z0-9_]", "_", paste0("canvas_", df$id[i]))
            div(class = "three wide computer four wide tablet eight wide mobile column",
                div(class = "result-card",
                    # Display image
                    if (!is.null(df$bg_png_b64[i]) && nzchar(df$bg_png_b64[i])) {
                      tags$img(src = paste0("data:image/png;base64,", df$bg_png_b64[i]))
                    } else {
                      tags$i(class = "image outline icon", style = "font-size:48px;color:#ccc;")
                    },
                    div(class = "label",
                        sprintf("#%d: %s", df$id[i], df$canvas_name[i]),
                        tags$br(),
                        tags$small(sprintf("%d�%d", df$width_px[i], df$height_px[i]))
                    ),
                    actionButton(ns(paste0("delete_", safe_id)), "Delete",
                               class = "ui tiny red button fluid",
                               style = "margin-top:4px;",
                               onclick = sprintf("Shiny.setInputValue('%s', %d, {priority: 'event'})",
                                                ns("delete_clicked"), df$id[i]))
                )
            )
          })
      )
    })

    # Force output to render even when hidden
    outputOptions(output, "library_ui", suspendWhenHidden = FALSE)

    # UPLOAD HANDLER
    observeEvent(input$image_upload, {
      file <- input$image_upload
      req(file$datapath)

      # Read image and convert to PNG base64
      tryCatch({
        # Detect file type
        ext <- tolower(tools::file_ext(file$name))

        # Read image and get dimensions
        if (ext == "png") {
          img <- png::readPNG(file$datapath, native = FALSE)
          width <- ncol(img)
          height <- nrow(img)

          # Already PNG, just read raw bytes for base64
          png_raw <- readBin(file$datapath, "raw", file.info(file$datapath)$size)
        } else if (ext %in% c("jpg", "jpeg")) {
          img <- jpeg::readJPEG(file$datapath, native = FALSE)
          width <- ncol(img)
          height <- nrow(img)

          # Convert JPEG to PNG
          tmp <- tempfile(fileext = ".png")
          on.exit(unlink(tmp), add = TRUE)
          png::writePNG(img, tmp)
          png_raw <- readBin(tmp, "raw", file.info(tmp)$size)
        } else {
          showNotification(paste("Unsupported file type:", ext, "- Please use PNG or JPEG"),
                         type = "error")
          return()
        }

        png_b64 <- base64enc::base64encode(png_raw)

        # Store in reactive values
        rv$current_image <- png_b64
        rv$width_px <- width
        rv$height_px <- height
        rv$file_size_kb <- round(length(png_raw) / 1024, 1)

        # Update preview by replacing container content via JavaScript
        session$sendCustomMessage("canvas-update-preview", list(
          targetId = ns("canvas_preview_container"),
          html = as.character(tags$img(src = paste0("data:image/png;base64,", png_b64)))
        ))

        # Set default name
        name <- gsub("\\.[^.]+$", "", basename(file$name))
        updateTextInput(session, "canvas_name", value = name)

        # Enable save
        shinyjs::enable("btn_save")

        # Go to tray
        session$sendCustomMessage("canvas-set-step", list(
          rootId = ns("root"),
          step = "tray"
        ))

      }, error = function(e) {
        showNotification(paste("Failed to process image:", conditionMessage(e)),
                       type = "error")
      })
    }, ignoreInit = TRUE)

    # SAVE TO LIBRARY
    observeEvent(input$btn_save, {
      req(conn)

      if (is.null(rv$current_image)) {
        showNotification("No canvas loaded", type = "error")
        return()
      }

      name <- trimws(f_or(input$canvas_name, "canvas"))
      if (!nzchar(name)) name <- "canvas"

      payload <- list(
        canvas_name = name,
        width_px = rv$width_px,
        height_px = rv$height_px,
        bg_png_b64 = rv$current_image
      )

      success <- tryCatch({
        insert_canvas(conn, payload)
        TRUE
      }, error = function(e) {
        showNotification(paste("Save failed:", conditionMessage(e)), type = "error")
        FALSE
      })

      if (success) {
        showNotification("Canvas saved!", type = "message")
        refresh_library()
        session$sendCustomMessage("canvas-set-step", list(rootId = ns("root"), step = "library"))
      }
    }, ignoreInit = TRUE)

    # LIBRARY - Refresh function
    refresh_library <- function() {
      df <- tryCatch(fetch_canvases(conn), error = function(e) {
        cat("ERROR fetching canvases:", conditionMessage(e), "\n")
        NULL
      })
      library_data(df)
    }

    # Refresh library when tab clicked
    observeEvent(input$current_step, {
      if (input$current_step == "library") {
        req(conn)
        refresh_library()
      }
    }, ignoreInit = TRUE)

    observeEvent(input$btn_refresh, {
      req(conn)
      refresh_library()
    }, ignoreInit = TRUE)

    # DELETE HANDLER
    observeEvent(input$delete_clicked, {
      req(conn)
      canvas_id <- input$delete_clicked

      # Check usage
      usage <- tryCatch({
        check_canvas_usage(conn, canvas_id)
      }, error = function(e) {
        list()
      })

      if (length(usage) > 0) {
        usage_text <- sapply(names(usage), function(table) {
          sprintf("%s (%d)", table, usage[[table]])
        })
        showNotification(
          HTML(paste0(
            "<strong>Cannot delete canvas #", canvas_id, ":</strong><br/>",
            "Used in: ", paste(usage_text, collapse=", ")
          )),
          type = "warning",
          duration = 10
        )
        return()
      }

      # Safe to delete
      success <- tryCatch({
        delete_canvas(conn, canvas_id)
        TRUE
      }, error = function(e) {
        showNotification(paste("Delete failed:", conditionMessage(e)), type = "error")
        FALSE
      })

      if (success) {
        showNotification(sprintf("Deleted canvas #%d", canvas_id), type = "message")
        refresh_library()
      }
    }, ignoreInit = TRUE)
  })
}
