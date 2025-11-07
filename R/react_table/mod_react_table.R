# --- Dependencies (loaded once) ----------------------------------------------
rjsfGridDeps <- function() {
  shiny::singleton(
    shiny::tags$head(
      # Bootstrap 5 from CDN (OK per user's request)
      shiny::tags$link(rel = "stylesheet",
                       href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"),

      # Small polyfill
      shiny::tags$script(shiny::HTML(
        "window.global = window; window.process = window.process || { env: { NODE_ENV: 'production' } };"
      )),

      # RJSF Grid bundle (local)
      shiny::tags$script(src = "vendor/rjsf-grid.js"),

      # Debug: Log the script path
      shiny::tags$script(shiny::HTML(
        "console.log('[rjsf] Looking for JS at path:', document.currentScript?.previousElementSibling?.src || 'unknown');"
      )),

      # Handlers (simplified, working version from TestReact)
      shiny::tags$script(shiny::HTML(
        "(function(){
           console.log('[rjsf] Initializing handlers...');
           console.log('[rjsf] window.renderRJSFGrid exists?', typeof window.renderRJSFGrid);

           if (window.__rjsf_handlers_initialized) {
             console.log('[rjsf] Handlers already initialized');
             return;
           }
           window.__rjsf_handlers_initialized = true;

           window.__rjsf_queue = window.__rjsf_queue || [];

           if (window.Shiny && window.Shiny.addCustomMessageHandler) {
             Shiny.addCustomMessageHandler('rjsf-grid-props', function(cfg){
               console.log('[rjsf-grid-props]', cfg);
               console.log('[rjsf] window.renderRJSFGrid?', typeof window.renderRJSFGrid);
               if (window.renderRJSFGrid) {
                 console.log('[rjsf] Calling renderRJSFGrid...');
                 window.renderRJSFGrid(cfg.elId, cfg);
               } else {
                 console.warn('[rjsf] renderRJSFGrid not available, queueing');
                 window.__rjsf_queue.push(cfg);
               }
             });

             Shiny.addCustomMessageHandler('react-table-props', function(cfg){
               console.log('[react-table-props]', cfg);
               if (window.renderRJSFGrid) {
                 window.renderRJSFGrid(cfg.elId, cfg);
               } else {
                 console.warn('[rjsf] renderRJSFGrid not available, queueing');
                 window.__rjsf_queue.push(cfg);
               }
             });

             Shiny.addCustomMessageHandler('rjsf-grid-value', function(msg){
               if (window.Shiny && window.Shiny.setInputValue) {
                 window.Shiny.setInputValue(msg.elId + '_value', msg.value, { priority: 'event' });
               }
             });

             console.log('[rjsf] Message handlers registered');
           }

           function flush(){
             console.log('[rjsf] Flush called, renderRJSFGrid?', typeof window.renderRJSFGrid);
             if (!window.renderRJSFGrid) {
               console.warn('[rjsf] Cannot flush - renderRJSFGrid not loaded');
               return;
             }
             var q = window.__rjsf_queue; window.__rjsf_queue = [];
             console.log('[rjsf] Flushing', q.length, 'queued items');
             q.forEach(function(cfg){ window.renderRJSFGrid(cfg.elId, cfg); });
           }

           window.addEventListener('load', flush);
           document.addEventListener('readystatechange', flush);

           // Try flushing after a delay to catch late loads
           setTimeout(flush, 1000);
           setTimeout(flush, 2000);
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

# --- React Table: UI (simplified, working version) ---------------------------
react_table_ui <- function(id, height = "60vh", compact = TRUE, divider = FALSE, label_cols = 3L) {
  ns <- NS(id)
  scope <- paste0("#", ns("root"))
  input_cols <- 12L - label_cols

  # Compact CSS
  compact_css <- if (compact) {
    sprintf("
      %s .mb-2 { margin-bottom: .25rem !important; }
      %s fieldset { padding: .5rem !important; }
      %s details > summary { margin-bottom: .25rem; }

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
  } else ""

  # Divider CSS
  divider_css <- if (divider) {
    sprintf("
      @media (min-width:768px){
        %s section > .row.g-3 > [class*='col-md-']:not(:first-child){
          border-left:1px solid #e5e7eb; padding-left:.75rem;
        }
        %s section > .row.g-3 { column-gap:0 !important; }
      }
    ", scope, scope)
  } else ""

  tagList(
    rjsfGridDeps(),
    tags$style(HTML(paste(compact_css, divider_css, collapse = "\n"))),
    div(
      id = ns("root"),
      class = "card card-body",
      style = paste0("min-height:", height, ";")
    )
  )
}

# --- RJSF Grid Server (for forms with schema) --------------------------------
rjsfGridServer <- function(id, schema, uiSchema = NULL, formData = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    elId <- session$ns("root")

    # Initial render when client is ready
    session$onFlushed(function() {
      cat("[rjsfGridServer] Sending initial config to", elId, "\n")
      session$sendCustomMessage("rjsf-grid-props", list(
        elId     = elId,
        schema   = schema,
        uiSchema = uiSchema,
        formData = formData
      ))
      # Sync the initial value so value() matches the UI
      session$sendCustomMessage("rjsf-grid-value", list(
        elId = elId, value = f_or(formData, list())
      ))
    }, once = TRUE)

    value <- shiny::reactive({ input$root_value })

    # set() updates form data
    set <- function(v, sync_input = TRUE) {
      session$sendCustomMessage("rjsf-grid-props", list(
        elId     = elId,
        schema   = schema,
        uiSchema = uiSchema,
        formData = v
      ))
      if (isTRUE(sync_input)) {
        session$sendCustomMessage("rjsf-grid-value", list(elId = elId, value = v))
      }
    }

    list(value = value, set = set)
  })
}

# --- React Table: Server (for data tables) -----------------------------------
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
        key       = f_or(key, if (NROW(df)) colnames(df)[1] else NULL),
        data      = df
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


