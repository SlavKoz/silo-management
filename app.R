# app.R
source("global.R", local = TRUE)

ui <- if (exists("f_app_ui", inherits = TRUE)) f_app_ui() else app_ui()
server <- if (exists("f_app_server", inherits = TRUE)) f_app_server else app_server

shinyApp(ui = ui, server = server)
