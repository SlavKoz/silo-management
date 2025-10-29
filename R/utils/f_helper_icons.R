# f_-layer for icons helpers.
# Initially just delegates to legacy helpers in helper_icons.R
# If we need to change behavior later, we’ll do it here.

# Search
f_iconify_search_all <- function(query, limit = 24, page_size = 200, max_results = 5000) {
  # if your legacy helper already supports (query, limit), just delegate:
  iconify_search_all(query, limit = limit)
}

# Fetch SVG
f_fetch_iconify_svg <- function(id_or_prefix, name = NULL) {
  fetch_iconify_svg(id_or_prefix, name)
}

# Sanitize / recolor / rasterize
f_sanitize_svg   <- function(svg_txt)                  sanitize_svg(svg_txt)
f_recolor_svg    <- function(svg_txt, color_hex)       recolor_svg(svg_txt, color_hex)
f_svg_to_png_raw <- function(svg_txt, size = 64)       svg_to_png_raw(svg_txt, size)

# Build DB payload
f_build_payload  <- function(icon_name, svg_txt)       build_payload(icon_name, svg_txt)

# f_icons_bind_search_upload() — wire ENTER search, magnifier click, and upload trigger
# ns: the module NS() function (pass `ns` from inside your UI)
f_icons_bind_search_upload <- function(ns) {
  rid  <- ns("root")
  qid  <- ns("q_prompt")
  sid  <- ns("sem_search")
  bid  <- ns("btn_pick_svg")
  fid  <- ns("svg_upload_search")
  cid  <- ns("color_hex")   # <- new
  
  tags$script(HTML(paste0(
    "(function(rid,qid,sid,bid,fid,cid){",
    "  var root = document.getElementById(rid); if(!root) return;",
    "  var prompt = document.getElementById(qid);",
    "  function doSearch(){",
    "    if(!window.Shiny) return;",
    "    var val = (prompt && prompt.value) ? prompt.value : '';",
    "    Shiny.setInputValue(qid + '_val', val, {priority:'event'});",
    "    Shiny.setInputValue(qid + '_enter', Date.now(), {priority:'event'});",
    "  }",
    "  if(prompt){",
    "    prompt.addEventListener('keydown', function(ev){ if(ev.key==='Enter'){ ev.preventDefault(); doSearch(); } });",
    "  }",
    "  var sem = document.getElementById(sid);",
    "  if(sem){",
    "    sem.addEventListener('click', function(ev){",
    "      var ico = ev.target.closest('.ui.icon.input .search.icon');",
    "      if(ico){ ev.preventDefault(); doSearch(); }",
    "    });",
    "  }",
    "  var pickBtn = document.getElementById(bid);",
    "  var fileEl  = document.getElementById(fid);",
    "  if(pickBtn && fileEl){ pickBtn.addEventListener('click', function(){ fileEl.click(); }); }",
    "  // bind color input (native <input type=color>) -> input$color_hex",
    "  var col = document.getElementById(cid);",
    "  if(col){",
    "    var push = function(){ if(window.Shiny) Shiny.setInputValue(cid, col.value, {priority:'event'}); };",
    "    col.addEventListener('input', push);",
    "    col.addEventListener('change', push);",
    "  }",
    "})('", rid, "','", qid, "','", sid, "','", bid, "','", fid, "','", cid, "');"
  )))
}


