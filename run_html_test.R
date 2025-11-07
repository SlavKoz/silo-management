#!/usr/bin/env Rscript
# Test runner for HTML-based form (no vendor JS)


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

source("R/react_table/react_table_dsl.R", local = TRUE)
source("R/react_table/react_table_auto.R", local = TRUE)
source("R/test_html_form.R", local = TRUE)



run_html_form_test()
