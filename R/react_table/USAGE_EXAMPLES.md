# HTML Form Module - Usage Examples

## Overview
The `mod_html_form` module is a generic, reusable form component that can be used throughout the application. It supports multiple instances on the same page through proper Shiny namespacing.

## File Location
- **Module**: `R/react_table/mod_html_form.R`
- **Test Example**: `R/test_html_form.R`

## Key Features
- ✅ **Multiple Instances**: Use multiple forms on the same tab without conflicts
- ✅ **Proper Namespacing**: Each instance has isolated CSS, JavaScript, and inputs
- ✅ **Reactive Support**: Schema and data can be reactive or static
- ✅ **Customizable**: Configure columns, groups, static fields, and styling
- ✅ **Edit/Lock Toggle**: Built-in edit mode with visual feedback
- ✅ **No Vendor JS**: Pure R/HTML rendering

---

## Basic Usage

### Single Form Instance

```r
library(shiny)

# Load required modules
source("R/react_table/react_table_dsl.R")
source("R/react_table/react_table_auto.R")
source("R/react_table/mod_html_form.R")

ui <- fluidPage(
  # Single form instance
  mod_html_form_ui("my_form")
)

server <- function(input, output, session) {
  # Define schema configuration
  schema_config <- list(
    fields = list(
      field("Name", "text", title = "Full Name"),
      field("Email", "text", title = "Email Address"),
      field("Age", "number", title = "Age", min = 18, max = 100)
    ),
    columns = 1,
    static_fields = character(0)
  )

  # Define form data
  form_data <- list(
    Name = "John Doe",
    Email = "john@example.com",
    Age = 30
  )

  # Initialize module
  mod_html_form_server(
    id = "my_form",
    schema_config = schema_config,
    form_data = form_data,
    title_field = "Name",
    show_header = TRUE
  )
}

shinyApp(ui, server)
```

---

## Multiple Instances on Same Page

### Example: Two Forms Side-by-Side

```r
ui <- fluidPage(
  titlePanel("Multiple Forms Demo"),

  fluidRow(
    column(6,
      h3("Customer Form"),
      mod_html_form_ui("customer_form")
    ),
    column(6,
      h3("Product Form"),
      mod_html_form_ui("product_form")
    )
  )
)

server <- function(input, output, session) {
  # Customer form configuration
  customer_schema <- list(
    fields = list(
      field("CustomerName", "text", title = "Customer Name"),
      field("CustomerID", "text", title = "Customer ID"),
      field("Email", "text", title = "Email"),
      field("Phone", "text", title = "Phone")
    ),
    columns = 2,
    static_fields = c("CustomerID")
  )

  customer_data <- list(
    CustomerName = "ACME Corp",
    CustomerID = "CUST-001",
    Email = "contact@acme.com",
    Phone = "555-1234"
  )

  # Product form configuration
  product_schema <- list(
    fields = list(
      field("ProductName", "text", title = "Product Name"),
      field("SKU", "text", title = "SKU"),
      field("Price", "number", title = "Price", min = 0),
      field("Stock", "number", title = "Stock", min = 0)
    ),
    columns = 2,
    static_fields = c("SKU")
  )

  product_data <- list(
    ProductName = "Widget A",
    SKU = "WDG-A-001",
    Price = 29.99,
    Stock = 150
  )

  # Initialize both forms - UNIQUE IDs ensure no conflicts
  mod_html_form_server(
    id = "customer_form",
    schema_config = customer_schema,
    form_data = customer_data,
    title_field = "CustomerName",
    show_header = TRUE
  )

  mod_html_form_server(
    id = "product_form",
    schema_config = product_schema,
    form_data = product_data,
    title_field = "ProductName",
    show_header = TRUE
  )
}
```

---

## Using with Reactive Data

### Example: Form Updates Based on Selection

```r
server <- function(input, output, session) {
  # Reactive data source
  selected_item <- reactive({
    # This could come from a table selection, input, etc.
    list(
      ItemName = "Dynamic Item",
      ItemCode = paste0("ITEM-", input$selected_id),
      Status = "Active"
    )
  })

  # Reactive schema configuration
  schema_config <- reactive({
    list(
      fields = list(
        field("ItemName", "text", title = "Item Name"),
        field("ItemCode", "text", title = "Item Code"),
        field("Status", "select", title = "Status",
              enum = c("Active", "Inactive", "Pending"))
      ),
      columns = 1,
      static_fields = c("ItemCode")  # Code is read-only
    )
  })

  # Module accepts reactive inputs
  mod_html_form_server(
    id = "dynamic_form",
    schema_config = schema_config,  # Reactive
    form_data = selected_item,      # Reactive
    title_field = "ItemName",
    show_header = TRUE
  )
}
```

---

## Integration in Main Application

### In Your Main App (e.g., f_app_ui.R)

