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
source("R/utils/f_helper_core.R", local = TRUE)
source("R/db/connect_wrappers.R", local = TRUE)
source("R/db/queries.R", local = TRUE)
source("R/react_table/react_table_dsl.R", local = TRUE)
source("R/react_table/react_table_auto.R", local = TRUE)
source("R/react_table/html_form_renderer.R", local = TRUE)
source("R/react_table/mod_html_form.R", local = TRUE)
source("R/test_html_form.R", local = TRUE)



run_html_form_test()

