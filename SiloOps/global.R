# SiloOps/global.R
# Global configuration and dependencies for Silo Operations

suppressPackageStartupMessages({
  library(shiny)
  library(shiny.semantic)
  library(DBI)
  library(pool)
  library(shinyjs)
  library(odbc)
})

# ------------------- deterministic loader (f_ overrides last) -------------------
source_dir <- function(path, pattern = "\\.R$", recursive = FALSE,
                       first = NULL, last = NULL, env = globalenv()) {
  if (!dir.exists(path)) return(invisible())

  files <- list.files(path, pattern = pattern, full.names = TRUE, recursive = recursive)
  if (!length(files)) return(invisible())

  # Normalize slashes for the regex to work on all OSes
  norm <- function(x) gsub("\\\\", "/", x)

  files_n <- norm(files)
  # legacy vs f_* (match file names beginning with f_ in any subdir)
  is_f <- grepl("(^|/)f_[^/]*\\.R$", files_n)

  base_files <- files[!is_f]
  f_files    <- files[is_f]

  take <- function(vec, names) {
    if (is.null(names) || !length(names)) return(character(0))
    vec[basename(vec) %in% names]
  }
  drop <- function(vec, names) {
    if (is.null(names) || !length(names)) return(vec)
    vec[!basename(vec) %in% names]
  }

  head <- take(base_files, first)
  tail <- take(base_files, last)
  mid  <- drop(base_files, c(first, last))

  ordered <- c(head, sort(mid), tail, sort(f_files))  # f_* always last
  for (f in ordered) source(f, local = env)
  invisible(NULL)
}

# ----------------------------- Load order ---------------------------------------
# 1) Shared utils (core first; f_* helpers will load automatically after legacy ones)
source_dir("../shared/R/utils", first = c("helper_core.R"))

# 2) Shared DB (credentials/wrappers before queries; f_* overrides load last automatically)
source_dir("../shared/R/db", first = c("creds_public.R", "connect_wrappers.R"), last = c("queries.R"))

# 3) Shared React table (will be needed for operations forms)
source_dir("../shared/R/react_table",
           first = c("react_table_dsl.R", "react_table_helpers.R"),
           last  = c("html_form_renderer.R", "mod_html_form.R", "mod_react_table.R", "react_table_auto.R"))

# 4) Load app-specific modules
source("R/f_landing_page.R", local = globalenv())
source("R/f_app_ui.R", local = globalenv())
source("R/f_app_server.R", local = globalenv())

# Note: Database connection pool is provided by ../shared/R/db/connect_wrappers.R
# The db_pool() function is available globally