```r
# Load the module at the top of your UI file
source("R/react_table/mod_html_form.R")

# In a tab panel
tabPanel(
  "Container Details",
  value = "container_details",

  # Use the form module with a unique ID
  mod_html_form_ui("container_form", max_width = "1400px")
)
```

### In Your Server (e.g., f_app_server.R)

```r
# Load DSL and module
source("R/react_table/react_table_dsl.R")
source("R/react_table/react_table_auto.R")
source("R/react_table/mod_html_form.R")

# Define schema for containers
container_schema <- list(
  fields = list(
    # Column 1
    field("ContainerNumber", "text", title = "Container Number", column = 1),
    field("Location", "text", title = "Location", column = 1),

    # Column 2
    field("Capacity", "number", title = "Capacity (MT)", min = 0, column = 2),
    field("CurrentLevel", "number", title = "Current Level (MT)", min = 0, column = 2),

    # Column 3 - Metadata
    field("CreatedAt", "text", title = "Created", group = "Metadata"),
    field("UpdatedAt", "text", title = "Updated", group = "Metadata")
  ),
  groups = list(
    group("Metadata", title = "Metadata", collapsible = TRUE, collapsed = TRUE, column = 3)
  ),
  columns = 3,
  static_fields = c("Metadata.CreatedAt", "Metadata.UpdatedAt")
)

# Reactive container data (from table selection, database, etc.)
selected_container <- reactive({
  req(input$container_table_selected)
  # Fetch container data based on selection
  fetch_container_data(input$container_table_selected)
})

# Initialize form module
mod_html_form_server(
  id = "container_form",
  schema_config = container_schema,
  form_data = selected_container,
  title_field = "ContainerNumber",
  show_header = TRUE
)
```

---

## Multiple Instances in Tabs

### Example: Different Forms in Different Tabs

```r
ui <- navbarPage(
  "My Application",

  # Tab 1: Containers
  tabPanel(
    "Containers",
    mod_html_form_ui("container_form")
  ),

  # Tab 2: Products
  tabPanel(
    "Products",
    mod_html_form_ui("product_form")
  ),

  # Tab 3: Customers
  tabPanel(
    "Customers",
    mod_html_form_ui("customer_form")
  )
)

server <- function(input, output, session) {
  # Each form has unique configuration and data
  # No conflicts because each has a unique ID

  mod_html_form_server("container_form", container_schema, container_data, ...)
  mod_html_form_server("product_form", product_schema, product_data, ...)
  mod_html_form_server("customer_form", customer_schema, customer_data, ...)
}
```

---

## Advanced Configuration Options

### All Available Parameters

```r
mod_html_form_server(
  id = "my_form",                    # REQUIRED: Unique module ID

  schema_config = list(              # REQUIRED: Form schema definition
    fields = list(...),              # List of field() definitions
    groups = list(...),              # List of group() definitions (optional)
    columns = 2,                     # Number of columns (1-4)
    static_fields = c(...),          # Vector of read-only field paths
    widgets = list(...)              # Custom widgets (optional)
  ),

  form_data = list(...),             # REQUIRED: Form data (reactive or static)

  title_field = "ItemName",          # Field to use for header title (optional)
  show_header = TRUE                 # Show/hide header (default: TRUE)
)
```

### UI Customization

```r
mod_html_form_ui(
  id = "my_form",                    # REQUIRED: Unique module ID
  max_width = "1200px",              # Maximum form width (default: "1200px")
  margin = "2rem auto"               # Form margin (default: "2rem auto")
)
```

---

## Important Notes

### Namespace Isolation
Each form instance is completely isolated:
- **CSS** is scoped to the module ID (e.g., `#my_form-form`)
- **JavaScript** functions are namespaced (e.g., `toggleEditMode_my_form`)
- **Inputs** are namespaced (e.g., `my_form-field_ItemName`)

This means you can have **unlimited** instances on the same page without any conflicts.

### Unique IDs Required
Always use unique IDs when creating multiple instances:

✅ **CORRECT**:
```r
mod_html_form_ui("form1")
mod_html_form_ui("form2")
mod_html_form_ui("container_details")
```

❌ **INCORRECT**:
```r
mod_html_form_ui("form")  # Used twice!
mod_html_form_ui("form")  # Will cause conflicts!
```

### Performance Considerations
- Each instance loads Bootstrap CSS/Icons (only once per page)
- Each instance has its own JavaScript edit toggle function
- For many instances (10+), consider lazy loading or pagination

---

## Retrieving Form Values

The module returns a list with helper functions:

```r
form_instance <- mod_html_form_server(
  id = "my_form",
  schema_config = schema_config,
  form_data = form_data,
  title_field = "ItemName"
)

# Access current data
observe({
  current_data <- form_instance$get_data()
  print(current_data)
})

# Access compiled schema
observe({
  schema <- form_instance$get_schema()
  print(schema$schema)
  print(schema$uiSchema)
})
```

---

## Testing

Run the test file to see a working example:

```r
source("run_html_test.R")
```

This demonstrates a 4-column layout with all features enabled.
