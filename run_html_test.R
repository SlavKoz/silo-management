#!/usr/bin/env Rscript
# Test runner for HTML-based form (no vendor JS)

cat("\n╔════════════════════════════════════════╗\n")
cat("║   HTML Form Test (No Vendor JS)        ║\n")
cat("╚════════════════════════════════════════╝\n\n")

cat("This test uses pure R/HTML rendering.\n")
cat("NO vendor/rjsf-grid.js file needed!\n\n")

# Check packages
required <- c("shiny")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE, quietly = TRUE)
}

# Load modules
cat("Loading modules...\n")
source("R/react_table/react_table_dsl.R", local = TRUE)
source("R/react_table/react_table_auto.R", local = TRUE)
source("R/test_html_form.R", local = TRUE)

cat("\nLaunching app...\n\n")

run_html_form_test()
