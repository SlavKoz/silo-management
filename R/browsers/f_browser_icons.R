# R/browsers/f_browser_icons.R
# Icons browser — Semantic steps + short container, Enter-to-search, instant tray preview

f_browser_icons_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Equal width, compact height, typographic tuning for guidance
    f_scoped_css(ns("root"), c(
      # panel visibility
      ".steps-panel{display:none;}",
      ".steps-panel.active{display:block;}",
      
      # wrapper: no special centering here
      ".vstack-wrap{margin:.25rem 0;}",
      
      # the centered, fixed-width stack
      ".slim-vseg.ui.segments{width:33.333%; max-width:520px; min-width:340px; display:block;}",
      ".center-block{margin-left:auto!important; margin-right:auto!important;}",
      
      # compact rhythm
      ".slim-vseg.ui.segments>.segment{padding:.45rem .65rem!important;}",
      ".slim-vseg .seg-top .ui.fluid.icon.input.small>input{height:32px;}",
      ".slim-vseg .seg-or{padding:.25rem .45rem!important;}",
      ".slim-vseg .seg-or .ui.header.tiny,.slim-vseg .seg-or .ui.header.small{margin:.1rem 0; letter-spacing:.02em;}",
      ".slim-vseg .seg-bottom .ui.button.small{padding:.48rem .8rem;}",
      ".slim-vseg .seg-top input{ text-align:left; }",
      ".slim-vseg .seg-top input:placeholder-shown{ text-align:center; }",
      ".slim-vseg .seg-top input::placeholder{ opacity:.9; }",
      
      ".results-grid.ui.grid{margin-top:.25rem;}",
      ".results-grid .column{padding:.4rem!important;}",
      
      ".result-card{border:1px solid #e9ecef;border-radius:.5rem;padding:6px;text-align:center;}",
      ".result-card img{height:48px;width:48px;object-fit:contain;display:block;margin:0 auto 6px;}",
      ".result-card .label{font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin:2px 2px 6px;}",
      ".result-card .ui.button{font-size:.8rem;padding:.3rem .5rem;}",
      
      # Tray sizing & preview
      ".tray-grid{margin-top:.25rem; align-items:stretch;}",
      ".tray-grid .column{padding:.5rem!important;}",
      ".tray-seg{height:100%; min-height:220px; display:flex; align-items:center;}",
      ".tray-seg .ui.form{width:100%;}",
      ".tray-preview{justify-content:center;}",
      ".tray-preview svg{width:160px; height:160px; display:block; margin:auto;}",
      ".tray-preview img{width:160px; height:160px; display:block;}",
      
      paste0("#", ns("preview_target"),
             "{min-height:220px;border:2px dashed #bbb;background:#fafafa;display:flex;align-items:center;justify-content:center;}"),
      paste0("#", ns("preview_target"), " img, #", ns("preview_target"), " svg",
             "{width:160px;height:160px;display:block;}")
    )),
    
    div(id = ns("root"),
        
        # -------- Steps header --------
        div(class = "ui three steps",
            a(class = "active step", `data-step` = "search",
              tags$i(class = "search icon"),
              div(class = "content",
                  div(class="title","Search"),
                  div(class="description","Iconify or upload"))
            ),
            a(class = "step", `data-step` = "tray",
              tags$i(class = "inbox icon"),
              div(class = "content",
                  div(class="title","Tray"),
                  div(class="description","Preview & recolor"))
            ),
            a(class = "step", `data-step` = "library",
              tags$i(class = "book icon"),
              div(class = "content",
                  div(class="title","Library"),
                  div(class="description","Saved icons"))
            )
        ),
        
        # ===================== SEARCH PANEL =====================
        div(id = ns("panel-search"), class = "steps-panel active", `data-panel` = "search",
            
            # Centered, stacked segments: Search | OR | Upload (narrow ~33%)
            div(
              class = "vstack-wrap",
              div(class = "ui segments slim-vseg center-block",
                  # 1) SEARCH (top)
                  div(class = "ui segment seg-top",
                      div(class = "ui search", id = ns("sem_search"),
                          div(class = "ui fluid icon input small",
                              tags$input(
                                id = ns("q_prompt"),
                                class = "prompt",
                                type = "text",
                                placeholder = "Type a search term and press Enter"
                              ),
                              tags$i(class = "search icon")
                          ),
                          div(class = "results")
                      )
                  ),
                  # 2) OR (middle)
                  div(class = "ui center aligned secondary segment seg-or",
                      div(class = "ui header tiny", "OR")
                  ),
                  # 3) UPLOAD (bottom)
                  div(class = "ui segment seg-bottom",
                      div(style = "display:none;", fileInput(ns("svg_upload_search"), NULL, accept = ".svg")),
                      tags$button(
                        id = ns("btn_pick_svg"),
                        class = "black fluid ui labeled icon button small",
                        tags$i(class = "upload icon"),
                        "Upload SVG"
                      )
                  )
              )
            ),
            # Results grid under the stack
            div(class = "ui basic segment", uiOutput(ns("results_ui")))
        ),
        
        # ===================== TRAY PANEL =====================
        div(
          id = ns("panel-tray"), class = "steps-panel", `data-panel` = "tray",
          div(class = "ui two column stackable grid tray-grid",
              
              # LEFT: segment with name + color + save
              div(class = "column",
                  div(class = "ui segment tray-seg",
                      div(class = "ui form",
                          div(class = "field",
                              tags$label("Display name"),
                              textInput(ns("display_name"), NULL, placeholder = "Short name")
                          ),
                          div(class = "field",
                              tags$label("Color"),
                              tags$input(
                                id = ns("color_hex"),
                                type = "color",
                                value = "#2d89ef",
                                style = "width: 52px; height: 32px; padding: 0; border: none;"
                              )
                          ),
                          div(class = "field",
                              actionButton(ns("btn_save"), "Save to Library",
                                           class = "black fluid ui button")
                          ),
                          div(class = "fields two",
                              div(class = "field",
                                  checkboxInput(ns("debug_on"), "Show debug", value = FALSE)
                              ),
                              div(class = "field right aligned",
                                  actionButton(ns("btn_test_svg"), "Render test", class = "ui button")
                              )
                          )
                      )
                  )
              ),
              
              # RIGHT: segment with live preview + debug panel
              div(class = "column",
                  div(class = "ui segment tray-seg tray-preview",
                      div(id = ns("preview_target"))
                  ),
                  uiOutput(ns("tray_debug_ui"))
              )
          )
        ),
        
        # ===================== LIBRARY PANEL =====================
        div(id = ns("panel-library"), class = "steps-panel", `data-panel` = "library",
            div(class = "ui right aligned basic segment",
                actionButton(ns("btn_refresh"), "Refresh", class = "ui small button")
            ),
            div(id = ns("library_grid"), class = "ui-grid"),
            div(class = "ui divider"),
            actionButton(ns("btn_delete"), "Delete Selected", class = "ui button red")
        ),
        
        # ---- Module-local JS: preview handlers with ACK (FIXED sprintf: 2 args) ----
        tags$script(HTML(sprintf("
(function(rootId, ackId){
  if (window.__iconsPreviewHook_%s) return;
  window.__iconsPreviewHook_%s = true;

  function byId(id){ return document.getElementById(id); }
  function ack(payload){
    try { if (window.Shiny) Shiny.setInputValue(ackId, payload, {priority:'event'}); } catch(_){}
  }

  if (window.Shiny && Shiny.addCustomMessageHandler) {
    // PNG base64
    Shiny.addCustomMessageHandler('icons-preview-b64', function(msg){
      try {
        var el = byId(msg.targetId);
        if (!el) { ack({ok:false, reason:'no target', type:'b64'}); return; }
        var w = msg.w || 160, h = msg.h || 160;
        el.innerHTML = '<img alt=\"preview\" src=\"data:image/png;base64,' + (msg.b64||'') +
                       '\" width=\"'+w+'\" height=\"'+h+'\" style=\"display:block;margin:auto;\" />';
        ack({ok:true, type:'b64', len:(msg.b64||'').length});
      } catch(e) { ack({ok:false, type:'b64', reason: String(e)}); }
    });

    // RAW HTML (e.g., inline SVG)
    Shiny.addCustomMessageHandler('icons-preview-html', function(msg){
      try {
        var el = byId(msg.targetId);
        if (!el) { ack({ok:false, reason:'no target', type:'html'}); return; }
        el.innerHTML = msg.html || '<div class=\"ui red label\">(empty html)</div>';
        ack({ok:true, type:'html', len:(msg.html||'').length});
      } catch(e) { ack({ok:false, type:'html', reason: String(e)}); }
    });
  }
})('%s','%s');
", ns("root"), ns("root"),  # guard key
                                 ns("root"), ns("preview_ack")  # <-- ONLY TWO ARGS NOW
        ))),
        
        # ---- Steps + search prompt + upload trigger
        tags$script(HTML(sprintf("
(function(rootId, stepInput, promptId, btnSearchId, fileBtnId, fileInputId){
  var root = document.getElementById(rootId);
  if (!root) return;

  function activate(name){
    root.querySelectorAll('.ui.steps .step').forEach(function(el){
      el.classList.toggle('active', el.dataset.step === name);
    });
    root.querySelectorAll('.steps-panel').forEach(function(p){
      p.classList.toggle('active', (p.dataset.panel === name));
    });
    if (window.Shiny) Shiny.setInputValue(stepInput, name, {priority:'event'});
  }
  root._setStep = activate;

  // Step clicks
  root.addEventListener('click', function(e){
    var s = e.target.closest('.ui.steps .step');
    if (s && root.contains(s)) { e.preventDefault(); activate(s.dataset.step); }
  });

  // ENTER to search
  var prompt = document.getElementById(promptId);
  function doSearch() {
    if (!window.Shiny) return;
    var val = (prompt && prompt.value) ? prompt.value : '';
    Shiny.setInputValue(promptId + '_val', val, {priority:'event'});
    Shiny.setInputValue(promptId + '_enter', Date.now(), {priority:'event'});
  }
  if (prompt) {
    prompt.addEventListener('keydown', function(ev){
      if (ev.key === 'Enter') { ev.preventDefault(); doSearch(); }
    });
  }
  var b = document.getElementById(btnSearchId);
  if (b) b.addEventListener('click', function(ev){ ev.preventDefault(); doSearch(); });

  // Button -> hidden file input
  var pickBtn = document.getElementById(fileBtnId);
  var fileEl  = document.getElementById(fileInputId);
  if (pickBtn && fileEl) pickBtn.addEventListener('click', function(){ fileEl.click(); });

  // SERVER → UI: listen for 'icons-set-step'
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('icons-set-step', function(msg){
      var tgt = document.getElementById(msg.rootId || rootId);
      if (!tgt || !tgt._setStep) return;
      tgt._setStep(msg.step || 'search');
    });
  }

  // default
  activate('search');
})('%s','%s','%s','%s','%s','%s');
", ns("root"), ns("step"),
                                 ns("q_prompt"), ns("btn_do_search"),
                                 ns("btn_pick_svg"), ns("svg_upload_search")
        )))
    ),
    
    # Bind ENTER/magnifier and upload trigger via helper (must be inside tagList)
    f_icons_bind_search_upload(ns)
  )
}


