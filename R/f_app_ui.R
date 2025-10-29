# R/f_app_ui.R — Semantic/Fomantic UI with hash router (/#/icons, /#/containers, ...)

f_app_ui <- function() {
  shiny.semantic::semanticPage(
    shinyjs::useShinyjs(),
    
    tags$head(
      # Core styles (Fomantic + your overrides)
      tags$link(rel = "stylesheet", href = "css/admin.css?v=20251021"),
      tags$link(rel = "stylesheet", href = "css/silo-canvas.css?v=20251021"),
      tags$link(rel = "stylesheet", href = "css/admin-grid.css"),
      tags$script(src = "js/icon-browser.js"),
      tags$script(src = "js/admin-grid.js"),
      tags$script(HTML("
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    Shiny.addCustomMessageHandler('icons-set-step', function(msg){
      var root = document.getElementById(msg.rootId);
      if (!root || !root._setStep) return;
      root._setStep(msg.step || 'search');
    });
  }
")),
      tags$style(HTML("
        :root { --sbw: 240px; --sbw-collapsed: 56px; }
        body { --sbw-current: var(--sbw); }
        body.sb-collapsed { --sbw-current: var(--sbw-collapsed); }

        .sb-rail {
          position: fixed; top: 0; bottom: 0; left: 0;
          width: var(--sbw-current); background: #1b1c1d; color: #fff;
          overflow: hidden; transition: width .2s ease; z-index: 1000; padding-top: .5rem;
        }
        .sb-content {
          margin-left: calc(var(--sbw-current) + 1rem);
          transition: margin-left .2s ease; padding: 1rem 1rem 2rem;
        }
        .sb-rail .ui.vertical.menu { background: transparent; border: none; box-shadow: none; margin: 0 .5rem; }
        .sb-rail .item { color: #fff !important; border-radius: .4rem; display:flex; align-items:center; cursor:pointer; }
        .sb-rail .item .icon { min-width: 24px; text-align:center; margin-right: .75rem; opacity:.9; }
        .sb-rail .item .item-label { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        body.sb-collapsed .sb-rail .item { justify-content:center; }
        body.sb-collapsed .sb-rail .item .item-label { display:none; }
        .sb-rail .menu-bottom { position:absolute; left:.5rem; right:.5rem; bottom:.5rem; }
        .sb-rail .menu-bottom .item { background: rgba(255,255,255,0.06); border-radius:.4rem; }

        .pane-header {
          background:#0d6efd; color:#fff; padding:.75rem 1rem; border-radius:.5rem;
          display:flex; align-items:center; justify-content:space-between; margin:.5rem 0 1rem;
        }
        .pane-title { margin:0; font-weight:600; font-size:1.15rem; }
        .nav-active { background: rgba(255,255,255,0.08) !important; }
      "))
    ),
    
    # -------- Sidebar rail --------
    div(class = "sb-rail",
        div(class = "ui vertical inverted menu fluid",
            div(class = "item header", "Silo"),
            
            # Note: data-route attributes drive router
            a(class = "item", `data-route` = "#/icons",
              tags$i(class = "icons icon"),     span(class = "item-label", "Icons")),
            a(class = "item", `data-route` = "#/containers",
              tags$i(class = "boxes icon"),     span(class = "item-label", "Containers")),
            a(class = "item", `data-route` = "#/silos",
              tags$i(class = "warehouse icon"), span(class = "item-label", "Silos")),
            a(class = "item", `data-route` = "#/placements",
              tags$i(class = "map marker alternate icon"), span(class = "item-label", "Placements")),
            a(class = "item", `data-route` = "#/canvas",
              tags$i(class = "project diagram icon"),      span(class = "item-label", "Canvas")),
            
            # Bottom collapse toggle
            div(class = "menu-bottom",
                a(id = "sb-collapse-toggle", class = "item", href = "javascript:void(0);",
                  tags$i(id = "sb-collapse-icon", class = "angle double left icon"),
                  span(class = "item-label", id = "sb-collapse-label", "Collapse")
                )
            )
        )
    ),
    
    # -------- Main content --------
    div(class = "sb-content",
        div(class = "pane-header",
            h4(class = "pane-title", textOutput("f_page_title", inline = TRUE)),
            div(class = "header-actions",
                tags$div(class="ui tiny basic inverted label", "Router mode")
            )
        ),
        
        # Route outlet (server renders active module UI here)
        uiOutput("f_route_outlet")
    ),
    
    # -------- Router + collapse behavior --------
    tags$script(HTML("
      (function(){
        // collapse control
        function syncCollapse(){
          var collapsed = document.body.classList.contains('sb-collapsed');
          var icon = document.getElementById('sb-collapse-icon');
          var label = document.getElementById('sb-collapse-label');
          if (!icon || !label) return;
          icon.className = collapsed ? 'angle double right icon' : 'angle double left icon';
          label.textContent = collapsed ? 'Expand' : 'Collapse';
        }
        document.addEventListener('click', function(e){
          var a = e.target.closest('#sb-collapse-toggle');
          if (!a) return;
          e.preventDefault(); document.body.classList.toggle('sb-collapsed'); syncCollapse();
        });
        document.addEventListener('DOMContentLoaded', syncCollapse);

        // simple hash router
        function normRoute(h){ return h && h.startsWith('#/') ? h : '#/icons'; }
        function setActiveRoute(h){
          var items = document.querySelectorAll('.sb-rail .item[data-route]');
          items.forEach(function(it){ it.classList.toggle('nav-active', it.getAttribute('data-route') === h); });
        }
        function syncRoute(){
          var h = normRoute(location.hash);
          setActiveRoute(h);
          if (window.Shiny) Shiny.setInputValue('f_route', h, {priority:'event'});
        }
        // click on menu items updates hash (and triggers sync)
        document.addEventListener('click', function(e){
          var it = e.target.closest('.sb-rail .item[data-route]');
          if (!it) return;
          var h = it.getAttribute('data-route') || '#/icons';
          if (location.hash !== h) location.hash = h; else syncRoute(); // also handle same-route click
        });

        window.addEventListener('hashchange', syncRoute);
        document.addEventListener('DOMContentLoaded', syncRoute);
      })();
    "))
  )
}
