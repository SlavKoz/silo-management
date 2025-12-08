# R/f_app_ui.R — Semantic UI with collapsible sidebar groups

f_app_ui <- function() {
  shiny.semantic::semanticPage(
    shinyjs::useShinyjs(),
    
    tags$head(
      tags$link(rel = "stylesheet", href = "css/admin.css?v=20251021"),
      tags$link(rel = "stylesheet", href = "css/silo-canvas.css?v=20251021"),
      tags$link(rel = "stylesheet", href = "css/admin-grid.css"),
      tags$link(rel = "stylesheet", href = "css/f_siloplacements.css"),
      tags$script(src = "js/icon-browser.js"),
      tags$script(src = "js/admin-grid.js"),
      tags$script(src = "js/f_siloplacements_canvas.js"),
      tags$style(HTML("
  :root { --sbw: 240px; --sbw-collapsed: 56px; }
  body { --sbw-current: var(--sbw); }
  body.sb-collapsed { --sbw-current: var(--sbw-collapsed); }

  /* Sidebar (fixed) */
  .sb-rail {
    position: fixed; top:0; bottom:0; left:0; width: var(--sbw-current);
    background:#1b1c1d; color:#fff; overflow:hidden; transition: width .2s ease; z-index:1000; padding-top:.5rem;
  }
  .sb-content { margin-left: calc(var(--sbw-current) + 1rem); transition: margin-left .2s ease; padding:1rem 1rem 2rem; }

  /* App title/header */
  .sb-title {
    margin: 0 .5rem .25rem .5rem;
    padding: .65rem .75rem;
    color:#fff; font-weight:600; background: rgba(255,255,255,0.06);
    border-radius:.4rem;
  }

  /* Scrollable menu area (leave space for Collapse) */
  .sb-menu-scroll {
    position: relative;
    height: calc(100% - 3.75rem);
    overflow: auto;
    padding: 0 .5rem;
    padding-bottom: 3.25rem;
  }

  /* Collapse button pinned at the bottom */
  .sb-rail .menu-bottom { position: absolute; left: .5rem; right: .5rem; bottom: .5rem; }
  .sb-rail .menu-bottom .item { background: rgba(255,255,255,0.06); border-radius:.4rem; }

  /* Menu look & feel */
  .sb-rail .ui.vertical.menu { background: transparent; border:none; box-shadow:none; margin:0; }
  .sb-rail .item { color:#fff !important; border-radius:.4rem; display:flex; align-items:center; cursor:pointer; padding:.65rem .75rem; position: relative; }
  .sb-rail .item .item-label { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .sb-rail .item.nav-active { background: rgba(255,255,255,0.10); }
  .sb-rail .item .icon { min-width: 24px; text-align:center; margin-right: .65rem; opacity:.9; }

  /* Subitem indent (a bit bigger) */
  .sb-rail .subitem { padding-left: 2.25rem !important; }

  /* Group headers: visually distinct (no arrows/caret) */
  .sb-rail .group-header {
    display:flex; align-items:center; flex-wrap:nowrap; gap:.5rem;
    font-weight:600;
    background: linear-gradient(90deg, rgba(255,255,255,0.10), rgba(255,255,255,0.06));
    border: 1px solid rgba(255,255,255,0.12);
    border-left: 3px solid #3b82f6;
    border-radius: .45rem;
    padding: .55rem .65rem;
    margin: .35rem 0 .15rem 0;
  }
  .sb-rail .group-header .group-caret { display: none !important; } /* remove caret entirely */
  .group-children { padding-top:.25rem; }
  .collapsed .group-children { display:none; }

  /* -------- Collapsed behaviour -------- */
  /* Items: icons only when collapsed */
  body.sb-collapsed .sb-rail .item { justify-content:center; }
  body.sb-collapsed .sb-rail .item .icon { margin-right:0; }
  body.sb-collapsed .sb-rail .item .item-label { display:none; }

  /* Group headers in collapsed: icon-only, still visually distinct */
  body.sb-collapsed .sb-rail .group-header {
    gap:0; padding:.5rem; justify-content:center;
  }
  body.sb-collapsed .sb-rail .group-header .icon { margin-right:0; }
  body.sb-collapsed .sb-rail .subitem { padding-left:.85rem !important; } /* slightly larger than before */
  body.sb-collapsed .sb-rail .group-children .item { justify-content:center; }

  /* Page header */
  .pane-header { background:#0d6efd; color:#fff; padding:.75rem 1rem; border-radius:.5rem; display:flex; align-items:center; justify-content:space-between; margin:.5rem 0 1rem; }
  .pane-title { margin:0; font-weight:600; font-size:1.15rem; }

  /* Search palette dropdown menu items */
  #global_search_category + .menu { font-size: 11px !important; }
  #global_search_category + .menu .item { font-size: 11px !important; padding: 0.5rem 0.8rem !important; }

  /* ======================
     Tooltips (collapsed)
     ====================== */
  .sb-rail .item[data-tip]:hover::after {
  content: attr(data-tip);
  position: fixed;             /* stick to viewport edge */
  left: calc(var(--sbw-current) + 6px);
  top: calc(var(--mouse-y, 0px));  /* updated by JS */
  transform: translateY(-50%);
  background: rgba(0,0,0,0.85);
  color: #fff;
  padding: .35rem .6rem;
  border-radius: .4rem;
  font-size: .8rem;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  animation: tooltipFade .15s forwards;
  z-index: 9999;
}
@keyframes tooltipFade { 
  from { opacity:0; transform: translateY(-50%) scale(0.98); } 
  to   { opacity:1; transform: translateY(-50%) scale(1); } 
}
/* Show tooltips only when collapsed (hide when expanded) */
body:not(.sb-collapsed) .sb-rail .item[data-tip]:hover::after {
  display: none;
}
"))

    ),
    
    # ------ Sidebar rail ------
    # ------ Sidebar rail ------
    div(class = "sb-rail",
        # app title/header (fixed) - no home button
        div(class = "sb-title", "Silo"),

        # scrollable menu area (server-built groups/items)
        div(class = "sb-menu-scroll",
            uiOutput("f_sidebar_menu")
        ),
        
        # Bottom collapse toggle (absolute pinned)
        div(class = "menu-bottom",
            a(id = "sb-collapse-toggle", class = "item", href = "javascript:void(0);",
              tags$i(id = "sb-collapse-icon", class = "angle double left icon"),
              span(class = "item-label", id = "sb-collapse-label", "Collapse")
            )
        )
    )
    ,
    
    # ------ Main content ------
    div(class = "sb-content",
        div(class = "pane-header",
            h4(class = "pane-title", textOutput("f_page_title", inline = TRUE)),
            div(class = "header-actions",
                div(class = "ui mini action input", style = "width: 280px;",
                    tags$input(type = "text",
                              placeholder = "Search...",
                              id = "global_search_input",
                              list = "search_suggestions",
                              autocomplete = "off",
                              style = "font-size: 11px; padding: 0.4rem 0.6rem;"),
                    uiOutput("search_datalist"),
                    tags$select(class = "ui compact selection dropdown",
                                id = "global_search_category",
                                style = "font-size: 11px; min-height: 1.8rem;",
                        tags$option(value = "forms", selected = "selected", "Forms"),
                        tags$option(value = "containers", "Containers"),
                        tags$option(value = "shapes", "Shapes"),
                        tags$option(value = "siloes", "Siloes"),
                        tags$option(value = "sites", "Sites"),
                        tags$option(value = "areas", "Areas"),
                        tags$option(value = "operations", "Operations"),
                        tags$option(value = "layouts", "Layouts")
                    ),
                    div(class = "ui mini icon button", id = "global_search_btn",
                        style = "font-size: 11px; padding: 0.4rem 0.6rem;",
                        tags$i(class = "search icon", style = "font-size: 11px;")
                    )
                )
            )
        ),
        uiOutput("f_route_outlet")
    ),
    
    # ------ Router + collapse + collapsible groups ------
    tags$script(HTML("
      (function(){
        // Initialize Fomantic UI dropdown for search category
        $(document).ready(function(){
          $('#global_search_category').dropdown({
            onChange: function(value, text, $selectedItem) {
              // Clear search input when category changes
              $('#global_search_input').val('').css('color', '');
            }
          });

          // Handle Enter key in search input
          $('#global_search_input').on('keypress', function(e){
            if (e.which === 13) { // Enter key
              e.preventDefault();
              $('#global_search_btn').click();
            }
          });

          // Check for matching suggestions and turn red if none found
          $('#global_search_input').on('input', function(){
            var inputVal = $(this).val().toLowerCase();
            if (!inputVal) {
              $(this).css('color', '');
              return;
            }

            // Get datalist options
            var datalist = $('#search_suggestions');
            if (!datalist.length) {
              $(this).css('color', '');
              return;
            }

            // Check if any option matches
            var hasMatch = false;
            datalist.find('option').each(function(){
              var optionVal = $(this).val().toLowerCase();
              if (optionVal.indexOf(inputVal) !== -1) {
                hasMatch = true;
                return false; // break
              }
            });

            // Set color based on match
            if (hasMatch) {
              $(this).css('color', '');
            } else {
              $(this).css('color', '#db2828'); // Semantic UI red
            }
          });
        });

        // Custom message handler for setting hash from server
        $(document).on('shiny:connected', function() {
          Shiny.addCustomMessageHandler('set-hash', function(msg){
            if (msg && msg.h && location.hash !== msg.h) location.hash = msg.h;
          });
        });

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
        function normRoute(h){ return (h && h.startsWith('#/')) ? h : '#/home'; }   // default to Home
        function setActiveRoute(h){
          // highlight the item whose data-route equals h
          var items = document.querySelectorAll('.sb-rail .item[data-route]');
          items.forEach(function(it){ it.classList.toggle('nav-active', it.getAttribute('data-route') === h); });
          // auto-expand the group containing the active item
          var active = document.querySelector('.sb-rail .item[data-route=\"' + h + '\"]');
          if (active) {
            var group = active.closest('.group-block');
            if (group) group.classList.remove('collapsed');
          }
        }
        function syncRoute(){
          var h = normRoute(location.hash);
          setActiveRoute(h);
          if (window.Shiny && typeof window.Shiny.setInputValue === 'function') {
            Shiny.setInputValue('f_route', h, {priority:'event'});
          }
        }

        function syncRouteWhenReady(){
          if (!(window.Shiny && typeof window.Shiny.setInputValue === 'function')) return false;
          syncRoute();
          return true;
        }
        // click on menu items updates hash
        document.addEventListener('click', function(e){
          var it = e.target.closest('.sb-rail .item[data-route]');
          if (!it) return;
          var h = it.getAttribute('data-route') || '#/home';
          if (location.hash !== h) location.hash = h; else syncRoute();
        });

        // collapsible groups toggle
        document.addEventListener('click', function(e){
          var gh = e.target.closest('.group-header');
          if (!gh) return;
          var block = gh.closest('.group-block');
          if (!block) return;
          block.classList.toggle('collapsed');
        });
        
        document.addEventListener('mousemove', function(e){
          document.documentElement.style.setProperty('--mouse-y', e.clientY + 'px');
        }, {passive:true});

        window.addEventListener('hashchange', syncRoute);
document.addEventListener('DOMContentLoaded', function(){
  // start with ALL groups collapsed
  document.querySelectorAll('.group-block').forEach(function(b){ b.classList.add('collapsed'); });
  // then sync route; setActiveRoute() will auto-expand the active group
  var h = (location.hash && location.hash.startsWith('#/')) ? location.hash : '#/home';
  // highlight + expand containing group
  var items = document.querySelectorAll('.sb-rail .item[data-route]');
  items.forEach(function(it){ it.classList.toggle('nav-active', it.getAttribute('data-route') === h); });
  var active = document.querySelector('.sb-rail .item[data-route=\"' + h + '\"]');
  if (active) { var group = active.closest('.group-block'); if (group) group.classList.remove('collapsed'); }
  if (!syncRouteWhenReady()) {
    var routeInitTimer = setInterval(function(){
      if (syncRouteWhenReady()) {
        clearInterval(routeInitTimer);
      }
    }, 100);

    // also catch the moment Shiny connects (happens after DOMContentLoaded)
    document.addEventListener('shiny:connected', function(){ syncRouteWhenReady(); }, { once: true });
  }
});

      })();
    "))
  )
}
