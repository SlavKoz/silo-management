# SiloOps/app.R
# Silo Operations Application

# Source global
source("global.R", local = TRUE)

# Define UI
ui <- f_app_ui()

# Define server
server <- f_app_server

# Run the application
shinyApp(ui = ui, server = server)
