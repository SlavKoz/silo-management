# --- Dependencies (loaded once) ----------------------------------------------
rjsfGridDeps <- function() {
  shiny::singleton(
    shiny::tags$head(
      # No Bootstrap 5!
      
      # Small polyfill
      shiny::tags$script(shiny::HTML(
        "window.global = window;
         window.process = window.process || { env: { NODE_ENV: 'production' } };"
      )),
      
      # Try preferred path, then fallback (adjust if needed)
      # Place the file at one of:
      #   www/vendor/rjsf-grid.js  (preferred)
      #   www/rjsf-grid.js         (fallback)
      shiny::tags$script(src = "vendor/rjsf-grid.js"),
      shiny::tags$script(src = "rjsf-grid.js"),
      
      # Handlers + debug logs
      # inside rjsfGridDeps(), replace the existing "function render(cfg) { ... }" with:
      
      shiny::tags$script(shiny::HTML(
        "(function(){
     if (window.__rjsf_handlers_initialized) return;
     window.__rjsf_handlers_initialized = true;

     window.__rjsf_queue = window.__rjsf_queue || [];

     function debugLog(tag, obj){
       try { console.debug('[react-table]', tag, obj); } catch(e){}
     }

     function normalizeCfg(cfg){
       // If R sent df as JSON string, parse it to objects (rows)
       if (cfg && typeof cfg.data === 'string') {
         try { cfg.data = JSON.parse(cfg.data); } catch(e){ debugLog('data JSON parse failed', e); }
       }
       return cfg;
     }

     function render(cfg){
       cfg = normalizeCfg(cfg);
       debugLog('render called with', cfg);

       // Verify the mount target exists
       var el = cfg && cfg.elId ? document.getElementById(cfg.elId) : null;
       if (!el) {
         console.error('[react-table] mount target not found:', cfg && cfg.elId, 'existing roots:', document.querySelectorAll('.react-table-root'));
         // queue it for later (e.g., if UI not in DOM yet)
         window.__rjsf_queue.push(cfg);
         return;
       }


       // Call the bundle
       if (window.renderRJSFGrid) {
         try { window.renderRJSFGrid(cfg.elId, cfg); }
         catch(e){ console.error('renderRJSFGrid error:', e); }
       } else {
         window.__rjsf_queue.push(cfg);
         debugLog('queued (bundle not ready yet); queue size', window.__rjsf_queue.length);
       }
     }

     if (window.Shiny && window.Shiny.addCustomMessageHandler) {
       Shiny.addCustomMessageHandler('rjsf-grid-props', render);
       Shiny.addCustomMessageHandler('react-table-props', render);

       Shiny.addCustomMessageHandler('rjsf-grid-value', function(msg){
         if (window.Shiny && window.Shiny.setInputValue) {
           window.Shiny.setInputValue(msg.elId + '_value', msg.value, { priority: 'event' });
         }
       });
     }

     function flush(){
       if (!window.renderRJSFGrid) return;
       var q = window.__rjsf_queue; window.__rjsf_queue = [];
       debugLog('flushing queue items', q.length);
       q.forEach(render);
     }
     window.addEventListener('load', flush);
     document.addEventListener('readystatechange', flush);
   })();"
      ))
      
    )
  )
}


