# app.R
source("global.R", local = TRUE)

ui <- if (exists("f_app_ui", inherits = TRUE)) f_app_ui() else app_ui()
server <- if (exists("f_app_server", inherits = TRUE)) f_app_server else app_server

# Force port 3838 - prevents Shiny from using random ports on restart
# If port is busy, app will error instead of silently switching ports
shinyApp(ui = ui, server = server, options = list(port = 3838, launch.browser = TRUE))