# =========================== SERVER ===========================================
f_browser_icons_server <- function(id, pool = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    output$tray_debug_ui <- renderUI(NULL)
    outputOptions(output, "tray_debug_ui", suspendWhenHidden = FALSE)
    
    rv <- reactiveValues(
      last_svg_sanitized = NULL,
      last_svg_recolored = NULL,
      last_png_b64       = NULL
    )
    results     <- reactiveVal(character(0))
    upload_meta <- reactiveVal(list())
    
    # Resolve helper names (f_* or legacy)
    .getfun <- function(...) { nms <- c(...); for (n in nms) if (exists(n, mode="function", inherits=TRUE)) return(get(n, inherits=TRUE)); stop(sprintf("None of: %s", paste(nms, collapse=", "))) }
    iconify_search_all <- .getfun("f_iconify_search_all","iconify_search_all")
    fetch_iconify_svg  <- .getfun("f_fetch_iconify_svg","fetch_iconify_svg")
    sanitize_svg       <- .getfun("f_sanitize_svg","sanitize_svg")
    recolor_svg        <- .getfun("f_recolor_svg","recolor_svg")
    
    # Cleaners so <div> innerHTML renders reliably
    strip_xml_headers <- function(svg_txt) {
      x <- svg_txt
      x <- sub("^\\s*<\\?xml[^>]*>\\s*", "", x, perl = TRUE)
      x <- sub("^\\s*<!DOCTYPE[^>]*>\\s*", "", x, perl = TRUE)
      x
    }
    ensure_svg_xmlns <- function(svg_txt) {
      if (!nzchar(svg_txt)) return(svg_txt)
      if (!grepl("<svg", svg_txt, fixed = TRUE)) return(svg_txt)
      if (grepl("<svg[^>]*\\sxmlns=", svg_txt, perl = TRUE)) return(svg_txt)
      sub("<svg", "<svg xmlns=\"http://www.w3.org/2000/svg\"", svg_txt, perl = TRUE)
    }
    
    # ---- Preview: recolor → PNG b64 (if possible) else inline SVG — paint via JS ----
    render_preview <- function(svg_txt) {
      if (is.null(svg_txt) || !nzchar(svg_txt)) {
        session$sendCustomMessage("icons-preview-html", list(
          targetId = ns("preview_target"),
          html     = '<div class="ui red label">No SVG</div>'
        ))
        rv$last_png_b64 <- NULL
        rv$last_svg_recolored <- ""
        return(invisible())
      }
      # color
      col <- try(trimws(f_or(input$color_hex, "#2d89ef")), silent = TRUE)
      if (!is.character(col) || !nzchar(col)) col <- "#2d89ef"
      
      # recolor
      svg_col <- recolor_svg(svg_txt, col)
      if (!nzchar(svg_col)) svg_col <- svg_txt
      
      # Try PNG path
      b64 <- f_try({
        raw <- svg_to_png_raw(svg_col, size = 160)  # helper in utils/helper_icons.R
        raw_to_b64(raw)
      }, default = NULL)
      
      if (!is.null(b64) && nzchar(b64)) {
        rv$last_png_b64       <- b64
        rv$last_svg_recolored <- svg_col
        session$sendCustomMessage("icons-preview-b64", list(
          targetId = ns("preview_target"),
          b64      = b64,
          w        = 160,
          h        = 160
        ))
        return(invisible())
      }
      
      # Fallback to inline SVG (strip headers + ensure xmlns)
      svg_safe <- ensure_svg_xmlns(strip_xml_headers(svg_col))
      rv$last_png_b64       <- NULL
      rv$last_svg_recolored <- svg_safe
      session$sendCustomMessage("icons-preview-html", list(
        targetId = ns("preview_target"),
        html     = svg_safe
      ))
      invisible()
    }
    
    output$tray_debug_ui <- renderUI({
      if (!isTRUE(input$debug_on)) return(NULL)
      
      sv_san_len <- nchar(f_or(rv$last_svg_sanitized, ""))
      sv_rec_len <- nchar(f_or(rv$last_svg_recolored, ""))
      b64        <- f_or(rv$last_png_b64, "")
      b64_len    <- nchar(b64)
      
      tags$div(
        class = "ui segment",
        tags$div(class="ui tiny header", "Preview debug"),
        tags$div(class="ui list",
                 tags$div(class="item", sprintf("Sanitized SVG length: %s", sv_san_len)),
                 tags$div(class="item", sprintf("Recolored SVG length: %s", sv_rec_len)),
                 tags$div(class="item", sprintf("PNG base64 length: %s", b64_len))
        ),
        tags$div(class="field",
                 tags$label("PNG base64 (data URL payload)"),
                 tags$textarea(
                   style = "width:100%; height:120px;",
                   readonly = "readonly",
                   b64
                 )
        )
      )
    })
    
    observeEvent(input$preview_ack, {
      if (isTRUE(input$preview_ack$ok)) {
        showNotification(sprintf("Preview injected (%s, len %s).",
                                 f_or(input$preview_ack$type, "?"),
                                 f_or(input$preview_ack$len, 0)),
                         type = "message", duration = 3)
      } else {
        showNotification(sprintf("Preview injection failed: %s",
                                 f_or(input$preview_ack$reason, "unknown")),
                         type = "error", duration = 6)
      }
    }, ignoreInit = TRUE)
    
    # Test button: inline SVG into preview_target
    observeEvent(input$btn_test_svg, {
      showNotification("TEST: render-test clicked", type = "message", duration = 3)
      session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "tray"))
      
      # Inline SVG (red square)
      red_svg <- '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160"><rect x="0" y="0" width="160" height="160" fill="#ff1744"/></svg>'
      session$sendCustomMessage("icons-preview-html", list(
        targetId = ns("preview_target"),
        html     = red_svg
      ))
      
      rv$last_svg_sanitized <- red_svg
      rv$last_svg_recolored <- red_svg
      rv$last_png_b64       <- ""
      updateTextInput(session, "display_name", value = "test-inline-svg")
      updateCheckboxInput(session, "debug_on", value = TRUE)
    })
    
    # DB + state
    conn <- NULL; try(conn <- db_get_connection(), silent = TRUE)
    validate_conn <- reactive({ req(!is.null(conn)); conn })
    
    # Init: start with Save/Delete disabled
    session$onFlushed(function(){
      shinyjs::disable(ns("btn_save"));   shinyjs::addClass(ns("btn_save"), "disabled")
      shinyjs::disable(ns("btn_delete")); shinyjs::addClass(ns("btn_delete"), "disabled")
    }, once = TRUE)
    
    # ---------- ENTER-to-search ----------
    observeEvent(input[[paste0("q_prompt_enter")]], {
      q <- trimws(f_or(input[[paste0("q_prompt_val")]], ""))
      if (!nzchar(q)) { results(character(0)); return() }
      ids <- f_try(iconify_search_all(q, limit = 48), default = character(0))
      results(ids)
    }, ignoreInit = TRUE)
    
    # ---------- Upload: go Tray + preview + name ----------
    observeEvent(input$svg_upload_search, {
      up <- input$svg_upload_search
      req(!is.null(up$datapath))
      raw_svg <- paste(readLines(up$datapath, warn = FALSE), collapse = "\n")
      sv1 <- sanitize_svg(raw_svg); req(nzchar(sv1))
      
      rv$last_svg_sanitized <- sv1
      render_preview(sv1)  # immediate
      
      base <- gsub("\\.svg$", "", basename(f_or(up$name, "icon.svg")), ignore.case = TRUE)
      updateTextInput(session, "display_name", value = base)
      
      shinyjs::enable(ns("btn_save")); shinyjs::removeClass(ns("btn_save"), "disabled")
      session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "tray"))
    }, ignoreInit = TRUE)
    
    # ---------- Results grid ----------
    output$results_ui <- renderUI({
      ids <- results()
      if (!length(ids)) return(NULL)
      
      div(class = "ui doubling stackable grid results-grid",
          lapply(ids, function(id) {
            parts <- strsplit(id, ":", fixed = TRUE)[[1]]
            img_tag <- if (length(parts) == 2) {
              tags$img(src = sprintf("%s/%s/%s.svg?height=48", ICONIFY_BASE, parts[1], parts[2]))
            } else {
              div(class="text-muted", "(no preview)")
            }
            nsid <- gsub("[^A-Za-z0-9_]", "_", id)
            
            div(
              class = "two wide computer four wide tablet eight wide mobile column",
              div(class="result-card",
                  img_tag,
                  div(class="label", htmltools::htmlEscape(id)),
                  actionButton(
                    ns(paste0("load_", nsid)),
                    "Load to Tray",
                    class = "ui tiny black button fluid"
                  )
              )
            )
          })
      )
    })
    
    # ---------- Load to tray from a search tile ----------
    observe({
      ids <- results()
      lapply(ids, function(id) {
        nsid <- gsub("[^A-Za-z0-9_]", "_", id)
        observeEvent(input[[paste0("load_", nsid)]], {
          sv0 <- fetch_iconify_svg(id)
          if (!nzchar(sv0)) { showNotification("Could not fetch icon SVG.", type="error", duration=5); return() }
          sv1 <- sanitize_svg(sv0)
          if (!nzchar(sv1)) { showNotification("SVG sanitize failed.", type="error", duration=5); return() }
          
          rv$last_svg_sanitized <- sv1
          render_preview(sv1)
          
          disp <- gsub(":", "-", id, fixed = TRUE)
          updateTextInput(session, "display_name", value = disp)
          
          shinyjs::enable(ns("btn_save")); shinyjs::removeClass(ns("btn_save"), "disabled")
          session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "tray"))
        }, ignoreInit = TRUE, once = TRUE)
      })
    })
    
    # ---------- Tray actions ----------
    observeEvent(input$color_hex, {
      if (!is.null(rv$last_svg_sanitized) && nzchar(rv$last_svg_sanitized)) {
        render_preview(rv$last_svg_sanitized)
      }
    }, ignoreInit = TRUE)
    
    observeEvent(input$btn_save, {
      conn <- validate_conn(); req(rv$last_svg_recolored)
      disp <- trimws(f_or(input$display_name, "icon"))
      payload <- f_build_payload(icon_name = disp, svg_txt = rv$last_svg_recolored)
      insert_icon(conn, payload)
      icons_refresh_library(conn, session)
      shinyjs::disable(ns("btn_delete")); shinyjs::addClass(ns("btn_delete"), "disabled")
      session$sendCustomMessage("icons-set-step", list(rootId = ns("root"), step = "library"))
    }, ignoreInit = TRUE)
    
    # ---------- Library ----------
    icons_refresh_library <- function(conn, session) {
      df <- f_try(fetch_icons(conn), default = NULL)
      if (is.null(df) || !nrow(df)) { session$sendCustomMessage("icons-browser.renderLibrary", list(rows = list())); return(invisible()) }
      rows <- lapply(seq_len(nrow(df)), function(i) {
        list(
          id    = df$id[i],
          label = sprintf("%d — %s", df$id[i], df$icon_name[i]),
          img   = if (isTRUE(nzchar(df$png_32_b64[i]))) paste0("data:image/png;base64,", df$png_32_b64[i]) else NULL
        )
      })
      session$sendCustomMessage("icons-browser.renderLibrary", list(rows = rows))
    }
    
    observeEvent(input$btn_refresh, {
      conn <- validate_conn()
      icons_refresh_library(conn, session)
    }, ignoreInit = TRUE)
    
    observeEvent(input$lib_selected_ids, {
      has <- length(input$lib_selected_ids) > 0
      if (has) { shinyjs::enable(ns("btn_delete")); shinyjs::removeClass(ns("btn_delete"), "disabled") }
      else     { shinyjs::disable(ns("btn_delete")); shinyjs::addClass(ns("btn_delete"), "disabled") }
    }, ignoreInit = TRUE)
    
    observeEvent(input$btn_delete, {
      conn <- validate_conn()
      ids <- as.integer(f_or(input$lib_selected_ids, integer()))
      if (!length(ids)) return()
      for (id in ids) {
        if (isTRUE(icon_is_used_somewhere(conn, id))) next
        delete_icon(conn, id)
      }
      shinyjs::disable(ns("btn_delete")); shinyjs::addClass(ns("btn_delete"), "disabled")
      icons_refresh_library(conn, session)
    }, ignoreInit = TRUE)
  })
}
