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
      ".slim-vseg .seg-or{padding:0!important; margin:0!important; text-align:center; cursor:pointer; border:none; width:100%; transition:background-color 0.2s;}",
      ".slim-vseg .seg-or:hover{background-color:#e0e0e0;}",
      ".slim-vseg .seg-or .ui.header{margin:.25rem .45rem;}",
      ".slim-vseg .seg-bottom .ui.button.small{padding:.48rem .8rem;}",
      ".slim-vseg .seg-top input{text-align:left;}",
      ".slim-vseg .seg-top input:placeholder-shown{text-align:center;}",
      
      # Results grid
      ".results-grid.ui.grid{margin-top:.25rem;}",
      ".results-grid .column{padding:.4rem!important;}",
      ".result-card{border:1px solid #e9ecef;border-radius:.5rem;padding:8px;text-align:center;transition:all 0.2s;}",
      ".result-card:hover{border-color:#2185d0; box-shadow:0 2px 4px rgba(0,0,0,0.1);}",
      ".result-card img{height:48px;width:48px;object-fit:contain;display:block;margin:0 auto 6px;}",
      ".result-card svg{height:48px;width:48px;object-fit:contain;display:block;margin:0 auto 6px;}",
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
      ".color-picker-group{display:flex; align-items:center; gap:0.75rem;}",
      ".color-picker-group input[type='color']{width:64px; height:40px; border-radius:6px; border:1px solid #ddd; cursor:pointer;}",
      ".color-hex-text{flex:1; font-family:monospace; font-size:1em; padding:0.5rem; background:#f9f9f9; border-radius:4px;}",
      # Color swatches
      ".color-swatches{display:flex; gap:0.5rem; flex-wrap:wrap;}",
      ".color-swatch-btn{cursor:pointer !important; transition:all 0.2s !important; min-width:40px !important; flex-shrink:0 !important;}",
      ".color-swatch-btn:hover{transform:scale(1.1) !important; border-color:#2185d0 !important; box-shadow:0 2px 4px rgba(0,0,0,0.2) !important;}",
      ".color-swatch-btn:focus{outline:none !important; box-shadow:0 0 0 3px rgba(33,133,208,0.3) !important;}"
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
                    tags$button(
                      id = ns("btn_search_confirm"),
                      class = "ui center aligned secondary segment seg-or",
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
                            # Color picker
                            div(class = "field",
                                tags$label("Color"),
                                div(class = "color-picker-group",
                                    tags$input(
                                      id = ns("color_hex"),
                                      type = "color",
                                      value = "#2185d0"
                                    ),
                                    div(class = "color-hex-text", textOutput(ns("color_display"), inline = TRUE))
                                )
                            ),
                            # Top 3 color swatches (separate field below)
                            div(class = "field",
                                tags$label("Top 3 Used Colors"),
                                div(class = "color-swatches",
                                    actionButton(
                                      ns("swatch_1"),
                                      label = "",
                                      class = "ui circular button color-swatch-btn",
                                      style = "background-color:#2185d0 !important; width:28px; height:28px; padding:0; border:2px solid #ddd;"
                                    ),
                                    actionButton(
                                      ns("swatch_2"),
                                      label = "",
                                      class = "ui circular button color-swatch-btn",
                                      style = "background-color:#000000 !important; width:28px; height:28px; padding:0; border:2px solid #ddd; margin-left:0.4rem;"
                                    ),
                                    actionButton(
                                      ns("swatch_3"),
                                      label = "",
                                      class = "ui circular button color-swatch-btn",
                                      style = "background-color:#db2828 !important; width:28px; height:28px; padding:0; border:2px solid #ddd; margin-left:0.4rem;"
                                    )
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
            uiOutput(ns("library_ui"))
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

        # JavaScript - Search confirm button
        tags$script(HTML(sprintf("
(function(){
  var btn = document.getElementById('%s');
  var prompt = document.getElementById('%s');
  if (btn && prompt) {
    btn.addEventListener('click', function(e){
      e.preventDefault();
      var val = prompt.value.trim();
      console.log('[Icons] Search confirm clicked:', val);
      if (window.Shiny && val) {
        Shiny.setInputValue('%s', val, {priority: 'event'});
      }
    });
  }
})();
", ns("btn_search_confirm"), ns("q_prompt"), ns("search_query")))),
        
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
", ns("color_hex"), ns("color_hex")))),

        # JavaScript - Set color picker without triggering events
        tags$script(HTML(sprintf("
(function(){
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('icons-set-color', function(msg){
      console.log('[Icons] Setting color silently:', msg.color);
      var picker = document.getElementById('%s');
      if (picker) {
        picker.value = msg.color;
        console.log('[Icons] Color picker updated to:', picker.value);
      } else {
        console.error('[Icons] Color picker not found');
      }
    });
  }
})();
", ns("color_hex")))),

        # JavaScript - Update swatch colors
        tags$script(HTML(sprintf("
(function(){
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('icons-update-swatches', function(msg){
      console.log('[Icons] Updating swatches:', msg.colors);
      var swatch1 = document.getElementById('%s');
      var swatch2 = document.getElementById('%s');
      var swatch3 = document.getElementById('%s');

      if (swatch1 && msg.colors[0]) {
        swatch1.style.backgroundColor = msg.colors[0];
        swatch1.setAttribute('data-color', msg.colors[0]);
        console.log('[Icons] Swatch 1 updated to:', msg.colors[0]);
      }
      if (swatch2 && msg.colors[1]) {
        swatch2.style.backgroundColor = msg.colors[1];
        swatch2.setAttribute('data-color', msg.colors[1]);
        console.log('[Icons] Swatch 2 updated to:', msg.colors[1]);
      }
      if (swatch3 && msg.colors[2]) {
        swatch3.style.backgroundColor = msg.colors[2];
        swatch3.setAttribute('data-color', msg.colors[2]);
        console.log('[Icons] Swatch 3 updated to:', msg.colors[2]);
      }
    });
  }
})();
", ns("swatch_1"), ns("swatch_2"), ns("swatch_3"))))
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
      recolored_svg = NULL,
      current_color = "#2185d0"  # Track current color
    )

    search_results <- reactiveVal(character(0))
    top_colors <- reactiveVal(c("#2185d0", "#000000", "#db2828"))  # Default placeholders
    library_data <- reactiveVal(NULL)  # Store library icons data
    delete_icon_id <- reactiveVal(NULL)  # Track which icon delete button was clicked
    
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

    # Query top 3 colors from database
    fetch_top_colors <- function() {
      defaults <- c("#2185d0", "#000000", "#db2828")

      if (is.null(conn)) {
        return(defaults)
      }

      colors <- tryCatch({
        # SQL query for top 3 colors
        query <- "SELECT TOP 3 primary_color, COUNT(*) as cnt FROM Icons WHERE primary_color IS NOT NULL GROUP BY primary_color ORDER BY COUNT(*) DESC"
        result <- DBI::dbGetQuery(conn, query)

        if (is.null(result) || nrow(result) == 0) {
          return(defaults)
        }

        # Extract colors and pad with defaults if needed
        cols <- result$primary_color

        if (length(cols) < 3) {
          cols <- c(cols, defaults[(length(cols)+1):3])
        }

        cols[1:3]
      }, error = function(e) {
        defaults
      })

      colors
    }

    # Extract original color from SVG
    extract_svg_color <- function(svg) {
      # Default fallback
      default_color <- "#2185d0"

      if (is.null(svg) || !nzchar(svg)) return(default_color)

      # Look for fill attribute in hex format
      fill_match <- regmatches(svg, regexpr('fill=["\']?(#[0-9A-Fa-f]{6})["\']?', svg, perl = TRUE))
      if (length(fill_match) > 0) {
        color <- sub('fill=["\']?(#[0-9A-Fa-f]{6})["\']?', '\\1', fill_match[1], perl = TRUE)
        cat("Extracted fill color:", color, "\n")
        return(tolower(color))
      }

      # Look for stroke attribute in hex format
      stroke_match <- regmatches(svg, regexpr('stroke=["\']?(#[0-9A-Fa-f]{6})["\']?', svg, perl = TRUE))
      if (length(stroke_match) > 0) {
        color <- sub('stroke=["\']?(#[0-9A-Fa-f]{6})["\']?', '\\1', stroke_match[1], perl = TRUE)
        cat("Extracted stroke color:", color, "\n")
        return(tolower(color))
      }

      # Look for currentColor (means it inherits, treat as black)
      if (grepl('fill="currentColor"', svg, fixed = TRUE) ||
          grepl("fill='currentColor'", svg, fixed = TRUE)) {
        cat("Found currentColor, using black\n")
        return("#000000")
      }

      cat("No color found, using default:", default_color, "\n")
      return(default_color)
    }
    
    # CORE: Render preview with detailed logging
    render_preview <- function(svg_txt, color = NULL) {
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

      # Get color - use provided color or fall back to input
      if (is.null(color)) {
        color <- f_or(input$color_hex, "#2185d0")
      }
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

    # LIBRARY UI - Render icons
    output$library_ui <- renderUI({
      df <- library_data()

      if (is.null(df)) {
        return(div(class = "ui info message", "Loading icons..."))
      }

      if (is.data.frame(df) && nrow(df) == 0) {
        return(div(class = "ui warning message", "No icons saved yet"))
      }

      if (!is.data.frame(df)) {
        return(div(class = "ui error message", "Error loading library"))
      }

      # Use same grid as search results
      div(class = "ui doubling stackable grid results-grid",
          lapply(seq_len(nrow(df)), function(i) {
            safe_id <- gsub("[^A-Za-z0-9_]", "_", paste0("icon_", df$id[i]))
            div(class = "two wide computer four wide tablet eight wide mobile column",
                div(class = "result-card",
                    # Display SVG directly
                    if (!is.null(df$svg[i]) && nzchar(df$svg[i])) {
                      HTML(df$svg[i])
                    } else if (!is.null(df$png_32_b64[i]) && nzchar(df$png_32_b64[i])) {
                      tags$img(src = paste0("data:image/png;base64,", df$png_32_b64[i]))
                    } else {
                      tags$i(class = "question circle outline icon", style = "font-size:48px;color:#ccc;")
                    },
                    div(class = "label", sprintf("#%d: %s", df$id[i], df$icon_name[i])),
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

    # CRITICAL: Force output to render even when panel is hidden
    outputOptions(output, "library_ui", suspendWhenHidden = FALSE)

    # Update swatch colors when top_colors changes
    observeEvent(top_colors(), {
      colors <- top_colors()

      # Ensure we always have 3 colors - use placeholders if missing
      if (length(colors) == 0 || all(is.na(colors)) || any(is.null(colors))) {
        colors <- c("#2185d0", "#000000", "#db2828")  # Blue, Black, Red
      }

      # Replace any NA or NULL with placeholders
      defaults <- c("#2185d0", "#000000", "#db2828")
      colors <- sapply(seq_along(colors), function(i) {
        c <- colors[i]
        if (is.null(c) || is.na(c) || !nzchar(c)) defaults[i] else c
      })

      # Send to JavaScript
      session$sendCustomMessage("icons-update-swatches", list(
        colors = as.character(colors)
      ))
    }, ignoreInit = FALSE)
    
    # Preview acknowledgment
    observeEvent(input$preview_ack, {
      if (isTRUE(input$preview_ack$ok)) {
        cat("✓ Preview rendered successfully\n")
      } else {
        cat("✗ Preview render failed:", f_or(input$preview_ack$reason, "unknown"), "\n")
      }
    }, ignoreInit = TRUE)

    # Color swatch button clicks
    observeEvent(input$swatch_1, {
      colors <- top_colors()
      color <- colors[1]
      rv$current_color <- color
      session$sendCustomMessage("icons-set-color", list(color = color))
      if (!is.null(rv$current_svg) && nzchar(rv$current_svg)) {
        render_preview(rv$current_svg, color = color)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$swatch_2, {
      colors <- top_colors()
      color <- colors[2]
      rv$current_color <- color
      session$sendCustomMessage("icons-set-color", list(color = color))
      if (!is.null(rv$current_svg) && nzchar(rv$current_svg)) {
        render_preview(rv$current_svg, color = color)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$swatch_3, {
      colors <- top_colors()
      color <- colors[3]
      rv$current_color <- color
      session$sendCustomMessage("icons-set-color", list(color = color))
      if (!is.null(rv$current_svg) && nzchar(rv$current_svg)) {
        render_preview(rv$current_svg, color = color)
      }
    }, ignoreInit = TRUE)
    
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

    # Init: disable buttons and load top colors
    session$onFlushed(function(){
      shinyjs::disable("btn_save")

      # Load top colors from database
      if (!is.null(conn)) {

        # Check table schema
        schema_check <- tryCatch({
          check_icons_table(conn)
        }, error = function(e) {
          list(exists = FALSE, message = paste("Schema check failed:", conditionMessage(e)))
        })

        if (!isTRUE(schema_check$exists)) {
          showNotification(
            HTML(paste0(
              "<strong>Icons table not found!</strong><br/>",
              "Please run the SQL script at:<br/>",
              "<code>R/db/schema_icons.sql</code><br/>",
              "to create the Icons table."
            )),
            type = "error",
            duration = NULL
          )
        } else if (isTRUE(schema_check$needs_fix)) {
          showNotification(
            HTML(paste0(
              "<strong>Icons table schema issue:</strong><br/>",
              schema_check$message, "<br/>",
              "Please run the SQL script at:<br/>",
              "<code>R/db/schema_icons.sql</code><br/>",
              "to fix the table schema."
            )),
            type = "warning",
            duration = NULL
          )
        }

        colors <- fetch_top_colors()
        top_colors(colors)

        # Load library on startup
        refresh_library()
      } else {
        top_colors(c("#2185d0", "#000000", "#db2828"))

        # Show warning notification to user
        showNotification(
          "Database connection failed. You can browse icons but cannot save them.",
          type = "warning",
          duration = NULL  # Stays visible until dismissed
        )
      }
    }, once = TRUE)
    
    # SEARCH
    observeEvent(input$search_query, {
      q <- trimws(input$search_query)
      
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

      raw <- paste(readLines(file$datapath, warn = FALSE), collapse = "\n")
      clean <- tryCatch(sanitize_svg(raw), error = function(e) "")

      if (!nzchar(clean)) {
        showNotification("Failed to process SVG file", type = "error")
        return()
      }

      # Extract original color from SVG
      original_color <- extract_svg_color(clean)
      cat("Detected original color:", original_color, "\n")

      # Store color in reactive value
      rv$current_color <- original_color

      # Update color picker to match (without triggering recolor)
      session$sendCustomMessage("icons-set-color", list(color = original_color))

      # Store original SVG
      rv$current_svg <- clean

      # Show preview with original color (pass color directly)
      render_preview(clean, color = original_color)

      # Set name
      name <- gsub("\\.svg$", "", basename(file$name), ignore.case = TRUE)
      updateTextInput(session, "display_name", value = name)

      # Enable save
      shinyjs::enable("btn_save")

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

      base_url <- tryCatch(get("ICONIFY_BASE", envir = .GlobalEnv), error = function(e) "https://api.iconify.design")

      div(class = "ui doubling stackable grid results-grid",
          lapply(ids, function(id) {
            parts <- strsplit(id, ":", fixed = TRUE)[[1]]
            safe_id <- gsub("[^A-Za-z0-9_]", "_", id)

            div(class = "two wide computer four wide tablet eight wide mobile column",
                div(class = "result-card",
                    if (length(parts) == 2) {
                      tags$img(src = sprintf("%s/%s/%s.svg?height=48", base_url, parts[1], parts[2]))
                    },
                    div(class = "label", htmltools::htmlEscape(id)),
                    actionButton(ns(paste0("load_", safe_id)), "Load",
                                class = "ui tiny black button fluid",
                                onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                                                 ns("load_icon_clicked"), id))
                )
            )
          })
      )
    })

    # Ensure search results render even when panel is hidden
    outputOptions(output, "results_ui", suspendWhenHidden = FALSE)
    
    # LOAD ICON TO TRAY - Single observer for all load button clicks
    observeEvent(input$load_icon_clicked, {
      id <- input$load_icon_clicked

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

      # Extract original color from SVG
      original_color <- extract_svg_color(clean)
      cat("Detected original color:", original_color, "\n")

      # Store color in reactive value
      rv$current_color <- original_color

      # Update color picker to match (without triggering recolor)
      session$sendCustomMessage("icons-set-color", list(color = original_color))

      # Store original SVG
      rv$current_svg <- clean

      # Show preview with original color (pass color directly)
      render_preview(clean, color = original_color)

      # Set name
      updateTextInput(session, "display_name", value = gsub(":", "-", id))

      # Enable save
      shinyjs::enable(ns("btn_save"))

      # Go to tray
      session$sendCustomMessage("icons-set-step", list(
        rootId = ns("root"),
        step = "tray"
      ))
    }, ignoreInit = TRUE)
    
    # COLOR CHANGE
    observeEvent(input$color_hex, {
      # Update stored color
      rv$current_color <- input$color_hex
      if (!is.null(rv$current_svg) && nzchar(rv$current_svg)) {
        render_preview(rv$current_svg)
      }
    }, ignoreInit = TRUE)
    
    # SAVE TO LIBRARY
    observeEvent(input$btn_save, {

      # Check connection first
      if (is.null(conn)) {
        cat("ERROR: No database connection available\n")
        showNotification("Database connection not available. Cannot save icon.", type = "error", duration = 10)
        return()
      }

      if (is.null(rv$recolored_svg) || !nzchar(rv$recolored_svg)) {
        cat("ERROR: No SVG to save\n")
        showNotification("No icon loaded to save.", type = "error")
        return()
      }

      name <- trimws(f_or(input$display_name, "icon"))
      if (!nzchar(name)) name <- "icon"

      cat("Saving icon:", name, "\n")

      # Get current color from reactive value (not input$color_hex which might not be synced)
      color <- f_or(rv$current_color, "#2185d0")
      cat("Color:", color, "\n")

      payload <- tryCatch({
        cat("Building payload...\n")
        f_build_payload(icon_name = name, svg_txt = rv$recolored_svg, primary_color = color)
      }, error = function(e) {
        cat("ERROR building payload:", conditionMessage(e), "\n")
        showNotification(paste("Error building payload:", conditionMessage(e)), type = "error")
        NULL
      })

      if (is.null(payload)) {
        cat("Payload is NULL, aborting save\n")
        return()
      }

      cat("Payload built successfully, inserting into database...\n")

      success <- tryCatch({
        insert_icon(conn, payload)
        cat("Insert successful\n")
        TRUE
      }, error = function(e) {
        cat("ERROR inserting icon:", conditionMessage(e), "\n")
        showNotification(paste("Save failed:", conditionMessage(e)), type = "error", duration = 10)
        FALSE
      })

      if (success) {
        cat("Icon saved successfully!\n")
        showNotification("Icon saved!", type = "message")
        # Update top colors after saving
        top_colors(fetch_top_colors())
        # Refresh library to show new icon
        refresh_library()
        # Switch to library panel to make it visible
        session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "library"))

        # Signal global icon change to refresh other modules (e.g., container browser)
        new_version <- f_or(session$userData$icons_version, 0) + 1
        session$userData$icons_version <- new_version
        cat("[Icon Browser] Incremented icons_version to:", new_version, "\n")
      }
    }, ignoreInit = TRUE)

    # LIBRARY - Refresh function updates reactive value
    refresh_library <- function() {
      df <- tryCatch(fetch_icons(conn), error = function(e) {
        cat("ERROR fetching icons:", conditionMessage(e), "\n")
        NULL
      })
      library_data(df)
    }
    
    # Refresh library when Library tab is clicked
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

    # DELETE HANDLER - Single observer for all delete button clicks
    observeEvent(input$delete_clicked, {
      req(conn)
      icon_id <- input$delete_clicked

      # Check deletion safety using metadata-driven approach
      safety_check <- tryCatch({
        check_deletion_safety("Icons", icon_id)
      }, error = function(e) {
        cat("Error checking deletion safety for icon", icon_id, ":", conditionMessage(e), "\n")
        list(can_delete = FALSE, message_html = paste("Error checking references:", conditionMessage(e)))
      })

      if (!safety_check$can_delete) {
        # Icon is in use - show detailed warning with specific records
        showNotification(
          HTML(safety_check$message_html),
          type = "warning",
          duration = NULL  # Keep visible until dismissed
        )
        return()
      }

      # Safe to delete
      success <- tryCatch({
        delete_icon(conn, icon_id)
        TRUE
      }, error = function(e) {
        cat("Error deleting icon", icon_id, ":", conditionMessage(e), "\n")
        showNotification(paste("Delete failed:", conditionMessage(e)), type = "error")
        FALSE
      })

      if (success) {
        showNotification(sprintf("Deleted icon #%d", icon_id), type = "message")
        refresh_library()

        # Signal global icon change to refresh other modules (e.g., container browser)
        new_version <- f_or(session$userData$icons_version, 0) + 1
        session$userData$icons_version <- new_version
        cat("[Icon Browser] Incremented icons_version to:", new_version, "\n")
      }
    }, ignoreInit = TRUE)
  })
}