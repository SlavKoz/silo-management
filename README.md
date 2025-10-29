# Silo Management Application

A Shiny application for managing grain silo configurations, including types, placements, graphical representations, and business rules.

## 🚧 Current Status: UI Migration in Progress

This application is currently transitioning from **bs4Dash** to **Fomantic UI** (shiny.semantic). 

### File Naming Convention
- **`f_*.R` files**: New Fomantic UI implementation (CURRENT PRODUCTION)
- **Non-prefixed files** (e.g., `app_ui.R`): Legacy bs4Dash version (DEPRECATED)

The migration is being done incrementally, with fixes and improvements applied along the way.

## 📋 Features

- **Silo Browser**: View and manage grain silo configurations
- **Icon Browser**: Manage visual representations for silos
- **Container Browser**: Handle container types and specifications
- **Placement Browser**: Define silo placement rules and locations
- **Canvas Manager**: Visual editor for silo layouts
- **React Table Integration**: Dynamic data grids with filtering and editing

## 🛠️ Tech Stack

- **R Shiny**: Application framework
- **shiny.semantic**: Fomantic UI components
- **bs4Dash**: Legacy UI framework (being phased out)
- **JavaScript/CSS**: Custom interactions and styling
- **Database**: Backend storage (credentials in excluded `Secrets/` folder)

## 📁 Project Structure

```
Silo/
├── app.R                  # Main entry point
├── global.R               # Bootstrap & module loader
├── R/
│   ├── f_app_ui.R        # Current Fomantic UI shell
│   ├── f_app_server.R    # Current server logic
│   ├── browsers/         # Data browser modules
│   ├── canvas/           # Visual layout editor
│   ├── db/               # Database connections & queries
│   ├── react_table/      # Table component system
│   └── utils/            # Helper functions
└── www/
    ├── js/               # Custom JavaScript
    └── css/              # Custom stylesheets
```

## 🚀 Getting Started

### Prerequisites
- R (>= 4.0)
- Required packages: `shiny`, `shiny.semantic`, `bs4Dash`, `shinyWidgets`, `shinyjs`, `jsonlite`, `httr`, `xml2`, `magick`, `rsvg`

### Installation

1. Clone this repository
2. Create a `Secrets/` folder with database credentials
3. Install required R packages:
   ```r
   install.packages(c("shiny", "shiny.semantic", "bs4Dash", "shinyWidgets", 
                      "shinyjs", "jsonlite", "httr", "xml2", "magick", "rsvg"))
   ```
4. Run the app:
   ```r
   shiny::runApp()
   ```

## 🔒 Security Note

Database credentials are stored in the `Secrets/` folder, which is **not included** in this repository. You'll need to configure your own database connection.

## 📝 Development Notes

### Module Loading Strategy
The `global.R` uses a smart loader that:
1. Loads legacy files first
2. Automatically overrides with `f_*` prefixed files
3. Maintains backward compatibility during migration

### Migration Progress
- ✅ Core UI shell (f_app_ui.R)
- ✅ Server logic (f_app_server.R)
- ✅ Helper utilities (f_helper_*.R)
- 🚧 Browser modules (in progress)
- ⏳ Canvas manager (planned)

## 🤝 Contributing

This is an internal application for grain silo management. Contact the maintainer for access or questions.

## 📄 License

Internal use only - Camgrain