# (Kept) Legacy form UI helper (not used by react_table_* but harmless to keep)
rjsfGridUI <- function(id, compact=TRUE, divider=TRUE, label_cols=3L, class="card card-body") {
  ns <- NS(id); scope <- paste0("#", ns("root"))
  input_cols <- 12L - label_cols
  
  width_css <- sprintf("
    @media (min-width:576px){
      %s .row .col-sm-4{flex:0 0 auto;width:%d%% !important;}
      %s .row .col-sm-8{flex:0 0 auto;width:%d%% !important;}
    }", scope, round(label_cols/12*100), scope, round(input_cols/12*100))
  
  compact_css <- sprintf("
  %s .mb-2 { margin-bottom: .25rem !important; }
  %s fieldset { padding: .5rem !important; }
  %s details > summary { margin-bottom: .25rem; }

  /* EXCLUDE React-Select's inline input (.rs__input) from compact sizing */
  %s input[type='text']:not(.rs__input),
  %s input[type='search']:not(.rs__input),
  %s input[type='number'],
  %s select,
  %s textarea {
    padding: .25rem .5rem !important;
    height: 2rem !important;
    line-height: 1.25rem !important;
    border-radius: .25rem !important;
  }

  %s input[type='color'] {
    height: 2rem !important; width: 2.5rem !important; padding: 0 !important;
  }
", scope, scope, scope, scope, scope, scope, scope, scope, scope)
  
  divider_css <- sprintf("
    @media (min-width:768px){
      %s section > .row.g-3 > [class*='col-md-']:not(:first-child){
        border-left:1px solid #e5e7eb; padding-left:.75rem;
      }
      %s section > .row.g-3 { column-gap:0 !important; }
    }", scope, scope)
  
  align_css <- sprintf("
    %s .form-switch { padding-left:0 !important; }
    %s .form-switch .form-check-input { margin-left:0 !important; }
    %s .form-check:has(> input[type='checkbox']) { padding-left:0 !important; }
    %s .form-check-input[type='checkbox'] { margin-left:0 !important; margin-top:0 !important; }
  ", scope, scope, scope, scope)
  
  align_fallback_css <- sprintf("
    %s .form-switch { padding-left:0 !important; }
    %s .form-switch .form-check-input { margin-left:0 !important; }
  ", scope, scope)
  
  react_select_fix_css <- sprintf("
  /* React-Select (prefix='rs'): prevent first letters from being clipped */
  %s .rs__control{ min-height: 2rem !important; }
  %s .rs__value-container{ padding: 0 .5rem !important; }

  /* wrappers */
  %s .rs__input-container{ margin: 0 !important; padding: 0 !important; }
  %s .rs__input{ margin: 0 !important; padding: 0 !important; }

  /* the REAL text input (cover all variants we see in v5) */
  %s .rs__input,
  %s .rs__input input,
  %s .rs__control input.rs__input,
  %s .rs__control input[type='text'],
  %s .rs__control input[type='search']{
    padding: 0 0 0 4px !important;
    margin: 0 !important;
    height: auto !important;
    line-height: 1.2 !important;
    min-width: 2ch !important;
    text-indent: 0 !important;
    box-sizing: content-box !important;
  }
", scope, scope, scope, scope, scope, scope, scope, scope, scope)
  
  rules <- c(width_css)
  if (compact) rules <- c(rules, compact_css)
  if (divider) rules <- c(rules, divider_css)
  rules <- c(rules, align_css, align_fallback_css)
  rules <- c(rules, react_select_fix_css)
  
  tagList(
    rjsfGridDeps(),
    tags$style(HTML(paste(unique(rules), collapse = "\n"))),
    div(id = ns("root"), class = "react-table-root")
  )
}

# --- React Table: UI ----------------------------------------------------------
react_table_ui <- function(id, height = "60vh") {
  ns <- NS(id)
  tagList(
    rjsfGridDeps(),
    div(
      id = ns("root"),
      class = "react-table-root",
      style = paste0("min-height:", height, ";")
    )
  )
}

# --- React Table: Server ------------------------------------------------------
react_table_server <- function(id, columns, data_fn,
                               selection = c("none","single","multiple"),
                               key = NULL,
                               uiSchema = NULL,
                               extra = NULL) {
  selection <- match.arg(selection)
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    send_cfg <- function(df) {
      cfg <- list(
        elId      = ns("root"),
        columns   = columns,
        selection = selection,
        key       = key %||% (if (NROW(df)) colnames(df)[1] else NULL),
        data      = df
        #data      = jsonlite::toJSON(df, dataframe = "rows", na = "null", auto_unbox = TRUE)
      )
      if (!is.null(uiSchema)) cfg$uiSchema <- uiSchema
      if (!is.null(extra))    cfg <- utils::modifyList(cfg, extra, keep.null = TRUE)
      session$sendCustomMessage("react-table-props", cfg)
    }
    
    observe({
      df <- try(data_fn(), silent = TRUE)
      if (inherits(df, "try-error") || is.null(df)) df <- data.frame()
      send_cfg(df)
    })
  })
}


