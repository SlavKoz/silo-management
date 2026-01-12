## global.R — Silo app bootstrap (with f_-override support)

suppressPackageStartupMessages({
  library(shiny);
  library(bs4Dash);
  library(shinyWidgets);
  library(shinyjs)
  library(shinyalert)
  library(shiny.semantic)
  library(jsonlite);
  library(httr);
  library(xml2);
  library(base64enc)
  library(rsvg)
  library(png)
  library(jpeg)
})

options(shiny.fullstacktrace = TRUE)
options(keep.source = TRUE)
options(shiny.sanitize.errors = FALSE)
options(shiny.error = function() {
  cat("\n--- shiny.error triggered ---\n"); traceback(2)
})

# ------------------- Constants -------------------
ICONIFY_BASE <- "https://api.iconify.design"

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

# 3) Shared React table
source_dir("../shared/R/react_table",
           first = c("react_table_dsl.R", "react_table_helpers.R"),
           last  = c("html_form_renderer.R", "mod_html_form.R", "mod_react_table.R", "react_table_auto.R"))

# 4) Feature modules (legacy + f_* modules)
source_dir("R/browsers")
source_dir("R/canvas")

# Test modules
if (file.exists("R/test_2column_form.R")) source("R/test_2column_form.R", local = globalenv())

# Landing page
if (file.exists("R/f_landing_page.R")) source("R/f_landing_page.R", local = globalenv())

# Search registry
if (file.exists("R/f_search_registry.R")) source("R/f_search_registry.R", local = globalenv())

# 5) App shell (export app_ui/app_server to globalenv)
# f_ app shell
if (file.exists("R/f_app_ui.R"))     source("R/f_app_ui.R",     local = globalenv())
if (file.exists("R/f_app_server.R")) source("R/f_app_server.R", local = globalenv())

# Map to legacy names used by app.R (in case app.R still calls app_ui/app_server)
if (exists("f_app_ui", inherits = TRUE))     assign("app_ui",     f_app_ui,     envir = globalenv())
if (exists("f_app_server", inherits = TRUE)) assign("app_server", f_app_server, envir = globalenv())
