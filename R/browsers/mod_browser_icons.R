# R/browsers/f_browser_icons.R - CLEAN VERSION
# Simplified icon browser with working preview

f_browser_icons_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Scoped CSS
    f_scoped_css(ns("root"), c(
      # Panel visibility
      ".steps-panel{display:none;}",
      ".steps-panel.active{display:block;}",
      
      # Search panel - centered narrow container
      ".vstack-wrap{margin:.25rem 0;}",
      ".slim-vseg.ui.segments{width:33.333%; max-width:520px; min-width:340px; margin:0 auto;}",
      ".slim-vseg.ui.segments>.segment{padding:.45rem .65rem!important;}",
      ".slim-vseg .seg-top .ui.fluid.icon.input.small>input{height:32px;}",
      ".slim-vseg .seg-or{padding:.25rem .45rem!important; text-align:center;}",
      ".slim-vseg .seg-bottom .ui.button.small{padding:.48rem .8rem;}",
      ".slim-vseg .seg-top input{text-align:left;}",
      ".slim-vseg .seg-top input:placeholder-shown{text-align:center;}",
      
      # Results grid
      ".results-grid.ui.grid{margin-top:.25rem;}",
      ".results-grid .column{padding:.4rem!important;}",
      ".result-card{border:1px solid #e9ecef;border-radius:.5rem;padding:8px;text-align:center;transition:all 0.2s;}",
      ".result-card:hover{border-color:#2185d0; box-shadow:0 2px 4px rgba(0,0,0,0.1);}",
      ".result-card img{height:48px;width:48px;object-fit:contain;display:block;margin:0 auto 6px;}",
      ".result-card .label{font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin:4px 2px 6px;}",
      ".result-card .ui.button{font-size:.8rem;padding:.3rem .5rem; margin-top:4px;}",
      
      # Tray - equal columns
      ".tray-grid{margin-top:.5rem;}",
      ".tray-grid .column{padding:.5rem!important;}",
      ".tray-left, .tray-right{height:100%; min-height:300px;}",
      ".tray-left .ui.segment{height:100%; display:flex; align-items:center; padding:1.5rem!important;}",
      ".tray-left .ui.form{width:100%;}",
      ".tray-right .ui.segment{height:100%; display:flex; align-items:center; justify-content:center; background:#fafafa; padding:1.5rem!important;}",
      
      # Preview - CRITICAL STYLING
      paste0("#", ns("icon_preview_container"), 
             "{width:100%; max-width:240px; min-height:240px; margin:auto;",
             " border:2px dashed #d4d4d5; border-radius:12px; background:#fff;",
             " display:flex; align-items:center; justify-content:center; padding:2rem;}"),
      paste0("#", ns("icon_preview_container"), " svg",
             "{max-width:180px; max-height:180px; width:auto; height:auto; display:block;}"),
      paste0("#", ns("icon_preview_container"), " img",
             "{max-width:180px; max-height:180px; width:auto; height:auto; display:block;}"),
      
      # Color picker
      ".color-field{display:flex; align-items:center; gap:0.75rem;}",
      ".color-field input[type='color']{width:64px; height:40px; border-radius:6px; border:1px solid #ddd; cursor:pointer;}",
      ".color-hex-text{flex:1; font-family:monospace; font-size:1em; padding:0.5rem; background:#f9f9f9; border-radius:4px;}",
      
      # Library
      ".library-grid{margin-top:1rem;}",
      ".library-card{border:1px solid #ddd; border-radius:8px; padding:12px; text-align:center; cursor:pointer; transition:all 0.2s;}",
      ".library-card:hover{border-color:#2185d0; box-shadow:0 2px 4px rgba(0,0,0,0.1);}",
      ".library-card.selected{border-color:#21ba45; border-width:2px; background:#f0fff4;}",
      ".library-card img{width:48px; height:48px; margin:0 auto 8px; display:block;}",
      ".library-card .name{font-size:11px; color:#666; margin-top:4px;}"
    )),
    
    div(id = ns("root"),
        
        # Steps header
        div(class = "ui three steps",
            a(class = "active step", `data-step` = "search",
              tags$i(class = "search icon"),
              div(class = "content",
                  div(class = "title", "Search"),
                  div(class = "description", "Find or upload")
              )
            ),
            a(class = "step", `data-step` = "tray",
              tags$i(class = "inbox icon"),
              div(class = "content",
                  div(class = "title", "Tray"),
                  div(class = "description", "Edit & preview")
              )
            ),
            a(class = "step", `data-step` = "library",
              tags$i(class = "book icon"),
              div(class = "content",
                  div(class = "title", "Library"),
                  div(class = "description", "Saved icons")
              )
            )
        ),
        
        # SEARCH PANEL
        div(id = ns("panel-search"), class = "steps-panel active", `data-panel` = "search",
            div(class = "vstack-wrap",
                div(class = "ui segments slim-vseg",
                    div(class = "ui segment seg-top",
                        div(class = "ui search", id = ns("sem_search"),
                            div(class = "ui fluid icon input small",
                                tags$input(
                                  id = ns("q_prompt"),
                                  class = "prompt",
                                  type = "text",
                                  placeholder = "Search icons (press Enter)"
                                ),
                                tags$i(class = "search icon")
                            )
                        )
                    ),
                    div(class = "ui center aligned secondary segment seg-or",
                        div(class = "ui header tiny", "OR")
                    ),
                    div(class = "ui segment seg-bottom",
                        div(style = "display:none;",
                            fileInput(ns("svg_upload"), NULL, accept = ".svg")
                        ),
                        tags$button(
                          id = ns("btn_upload"),
                          class = "black fluid ui labeled icon button small",
                          tags$i(class = "upload icon"),
                          "Upload SVG"
                        )
                    )
                )
            ),
            div(class = "ui basic segment", uiOutput(ns("results_ui")))
        ),
        
        # TRAY PANEL - CLEAN VERSION
        div(id = ns("panel-tray"), class = "steps-panel", `data-panel` = "tray",
            div(class = "ui two column equal width stackable grid tray-grid",
                
                # LEFT: Form
                div(class = "column tray-left",
                    div(class = "ui segment",
                        div(class = "ui form",
                            # Name
                            div(class = "field",
                                tags$label("Display Name"),
                                textInput(ns("display_name"), NULL, placeholder = "Icon name")
                            ),
                            # Color with hex display
                            div(class = "field",
                                tags$label("Color"),
                                div(class = "color-field",
                                    tags$input(
                                      id = ns("color_hex"),
                                      type = "color",
                                      value = "#2185d0"
                                    ),
                                    textOutput(ns("color_display"), inline = TRUE,
                                               container = function(x) tags$div(class = "color-hex-text", x))
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
                
                # RIGHT: Preview only
                div(class = "column tray-right",
                    div(class = "ui segment",
                        div(id = ns("icon_preview_container"),
                            div(style = "color:#999; font-size:0.95em; text-align:center;", 
                                tags$i(class = "eye slash outline icon large"),
                                tags$div("Preview will appear here")
                            )
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
            uiOutput(ns("library_ui")),
            div(class = "ui basic segment",
                actionButton(ns("btn_delete"), "Delete Selected",
                             class = "ui red button")
            )
        ),
        
        # JavaScript - Preview handler with detailed logging
        tags$script(HTML(sprintf("
(function(){
  var targetId = '%s';
  var ackId = '%s';
  
  console.log('[Icons] Initializing preview handler for:', targetId);
  
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('icons-preview-html', function(msg){
      console.log('[Icons] Preview message received:', {
        targetId: msg.targetId,
        htmlLength: (msg.html || '').length,
        htmlPreview: (msg.html || '').substring(0, 100)
      });
      
      var container = document.getElementById(msg.targetId);
      if (!container) {
        console.error('[Icons] Preview container not found:', msg.targetId);
        if (window.Shiny) {
          Shiny.setInputValue(ackId, {ok: false, reason: 'container_not_found'}, {priority: 'event'});
        }
        return;
      }
      
      container.innerHTML = msg.html || '<div style=\"color:#e03997;\">Empty preview</div>';
      console.log('[Icons] Preview updated successfully');
      
      if (window.Shiny) {
        Shiny.setInputValue(ackId, {ok: true, length: (msg.html || '').length}, {priority: 'event'});
      }
    });
    console.log('[Icons] Preview handler registered');
  } else {
    console.error('[Icons] Shiny not available for custom message handler');
  }
})();
", ns("icon_preview_container"), ns("preview_ack")))),
        
        # JavaScript - Steps navigation
        tags$script(HTML(sprintf("
(function(){
  var rootId = '%s';
  var root = document.getElementById(rootId);
  if (!root) return;
  
  function activate(step){
    console.log('[Icons] Activating step:', step);
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
    Shiny.addCustomMessageHandler('icons-set-step', function(msg){
      if (msg.rootId === rootId || !msg.rootId) {
        activate(msg.step || 'search');
      }
    });
  }
  
  activate('search');
})();
", ns("root"), ns("current_step")))),
        
        # JavaScript - Search enter key
        tags$script(HTML(sprintf("
(function(){
  var promptId = '%s';
  var prompt = document.getElementById(promptId);
  
  if (prompt) {
    prompt.addEventListener('keydown', function(e){
      if (e.key === 'Enter') {
        e.preventDefault();
        var val = prompt.value.trim();
        console.log('[Icons] Search:', val);
        if (window.Shiny) {
          Shiny.setInputValue('%s', val, {priority: 'event'});
        }
      }
    });
  }
})();
", ns("q_prompt"), ns("search_query")))),
        
        # JavaScript - Upload button
        tags$script(HTML(sprintf("
(function(){
  var btn = document.getElementById('%s');
  var input = document.getElementById('%s');
  if (btn && input) {
    btn.addEventListener('click', function(){ input.click(); });
  }
})();
", ns("btn_upload"), ns("svg_upload")))),
        
        # JavaScript - Color picker
        tags$script(HTML(sprintf("
(function(){
  var picker = document.getElementById('%s');
  if (picker) {
    var update = function(){
      console.log('[Icons] Color changed:', picker.value);
      if (window.Shiny) {
        Shiny.setInputValue('%s', picker.value, {priority: 'event'});
      }
    };
    picker.addEventListener('input', update);
    picker.addEventListener('change', update);
  }
})();
", ns("color_hex"), ns("color_hex"))))
    )
  )
}


# ================== SERVER ==================

f_browser_icons_server <- function(id, pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # State
    rv <- reactiveValues(
      current_svg = NULL,
      recolored_svg = NULL
    )
    
    search_results <- reactiveVal(character(0))
    selected_library_ids <- reactiveVal(integer(0))
    
    # Get helper functions
    .get <- function(...) {
      for (n in c(...)) {
        if (exists(n, mode = "function", inherits = TRUE)) {
          return(get(n, inherits = TRUE))
        }
      }
      stop("Helper function not found: ", paste(c(...), collapse = " or "))
    }
    
    iconify_search <- .get("f_iconify_search_all", "iconify_search_all")
    fetch_svg <- .get("f_fetch_iconify_svg", "fetch_iconify_svg")
    sanitize_svg <- .get("f_sanitize_svg", "sanitize_svg")
    recolor_svg <- .get("f_recolor_svg", "recolor_svg")
    
    # SVG cleaning
    clean_svg_for_html <- function(svg) {
      # Remove XML/DOCTYPE headers
      svg <- sub("^\\s*<\\?xml[^>]*>\\s*", "", svg, perl = TRUE)
      svg <- sub("^\\s*<!DOCTYPE[^>]*>\\s*", "", svg, perl = TRUE)
      # Ensure xmlns
      if (grepl("<svg", svg, fixed = TRUE) && !grepl("xmlns=", svg)) {
        svg <- sub("<svg", '<svg xmlns="http://www.w3.org/2000/svg"', svg)
      }
      svg
    }
    
    # CORE: Render preview with detailed logging
    render_preview <- function(svg_txt) {
      cat("\n=== RENDER PREVIEW CALLED ===\n")
      cat("SVG text length:", nchar(f_or(svg_txt, "")), "\n")
      
      if (is.null(svg_txt) || !nzchar(svg_txt)) {
        cat("Empty SVG - showing placeholder\n")
        session$sendCustomMessage("icons-preview-html", list(
          targetId = ns("icon_preview_container"),
          html = '<div style="color:#999;text-align:center;"><i class="eye slash outline icon large"></i><div>No icon loaded</div></div>'
        ))
        return(invisible())
      }
      
      # Get color
      color <- f_or(input$color_hex, "#2185d0")
      cat("Applying color:", color, "\n")
      
      # Recolor
      svg_colored <- tryCatch({
        recolor_svg(svg_txt, color)
      }, error = function(e) {
        cat("Recolor failed:", conditionMessage(e), "\n")
        svg_txt
      })
      
      if (!nzchar(svg_colored)) svg_colored <- svg_txt
      
      # Clean for HTML
      svg_clean <- clean_svg_for_html(svg_colored)
      cat("Cleaned SVG length:", nchar(svg_clean), "\n")
      cat("SVG preview (first 200 chars):", substring(svg_clean, 1, 200), "\n")
      
      # Store
      rv$recolored_svg <- svg_clean
      
      # Send to browser
      cat("Sending to browser, target ID:", ns("icon_preview_container"), "\n")
      session$sendCustomMessage("icons-preview-html", list(
        targetId = ns("icon_preview_container"),
        html = svg_clean
      ))
      
      cat("=== RENDER PREVIEW COMPLETE ===\n\n")
      invisible()
    }
    
    # Color hex display
    output$color_display <- renderText({
      toupper(f_or(input$color_hex, "#2185D0"))
    })
    
    # Preview acknowledgment
    observeEvent(input$preview_ack, {
      if (isTRUE(input$preview_ack$ok)) {
        cat("✓ Preview rendered successfully\n")
      } else {
        cat("✗ Preview render failed:", f_or(input$preview_ack$reason, "unknown"), "\n")
      }
    }, ignoreInit = TRUE)
    
    # DB connection
    conn <- NULL
    try({ conn <- db_get_connection() }, silent = TRUE)
    
    # Init: disable buttons
    session$onFlushed(function(){
      shinyjs::disable(ns("btn_save"))
      shinyjs::disable(ns("btn_delete"))
    }, once = TRUE)
    
    # SEARCH
    observeEvent(input$search_query, {
      q <- trimws(input$search_query)
      cat("\n>>> SEARCH:", q, "\n")
      
      if (!nzchar(q)) {
        search_results(character(0))
        return()
      }
      
      ids <- tryCatch({
        iconify_search(q, limit = 48)
      }, error = function(e) {
        cat("Search error:", conditionMessage(e), "\n")
        character(0)
      })
      
      cat("Found", length(ids), "results\n")
      search_results(ids)
    }, ignoreInit = TRUE)
    
    # UPLOAD
    observeEvent(input$svg_upload, {
      file <- input$svg_upload
      req(file$datapath)
      
      cat("\n>>> FILE UPLOADED:", file$name, "\n")
      
      raw <- paste(readLines(file$datapath, warn = FALSE), collapse = "\n")
      clean <- tryCatch(sanitize_svg(raw), error = function(e) "")
      
      if (!nzchar(clean)) {
        showNotification("Failed to process SVG file", type = "error")
        return()
      }
      
      rv$current_svg <- clean
      render_preview(clean)
      
      # Set name
      name <- gsub("\\.svg$", "", basename(file$name), ignore.case = TRUE)
      updateTextInput(session, "display_name", value = name)
      
      # Enable save
      shinyjs::enable(ns("btn_save"))
      
      # Go to tray
      session$sendCustomMessage("icons-set-step", list(
        rootId = ns("root"),
        step = "tray"
      ))
    }, ignoreInit = TRUE)
    
    # SEARCH RESULTS
    output$results_ui <- renderUI({
      ids <- search_results()
      if (!length(ids)) return(NULL)
      
      div(class = "ui doubling stackable grid results-grid",
          lapply(ids, function(id) {
            parts <- strsplit(id, ":", fixed = TRUE)[[1]]
            safe_id <- gsub("[^A-Za-z0-9_]", "_", id)
            
            div(class = "two wide computer four wide tablet eight wide mobile column",
                div(class = "result-card",
                    if (length(parts) == 2) {
                      tags$img(src = sprintf("%s/%s/%s.svg?height=48", ICONIFY_BASE, parts[1], parts[2]))
                    },
                    div(class = "label", htmltools::htmlEscape(id)),
                    actionButton(ns(paste0("load_", safe_id)), "Load", class = "ui tiny black button fluid")
                )
            )
          })
      )
    })
    
    # LOAD ICON TO TRAY
    observe({
      ids <- search_results()
      lapply(ids, function(id) {
        safe_id <- gsub("[^A-Za-z0-9_]", "_", id)
        observeEvent(input[[paste0("load_", safe_id)]], {
          cat("\n>>> LOADING ICON:", id, "\n")
          
          svg <- tryCatch(fetch_svg(id), error = function(e) "")
          if (!nzchar(svg)) {
            showNotification("Failed to fetch icon", type = "error")
            return()
          }
          
          clean <- tryCatch(sanitize_svg(svg), error = function(e) "")
          if (!nzchar(clean)) {
            showNotification("Failed to process icon", type = "error")
            return()
          }
          
          rv$current_svg <- clean
          render_preview(clean)
          
          # Set name
          updateTextInput(session, "display_name", value = gsub(":", "-", id))
          
          # Enable save
          shinyjs::enable(ns("btn_save"))
          
          # Go to tray
          session$sendCustomMessage("icons-set-step", list(
            rootId = ns("root"),
            step = "tray"
          ))
        }, ignoreInit = TRUE, once = TRUE)
      })
    })
    
    # COLOR CHANGE
    observeEvent(input$color_hex, {
      cat("\n>>> COLOR CHANGED:", input$color_hex, "\n")
      if (!is.null(rv$current_svg) && nzchar(rv$current_svg)) {
        render_preview(rv$current_svg)
      }
    }, ignoreInit = TRUE)
    
    # SAVE TO LIBRARY
    observeEvent(input$btn_save, {
      req(conn, rv$recolored_svg)
      
      name <- trimws(f_or(input$display_name, "icon"))
      if (!nzchar(name)) name <- "icon"
      
      cat("\n>>> SAVING:", name, "\n")
      
      payload <- tryCatch({
        f_build_payload(icon_name = name, svg_txt = rv$recolored_svg)
      }, error = function(e) {
        showNotification(paste("Error:", conditionMessage(e)), type = "error")
        NULL
      })
      
      req(payload)
      
      success <- tryCatch({
        insert_icon(conn, payload)
        TRUE
      }, error = function(e) {
        showNotification(paste("Save failed:", conditionMessage(e)), type = "error")
        FALSE
      })
      
      if (success) {
        showNotification("Icon saved!", type = "message")
        refresh_library()
        session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "library"))
      }
    }, ignoreInit = TRUE)
    
    # LIBRARY
    refresh_library <- function() {
      df <- tryCatch(fetch_icons(conn), error = function(e) NULL)
      
      if (is.null(df) || !nrow(df)) {
        output$library_ui <- renderUI({
          div(class = "ui message", "No icons saved yet")
        })
        return()
      }
      
      output$library_ui <- renderUI({
        div(class = "ui four column doubling stackable grid library-grid",
            lapply(seq_len(nrow(df)), function(i) {
              div(class = "column",
                  div(class = "library-card",
                      `data-id` = df$id[i],
                      onclick = sprintf("toggleLibIcon('%s',%d)", ns("root"), df$id[i]),
                      if (nzchar(df$png_32_b64[i])) {
                        tags$img(src = paste0("data:image/png;base64,", df$png_32_b64[i]))
                      },
                      div(class = "name", sprintf("#%d: %s", df$id[i], df$icon_name[i]))
                  )
              )
            })
        )
      })
    }
    
    observeEvent(input$btn_refresh, {
      req(conn)
      refresh_library()
    }, ignoreInit = TRUE)
    
    # Selection tracking
    observeEvent(input$library_selected, {
      ids <- as.integer(f_or(input$library_selected, integer()))
      selected_library_ids(ids)
      if (length(ids) > 0) {
        shinyjs::enable(ns("btn_delete"))
      } else {
        shinyjs::disable(ns("btn_delete"))
      }
    }, ignoreInit = TRUE)
    
    # DELETE
    observeEvent(input$btn_delete, {
      req(conn)
      ids <- selected_library_ids()
      if (!length(ids)) return()
      
      for (id in ids) {
        tryCatch(delete_icon(conn, id), error = function(e) NULL)
      }
      
      showNotification(sprintf("Deleted %d icon(s)", length(ids)), type = "message")
      selected_library_ids(integer(0))
      shinyjs::disable(ns("btn_delete"))
      refresh_library()
    }, ignoreInit = TRUE)
    
    # Library selection JS
    session$onFlushed(function(){
      session$sendCustomMessage("eval", list(js = sprintf("
if (!window.toggleLibIcon) {
  window.toggleLibIcon = function(rootId, id) {
    var root = document.getElementById(rootId);
    if (!root) return;
    var card = root.querySelector('.library-card[data-id=\"' + id + '\"]');
    if (!card) return;
    card.classList.toggle('selected');
    var selected = Array.from(root.querySelectorAll('.library-card.selected')).map(function(c){
      return parseInt(c.getAttribute('data-id'));
    });
    if (window.Shiny) {
      Shiny.setInputValue('%s', selected, {priority: 'event'});
    }
  };
}
      ", ns("library_selected"))))
    }, once = TRUE)
  })
}