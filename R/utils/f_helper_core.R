# f_helper_core.R — minimal core utilities for the new f_* model
# NOTE: We do NOT redefine legacy %||%. We rely on it if present.
# Keep this file tiny; add only things shared by multiple f_* modules.

# --- Safe OR without redefining %||% ---
f_or <- function(x, y) {
  # Prefer legacy %||% if available; otherwise inline check.
  if (exists("%||%", mode = "function", inherits = TRUE)) {
    return(get("%||%", inherits = TRUE)(x, y))
  }
  if (is.null(x) || length(x) == 0) y else x
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
  
  take <- function(vec, names) vec[basename(vec) %in% (names %||% character(0))]
  drop <- function(vec, names) vec[!basename(vec) %in% (names %||% character(0))]
  
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
