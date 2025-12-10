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

  /* Search bar components */
  #global_search_category { font-size: 11px !important; min-height: 1.8rem !important; min-width: 140px !important; }
  #global_search_category + .menu { font-size: 11px !important; }
  #global_search_category + .menu .item { font-size: 11px !important; padding: 0.5rem 0.8rem !important; }

  /* Search results dropdown - grouped categories */
  #global_search_input {
    font-size: 11px !important;
    min-height: 1.8rem !important;
    width: 250px !important;
    min-width: 250px !important;
    max-width: 250px !important;
  }
  #global_search_input .text {
    font-size: 11px !important;
    white-space: nowrap !important;
    overflow: hidden !important;
    text-overflow: ellipsis !important;
  }
  #global_search_input .menu { font-size: 11px !important; max-height: 400px; overflow-y: auto; }
  #global_search_input .menu .item { font-size: 11px !important; padding: 0.5rem 0.8rem !important; }

  /* Grouped search results styling */
  #global_search_input .menu .category {
    margin: 0;
  }
  #global_search_input .menu .category > .name {
    font-weight: 700;
    color: #2185d0;
    background: #f8f9fa;
    padding: 6px 12px;
    font-size: 11px !important;
    border-bottom: 1px solid #e0e0e0;
  }
  #global_search_input .menu .category .results {
    padding: 0;
  }
  #global_search_input .menu .category .result {
    font-size: 11px !important;
    padding: 0.5rem 0.8rem !important;
    cursor: pointer;
    transition: background 0.1s ease;
  }
  #global_search_input .menu .category .result:hover {
    background: rgba(0,0,0,0.05);
  }

  /* Test search dropdown styling */
  #test_search {
    font-size: 11px !important;
    min-height: 1.8rem !important;
    width: 200px !important;
  }
  #test_search .text {
    font-size: 11px !important;
  }
  #test_search .menu {
    font-size: 11px !important;
  }
  #test_search .menu .category > .name {
    font-weight: 700;
    color: #2185d0;
    background: #f8f9fa;
    padding: 6px 12px;
    font-size: 11px !important;
    border-bottom: 1px solid #e0e0e0;
  }
  #test_search .menu .category .result {
    font-size: 11px !important;
    padding: 0.5rem 0.8rem !important;
  }
  /* Results without category wrapper (specific category mode) */
  #test_search .menu > .result {
    font-size: 11px !important;
    padding: 0.5rem 0.8rem !important;
    cursor: pointer;
    transition: background 0.1s ease;
  }
  #test_search .menu > .result:hover {
    background: rgba(0,0,0,0.05);
  }

  /* Test search category selector */
  #test_search_category { font-size: 11px !important; min-height: 1.8rem !important; min-width: 140px !important; }
  #test_search_category + .menu { font-size: 11px !important; }
  #test_search_category + .menu .item { font-size: 11px !important; padding: 0.5rem 0.8rem !important; }

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
                div(style = "display: flex; gap: 0.5rem; width: 600px;",
                    shiny.semantic::dropdown_input(
                      input_id = "global_search_input",
                      choices = character(0),
                      choices_value = character(0),
                      value = "",
                      type = "selection fluid search",
                      default_text = "Type 3+ chars to search all..."
                    ),
                    tags$div(id = "test_search_wrapper"),
                    shiny.semantic::dropdown_input(
                      input_id = "global_search_category",
                      choices = c("All", "Containers", "Shapes", "Siloes", "Sites", "Areas", "Operations", "Layouts"),
                      choices_value = c("all", "containers", "shapes", "siloes", "sites", "areas", "operations", "layouts"),
                      value = "all",
                      type = "compact selection"
                    )
                )
            )
        ),
        div(style = "padding: 0.5rem 1rem; background: #f8f9fa; margin-bottom: 1rem; border-radius: 0.3rem;",
            tags$strong("Test Search Selected: "),
            textOutput("test_search_output", inline = TRUE)
        ),
        uiOutput("f_route_outlet")
    ),
    
    # ------ Router + collapse + collapsible groups ------
    tags$script(HTML("
      (function(){
        $(document).ready(function(){
          // Initialize simple test search dropdown with grouped results
          // Track last query sent to server
          var lastTestSearchQuery = '';
          var lastSentTestSearchQuery = '';
          var testSearchDebounce = null;

          $('#test_search_wrapper').html(
            '<div class=\"ui selection search dropdown\" id=\"test_search\">' +
            '<input type=\"hidden\" name=\"test_search\">' +
            '<i class=\"dropdown icon\"></i>' +
            '<div class=\"default text\">Type 3+ chars...</div>' +
            '<div class=\"menu\">' +
              '<div class=\"category\">' +
                '<div class=\"name\">Type 3+ chars...</div>' +
                '<div class=\"results\"></div>' +
              '</div>' +
            '</div>' +
            '</div>'
          );

          // Initialize the dropdown
          $('#test_search').dropdown({
            fullTextSearch: true,
            onChange: function(value, text, $selectedItem) {
              console.log('[TestSearch] Selected:', value, text);
              if (window.Shiny) {
                Shiny.setInputValue('test_search_input', value, {priority: 'event'});
              }
            }
          });

          // Listen for global category changes to clear test search
          $(document).on('shiny:inputchanged', function(event) {
            if (event.name === 'global_search_category') {
              console.log('[TestSearch] Category changed to:', event.value);
              var $testSearch = $('#test_search');

              // Reset tracking variables FIRST
              lastTestSearchQuery = '';
              lastSentTestSearchQuery = '';

              // Fully reset the dropdown
              $testSearch.dropdown('clear');
              $testSearch.dropdown('restore defaults');

              // Clear all input fields
              var $searchInput = $testSearch.find('input.search');
              $searchInput.val('');
              $testSearch.find('input[type=hidden]').val('');
              $testSearch.find('.text').text('Type 3+ chars...').addClass('default');

              // Clear menu
              $testSearch.find('.menu').empty().append(
                '<div class=\"category\"><div class=\"name\">Type 3+ chars...</div><div class=\"results\"></div></div>'
              );

              if (window.Shiny) {
                // Send empty query for test search
                Shiny.setInputValue('test_search_query', '', {priority: 'event'});
                Shiny.setInputValue('test_search_input', '', {priority: 'event'});
              }

              console.log('[TestSearch] Category change complete. Cleared query.');
            }
          });

          var pushTestSearchQuery = function(val) {
            var next = val || '';
            if (next === lastSentTestSearchQuery) {
              lastTestSearchQuery = next;
              return;
            }
            console.log('[TestSearch][push] sending to Shiny:', next);
            lastTestSearchQuery = next;
            lastSentTestSearchQuery = next;
            if (window.Shiny) {
              Shiny.setInputValue('test_search_query', next, {priority: 'event'});
            }
          };

          // Capture typing in test search
          $(document).on('input', '#test_search input.search', function(e) {
            var val = e.target.value || '';
            console.log('[TestSearch][input] val=', val, 'lastSent=', lastSentTestSearchQuery);
            clearTimeout(testSearchDebounce);
            testSearchDebounce = setTimeout(function(){ pushTestSearchQuery(val); }, 120);
          });

          // Custom message handler to update test search menu from server
          if (window.Shiny && window.Shiny.addCustomMessageHandler) {
            Shiny.addCustomMessageHandler('test-search-menu', function(msg) {
              console.log('[TestSearch] Received message:', msg);
              var $dd = $('#test_search');
              if (!$dd.length || !$dd.dropdown) return;
              var $menu = $dd.find('.menu');
              if (!$menu.length) return;

              $menu.empty();

              var showCategories = msg.show_categories !== false; // default to true

              if (!msg || !msg.groups || !msg.groups.length) {
                $menu.append('<div class=\"category\"><div class=\"name\">No items</div><div class=\"results\"></div></div>');
              } else {
                console.log('[TestSearch] Processing', msg.groups.length, 'groups, show_categories:', showCategories);
                msg.groups.forEach(function(g, idx) {
                  if (!g) {
                    console.log('[TestSearch] Group', idx, 'is null/undefined');
                    return;
                  }
                  var grpName = g.name || '';
                  var items = g.items || [];
                  console.log('[TestSearch] Group', idx, ':', grpName, 'with', items.length, 'items');

                  if (showCategories) {
                    // Create category container with header
                    var $category = $('<div class=\"category\"></div>');

                    // Add category name header
                    if (grpName) {
                      $category.append($('<div class=\"name\"></div>').text(grpName));
                    }

                    // Add results container for this category
                    var $results = $('<div class=\"results\"></div>');
                    items.forEach(function(it) {
                      var $item = $('<div class=\"result\"></div>').attr('data-value', it).text(it);
                      $results.append($item);
                    });

                    $category.append($results);
                    $menu.append($category);
                    console.log('[TestSearch] Appended category:', grpName);
                  } else {
                    // No categories - add items directly as plain results
                    items.forEach(function(it) {
                      var $item = $('<div class=\"result\"></div>').attr('data-value', it).text(it);
                      $menu.append($item);
                    });
                    console.log('[TestSearch] Appended', items.length, 'items without category');
                  }
                });
              }

              console.log('[TestSearch] Final menu HTML:', $menu.html().substring(0, 500));
              $dd.dropdown('refresh');

              // Restore search box text only if not empty or if current value is empty
              var el = document.querySelector('#test_search input.search');
              if (el && msg && typeof msg.query === 'string') {
                console.log('[TestSearch] Message wants to restore query to:', msg.query, 'current value:', el.value);
                // Only restore if the server query matches what we expect
                if (msg.query === lastTestSearchQuery || el.value === '') {
                  lastTestSearchQuery = msg.query;
                  lastSentTestSearchQuery = msg.query;
                  if (el.value !== msg.query) {
                    el.value = msg.query;
                    console.log('[TestSearch] Restored input to:', msg.query);
                  }
                } else {
                  console.log('[TestSearch] Skipping restore - mismatch');
                }
              }
            });
          }


          // Handle Enter key to select if only one result
          $(document).on('keydown', '#test_search input.search', function(e) {
            if (e.key === 'Enter' || e.keyCode === 13) {
              e.preventDefault();
              var $visibleResults = $('#test_search .menu .result:visible');

              if ($visibleResults.length === 1) {
                $visibleResults.first().click();
              }
            }
          });

          // Handle clicks on result items manually
          $(document).on('click', '#test_search .result', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var value = $(this).attr('data-value');
            var text = $(this).text();

            // Update the hidden input and display text
            $('#test_search').dropdown('set selected', value);
            $('#test_search .text').text(text).removeClass('default');

            // Update the search input box to show selected text
            $('#test_search input.search').val(text);

            // Hide the dropdown menu
            $('#test_search').dropdown('hide');

            console.log('[TestSearch] Clicked:', value, text);
            if (window.Shiny) {
              Shiny.setInputValue('test_search_input', value, {priority: 'event'});
            }
          });

          // Wait for shiny.semantic dropdown initialization, then extend with custom behavior
          setTimeout(function() {
            $('#global_search_category').dropdown({
              onChange: function(value, text, $selectedItem) {
                // Clear search input when category changes
                var $input = $('#global_search_input');
                $input.val('').css('color', '');
                lastGlobalSearchQuery = '';
                lastSentGlobalSearchQuery = '';
                var $searchBox = $('#global_search_input input.search');
                if ($searchBox.length) $searchBox.val('');

                // CRITICAL: Update both Shiny inputs when dropdown changes
                if (window.Shiny) {
                  Shiny.setInputValue('global_search_category', value, {priority: 'event'});
                  // Clear the search query in Shiny too, not just visually
                  Shiny.setInputValue('global_search_input', '', {priority: 'event'});
                  Shiny.setInputValue('global_search_query', '', {priority: 'event'});
                }
              }
            });
          }, 100);

        });

        // Send live query text from the dropdown's search box to Shiny
        var gsDebounce = null;
        var lastGlobalSearchQuery = '';
        var lastSentGlobalSearchQuery = '';
        var pushGlobalSearchQuery = function(val){
          var next = val || '';
          if (next === lastSentGlobalSearchQuery) {
            lastGlobalSearchQuery = next;
            return;
          }
          console.log('[GlobalSearch][push] sending to Shiny:', next);
          lastGlobalSearchQuery = next;
          lastSentGlobalSearchQuery = next;
          if (window.Shiny) {
            Shiny.setInputValue('global_search_query', lastGlobalSearchQuery, {priority: 'event'});
          }
        };

        // Delegate to handle re-rendered dropdowns
        $(document).on('input', '#global_search_input input.search', function(e){
          var val = e.target.value || '';
          console.log('[GlobalSearch][input] val=', val);
          $('#global_search_input .text').text(''); // hide placeholder while typing
          clearTimeout(gsDebounce);
          gsDebounce = setTimeout(function(){ pushGlobalSearchQuery(val); }, 120);
        });

        // Fallback for plain text inputs (datalist style) if present
        $(document).on('input', '#global_search_input', function(e){
          var val = e.target.value || '';
          console.log('[GlobalSearch][input-plain] val=', val);
          $('#global_search_input .text').text('');
          clearTimeout(gsDebounce);
          gsDebounce = setTimeout(function(){ pushGlobalSearchQuery(val); }, 120);
        });

        // Handle clicks on grouped search results
        $(document).on('click', '#global_search_input .menu .category .result', function(e){
          e.preventDefault();
          e.stopPropagation();
          var value = $(this).attr('data-value') || $(this).text();
          var $dd = $('#global_search_input');

          // Update the dropdown's visible text
          $dd.find('.text').text(value).removeClass('default');

          // Hide the menu
          $dd.dropdown('hide');

          // Send the selection to Shiny
          if (window.Shiny) {
            Shiny.setInputValue('global_search_input', value, {priority: 'event'});
          }

          console.log('[GlobalSearch][click] selected:', value);
        });

        // Ensure dropdown stays searchable and retains text after updates
        $(document).on('shiny:inputchanged', function(event){
          if (event.name === 'global_search_input') {
            var $dd = $('#global_search_input');
            if ($dd.dropdown) {
              $dd.dropdown({ fullTextSearch: true });
            }
            var el = document.querySelector('#global_search_input input.search') || document.getElementById('global_search_input');
            if (!el) return;
            if (el.value !== lastGlobalSearchQuery) el.value = lastGlobalSearchQuery;
            console.log('[GlobalSearch][rerender] restoring value:', el.value || '');
            pushGlobalSearchQuery(el.value || '');
          }
        });

        // Custom message from server to restore the current query after dropdown updates
        if (window.Shiny && window.Shiny.addCustomMessageHandler) {
          Shiny.addCustomMessageHandler('global-search-restore', function(msg){
            var el = document.querySelector('#global_search_input input.search') || document.getElementById('global_search_input');
            if (!el) return;
            if (msg && typeof msg.q === 'string') {
              el.value = msg.q;
              lastGlobalSearchQuery = msg.q;
              lastSentGlobalSearchQuery = msg.q;
              console.log('[GlobalSearch][restore] set to:', msg.q);
            }
          });
          Shiny.addCustomMessageHandler('global-search-menu', function(msg){
            var $dd = $('#global_search_input');
            if (!$dd.length || !$dd.dropdown) return;
            var $menu = $dd.find('.menu');
            if (!$menu.length) return;
            $menu.empty();
            if (!msg || !msg.groups || !msg.groups.length) {
              $menu.append($('<div class=\"item disabled\">No items</div>'));
            } else {
              msg.groups.forEach(function(g){
                if (!g) return;
                var grpName = g.name || '';
                var items = g.items || [];

                // Create category container
                var $category = $('<div class=\"category\"></div>');

                // Add category name header
                if (grpName) {
                  $category.append($('<div class=\"name\"></div>').text(grpName));
                }

                // Add results container for this category
                var $results = $('<div class=\"results\"></div>');
                items.forEach(function(it){
                  var $item = $('<div class=\"result\"></div>').attr('data-value', it).text(it);
                  $results.append($item);
                });

                $category.append($results);
                $menu.append($category);
              });
            }
            $dd.dropdown('refresh');
            // Restore search box text
            var el = document.querySelector('#global_search_input input.search');
            if (el && msg && typeof msg.query === 'string') {
              lastGlobalSearchQuery = msg.query;
              lastSentGlobalSearchQuery = msg.query;
              el.value = msg.query;
            }
            // Update visible placeholder/label if provided
            if (msg && msg.placeholder) {
              var $text = $dd.find('.text');
              if ($text.length) {
                var q = (msg && typeof msg.query === 'string') ? msg.query : '';
                if (q.length > 0) {
                  $text.text('');
                  $text.removeClass('default');
                } else {
                  $text.text(msg.placeholder);
                  $text.addClass('default');
                }
              }
            }
          });
        }

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
