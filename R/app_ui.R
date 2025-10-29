app_ui <- function() {
  bs4Dash::dashboardPage(
    header = bs4Dash::dashboardHeader(),
    sidebar = bs4Dash::dashboardSidebar(
      bs4Dash::sidebarMenu(
        bs4Dash::menuItem("Icons",      tabName = "icons",      icon = icon("icons")),
        bs4Dash::menuItem("Containers", tabName = "containers", icon = icon("boxes")),
        bs4Dash::menuItem("Silos",      tabName = "silos",      icon = icon("warehouse")),
        bs4Dash::menuItem("Placements", tabName = "placements", icon = icon("map-marker-alt")),
        bs4Dash::menuItem("Canvas",     tabName = "canvas",     icon = icon("project-diagram"))
      )
    ),
    body = bs4Dash::dashboardBody(
      shiny::singleton(
        tags$head(
          tags$link(rel="stylesheet", href="css/admin.css?v=20251009"),
          tags$link(rel="stylesheet", href="css/react-table.css?v=20251009"),
          tags$link(rel="stylesheet", href="css/silo-canvas.css?v=20251009"),
          tags$link(rel="stylesheet", href="css/admin-grid.css"),
          tags$script(src="vendor/rjsf-grid.js"),
          tags$script(src="js/admin-grid.js"),
          tags$script(src="js/icon-browser.js"),
          # minimal handlers you already used
          tags$script(HTML("
            if (window.Shiny && Shiny.addCustomMessageHandler) {
              Shiny.addCustomMessageHandler('react-edit-state', function(msg){
                var el = document.getElementById(msg.elId);
                if (!el) return; if (msg.isEdit) el.classList.add('is-edit'); else el.classList.remove('is-edit');
              });
              Shiny.addCustomMessageHandler('react-table-props', function(cfg){
                if (window.renderRJSFGrid) { window.renderRJSFGrid(cfg.elId, cfg); }
              });
            }
          "))
        )
      ),
      
      bs4Dash::bs4TabItems(
        # Icons: prefer f_ module if present
        bs4Dash::bs4TabItem(
          tabName = "icons",
          if (exists("f_browser_icons_ui")) f_browser_icons_ui("icons")
          else if (exists("browser_icons_ui")) browser_icons_ui("icons")
          else div("icons UI placeholder")
        ),
        
        bs4Dash::bs4TabItem(
          tabName = "containers",
          if (exists("f_browser_containers_ui")) f_browser_containers_ui("containers")
          else if (exists("browser_containers_ui")) browser_containers_ui("containers")
          else div("containers UI placeholder")
        ),
        
        bs4Dash::bs4TabItem(
          tabName = "silos",
          if (exists("f_browser_silos_ui")) f_browser_silos_ui("silos")
          else if (exists("browser_silos_ui")) browser_silos_ui("silos")
          else div("silos UI placeholder")
        ),
        
        bs4Dash::bs4TabItem(
          tabName = "placements",
          if (exists("f_browser_placements_ui")) f_browser_placements_ui("placements")
          else if (exists("browser_placements_ui")) browser_placements_ui("placements")
          else div("placements UI placeholder")
        ),
        
        bs4Dash::bs4TabItem(
          tabName = "canvas",
          if (exists("f_canvas_ui")) f_canvas_ui("canvas")
          else if (exists("canvas_ui")) canvas_ui("canvas")
          else div("canvas UI placeholder")
        )
      )
    ),
    controlbar = NULL,
    footer = NULL,
    title = "Silo"
  )
}
