#!/usr/bin/env Rscript
# Test runner for SiloPlacements Browser (modularized version)

# Check packages
required <- c("shiny", "shinyjs", "shinyalert")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE, quietly = TRUE)
}

# Load modules
cat("[Test] Loading modules...\n")
source("R/utils/f_helper_core.R", local = TRUE)
source("R/db/connect_wrappers.R", local = TRUE)
source("R/db/queries.R", local = TRUE)
source("R/react_table/react_table_dsl.R", local = TRUE)
source("R/react_table/react_table_auto.R", local = TRUE)
source("R/react_table/html_form_renderer.R", local = TRUE)
source("R/react_table/mod_html_form.R", local = TRUE)
source("R/browsers/f_browser_siloplacements.R", local = TRUE)

cat("\n=== Launching SiloPlacements Browser Test ===\n")
cat("Modularized version with external CSS and helpers\n\n")

run_siloplacements_canvas_test()

