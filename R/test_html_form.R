# R/test_html_form.R
# Test file demonstrating the generic HTML form module

# UI - uses the generic module
test_html_form_ui <- function(id) {
  mod_html_form_ui(id)
}

# Server - demonstrates how to configure the module
test_html_form_server <- function(id) {
  # Fetch real icons from database
  icons_df <- tryCatch({
    list_icons_for_picker(limit = 1000)
  }, error = function(e) {
    cat("Error fetching icons:", conditionMessage(e), "\n")
    data.frame(id = character(0), icon_name = character(0))
  })


  if (nrow(icons_df) == 0) {
    # Fallback to sample data if no database connection
    icons_df <- data.frame(
      id = c("1", "2", "3"),
      icon_name = c("Sample Icon 1", "Sample Icon 2", "Sample Icon 3"),
      stringsAsFactors = FALSE
    )
  }

  # Build enum choices for select (id as value, name as label)
  icon_choices <- setNames(
    as.character(icons_df$id),
    icons_df$icon_name
  )
  icon_choices <- c("(none)" = "", icon_choices)

  # Build icon metadata for thumbnail rendering with real png_32_b64
  icon_metadata <- lapply(seq_len(nrow(icons_df)), function(i) {
    has_b64 <- "png_32_b64" %in% names(icons_df) && !is.na(icons_df$png_32_b64[i]) && nzchar(as.character(icons_df$png_32_b64[i]))

    thumbnail_val <- if (has_b64) {
      paste0("data:image/png;base64,", icons_df$png_32_b64[i])
    } else {
      NULL
    }

    list(
      id = as.character(icons_df$id[i]),
      name = icons_df$icon_name[i],
      thumbnail = thumbnail_val
    )
  })

  # Define schema configuration
  schema_config <- list(
    fields = list(
      # COLUMN 1 - Basic Info
      field("ItemName", "text", title = "Item Name", column = 1),
      field("ItemCode", "text", title = "Item Code", column = 1),
      field("IconID", "select", title = "Icon", enum = icon_choices, widget = "icon-select", icon_metadata = icon_metadata, column = 1),
      field("IsActive", "switch", title = "Active (Switch)", column = 1, default = TRUE),
      field("IsEnabled", "checkbox", title = "Enabled (Checkbox)", column = 1, default = TRUE),

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
    IconID = "2",
    IsActive = TRUE,
    IsEnabled = TRUE,
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
