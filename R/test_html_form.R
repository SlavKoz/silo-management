# R/test_html_form.R
# Test file demonstrating the generic HTML form module

# Load the generic module
source("R/react_table/mod_html_form.R", local = TRUE)

# UI - uses the generic module
test_html_form_ui <- function(id) {
  mod_html_form_ui(id)
}

# Server - demonstrates how to configure the module
test_html_form_server <- function(id) {
  # Define schema configuration
  schema_config <- list(
    fields = list(
      # COLUMN 1 - Basic Info
      field("ItemName", "text", title = "Item Name", column = 1),
      field("ItemCode", "text", title = "Item Code", column = 1),

      # COLUMN 2 - Quantities
      field("Quantity", "number", title = "Quantity", min = 0, max = 1000, column = 2),
      field("Category", "select", title = "Category",
            enum = c("Type A", "Type B", "Type C"), column = 2),

      # COLUMN 3 - Specs Group (OPEN/EXPANDED)
      field("Width", "number", title = "Width (cm)", min = 0, max = 500, group = "Specs"),
      field("Height", "number", title = "Height (cm)", min = 0, max = 500, group = "Specs"),
      field("Weight", "number", title = "Weight (kg)", min = 0, max = 1000, group = "Specs"),
      field("Color", "color", title = "Label Color", group = "Specs"),

      # COLUMN 4 - Metadata Group (COLLAPSED)
      field("CreatedBy", "text", title = "Created By", group = "Metadata"),
      field("CreatedAt", "text", title = "Created At", group = "Metadata"),
      field("UpdatedAt", "text", title = "Updated At", group = "Metadata")
    ),
    groups = list(
      group("Specs", title = "Specifications", collapsible = TRUE, collapsed = FALSE, column = 3),
      group("Metadata", title = "Metadata", collapsible = TRUE, collapsed = TRUE, column = 4)
    ),
    columns = 4,
    static_fields = c("Metadata.CreatedBy", "Metadata.CreatedAt", "Metadata.UpdatedAt")
  )

  # Sample data
  formData <- list(
    ItemName = "Sample Item",
    ItemCode = "ITEM001",
    Quantity = 10,
    Category = "Type A",
    Specs = list(
      Width = 50,
      Height = 30,
      Weight = 2.5,
      Color = "#3498db"
    ),
    Metadata = list(
      CreatedBy = "System",
      CreatedAt = "2025-01-15 10:00:00",
      UpdatedAt = "2025-01-15 14:30:00"
    )
  )

  # Call the generic module server
  mod_html_form_server(
    id = id,
    schema_config = schema_config,
    form_data = formData,
    title_field = "ItemName",
    show_header = TRUE,
    show_delete_button = TRUE
  )
}

# Standalone runner
run_html_form_test <- function() {
  library(shiny)

  # Load DSL
  if (!exists("compile_rjsf")) {
    cat("[Test] Loading DSL modules...\n")
    source("R/react_table/react_table_dsl.R", local = TRUE)
    source("R/react_table/react_table_auto.R", local = TRUE)
  }

  ui <- fluidPage(
    title = "HTML Form Test",
    test_html_form_ui("test")
  )

  server <- function(input, output, session) {
    test_html_form_server("test")
  }

  cat("\n=== Launching HTML Form Test ===\n")
  cat("This uses pure R/HTML rendering\n")
  cat("NO vendor/rjsf-grid.js file needed!\n\n")

  shinyApp(ui, server)
}
