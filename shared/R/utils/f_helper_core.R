# f_helper_core.R — Core utilities
# Consolidated from helper_core.R and f_helper_core.R

# --- Safe OR (unified replacement for %||%) ---
f_or <- function(x, y) {
  if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x
}

f_is_empty <- function(x) is.null(x) || length(x) == 0 || (is.character(x) && !nzchar(x[1]))

# --- Namespacing helpers ---
# Wrap NS() for consistency in f_* modules (mostly readability)
f_ns <- function(id) shiny::NS(id)

# Return the *module instance id* prefix (e.g., "icons", "containers")
# Useful for building DOM ids or logs from inside server module.
f_module_id <- function(session) {
  stopifnot(!is.null(session) && inherits(session, "ShinySession"))
  # session$ns("") returns "icons-" style prefix; trim trailing dash.
  sub("-$", "", session$ns(""))
}

# --- Notifications (tiny façade) ---
f_notify <- function(msg, type = c("default","message","warning","error"), duration = 3) {
  type <- match.arg(type)
  shiny::showNotification(msg, type = if (type == "default") NULL else type, duration = duration)
}

# --- Try/catch helper with default result ---
f_try <- function(expr, default = NULL, quiet = TRUE) {
  out <- try(force(expr), silent = quiet)
  if (inherits(out, "try-error")) default else out
}

# --- Simple predicates ---
f_is_empty <- function(x) is.null(x) || length(x) == 0 || (is.character(x) && !nzchar(x))
f_has_pkg  <- function(pkg) requireNamespace(pkg, quietly = TRUE)

# --- Clip numeric to range (useful for UI sizes/limits) ---
f_clip <- function(x, lo = -Inf, hi = Inf) pmax(lo, pmin(hi, x))

# --- Optional: f_-aware source_dir (same semantics as in global, but callable elsewhere) ---
# Only use if you need to load a sub-tree from inside another f_* file.
f_source_dir <- function(path, pattern = "\\.R$", recursive = FALSE, first = NULL, last = NULL, env = parent.frame()) {
  if (!dir.exists(path)) return(invisible())
  files <- list.files(path, pattern = pattern, full.names = TRUE, recursive = recursive)
  if (!length(files)) return(invisible())
  
  # Separate legacy vs f_* so f_* load last.
  base <- files[!grepl("(^|/|\\\\)f_.*\\.R$", files)]
  fres <- setdiff(files, base)
  
  take <- function(vec, names) vec[basename(vec) %in% f_or(names, character(0))]
  drop <- function(vec, names) vec[!basename(vec) %in% f_or(names, character(0))]
  
  head <- take(base, first)
  tail <- take(base, last)
  mid  <- drop(base, c(first, last))
  ordered_base <- c(head, sort(mid), tail)
  ordered_f    <- sort(fres)
  
  for (f in c(ordered_base, ordered_f)) sys.source(f, envir = env)
  invisible(NULL)
}

f_scoped_css <- function(ns_id, rules_vec) {
  sel <- function(s) paste0("#", ns_id, " ", s)
  css <- paste0(vapply(rules_vec, function(r) {
    # r is like c(".class{...}", ".a,.b{...}") without the leading scope
    paste0(sel(""), r)
  }, character(1)), collapse = "")
  tags$style(HTML(css))
}

# --- UI helper: simple Semantic search dropdown (global search) ---
# Provides a consistent fallback if shiny.semantic helpers change.
search_selection_choices <- function(input_id,
                                     choices,
                                     groups = NULL,
                                     multiple = FALSE,
                                     default_text = "Search...") {
  # shiny.semantic binding keeps Shiny inputs in sync
  type <- if (multiple) "multiple selection fluid search" else "selection fluid search"

  # Grouping not natively supported by shiny.semantic dropdown_input; flatten for now
  sem_choices <- choices
  if (!is.null(groups) && length(groups) == length(choices)) {
    sem_choices <- unname(choices)
  }

  shiny.semantic::dropdown_input(
    input_id = input_id,
    choices = sem_choices,
    choices_value = choices,
    value = "",
    type = type
  )
}

# ==============================================================================
# UNUSED FUNCTIONS (from helper_core.R - commented out as not used anywhere)
# ==============================================================================

# who_defined <- function(name) {
#   stopifnot(is.character(name), length(name) == 1)
#   where <- find(name)
#   cat("Found in:", paste(where, collapse = " | "), "\n")
#   obj <- getAnywhere(name)
#   if (length(obj$objs) >= 1) {
#     f <- obj$objs[[1]]
#     env <- environment(f)
#     cat("Environment:", environmentName(env), "\n")
#     fn <- try(utils::getSrcFilename(f, full.names = TRUE), silent = TRUE)
#     ln <- try(utils::getSrcLocation(f), silent = TRUE)
#     if (!inherits(fn, "try-error") && !is.na(fn)) cat("File:", fn, "\n")
#     if (!inherits(ln, "try-error")) cat("Line:", paste(ln, collapse = ","), "\n")
#   }
#   invisible(where)
# }
