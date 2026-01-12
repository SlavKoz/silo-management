# Silo Application Suite

This repository contains two Shiny applications for the Silo system:

## Structure

```
Silo/
├── SiloAdmin/          # Admin application for configuration
│   ├── app.R
│   ├── global.R
│   ├── R/
│   │   ├── browsers/   # Admin browser modules
│   │   ├── canvas/     # Canvas management
│   │   ├── f_app_server.R
│   │   ├── f_app_ui.R
│   │   └── f_landing_page.R
│   └── www/            # Admin static assets
│
├── SiloOps/            # Operations application for daily use
│   ├── app.R
│   ├── global.R
│   ├── R/
│   │   ├── f_app_server.R
│   │   ├── f_app_ui.R
│   │   └── f_landing_page.R
│   └── www/            # Operations static assets
│
└── shared/             # Shared code between apps
    └── R/
        ├── db/         # Database queries and connection
        ├── react_table/# HTML forms and tables
        └── utils/      # Shared utilities and helpers
```

## Applications

### SiloAdmin (Port 3838)

Administrator interface for:
- Managing commodities, grain groups, and variants
- Configuring silos, shapes, and containers
- Managing sites, areas, and operations
- Icon and canvas management
- Offline reason configuration

### SiloOps (Port 3839)

Operations interface for:
- Daily silo operations
- Task queue management
- Operational reports
- Settings for operations users

## Development

### Running Locally

**Option 1: Run both apps**
```r
# Terminal 1 - Admin App
setwd("C:/path/to/Silo/SiloAdmin")
shiny::runApp(port = 3838)

# Terminal 2 - Ops App
setwd("C:/path/to/Silo/SiloOps")
shiny::runApp(port = 3839)
```

**Option 2: Run one at a time**
```r
# Just Admin
setwd("C:/path/to/Silo/SiloAdmin")
shiny::runApp()

# Just Ops
setwd("C:/path/to/Silo/SiloOps")
shiny::runApp()
```

### Deployment to Shiny Server (Ubuntu)

```bash
# Deploy to /srv/shiny-server/
sudo cp -r SiloAdmin /srv/shiny-server/
sudo cp -r SiloOps /srv/shiny-server/
sudo cp -r shared /srv/shiny-server/

# Restart Shiny Server
sudo systemctl restart shiny-server
```

Access:
- Admin: `http://yourserver:3838/SiloAdmin/`
- Ops: `http://yourserver:3838/SiloOps/`

## Configuration

### Database Connection

Password file should be located at:
```
../secrets/db_password.txt
```

From the working directory of each app (SiloAdmin or SiloOps):
- Goes up to `Silo/`
- Then up to `MyRProjects/`
- Then into `secrets/`

### Shared Resources

Both apps reference shared resources via relative paths:
```r
source_dir("../shared/R/utils")
source_dir("../shared/R/db")
source_dir("../shared/R/react_table")
```

## Links Between Apps

- **SiloOps → SiloAdmin**: "Admin" button in header (for authorized users)
- **SiloAdmin → SiloOps**: Can add "Operations" link in admin app

Deep linking works between apps (e.g., `http://localhost:3838/SiloAdmin#/shapes/circle%20XL`)

## Git Repository

This is a monorepo containing both applications. Commit changes together to keep them in sync.

```bash
git add .
git commit -m "Update: description of changes"
git push
```
