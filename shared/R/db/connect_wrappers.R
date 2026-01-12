# Silo/R/db/connect_wrappers.R
# Loads public config from Silo, injects password from ../secrets/db_password.R or env,
# and creates a pooled ODBC connection. Always parameterize SQL in callers.

suppressPackageStartupMessages({
  library(DBI)
  library(pool)
  library(odbc)
})

# ---- Load public (no-password) config from inside Silo ----
# This file should be in the same directory, so just source it relatively
if (!exists("get_public_db_config")) {
  source("creds_public.R", local = TRUE)
}

# ---- Load password from outside Silo (preferred), fallback to env ----
# Expected file: ../secrets/db_password.R  exporting get_db_password()
# .get_password <- function() {
#   secrets_path <- file.path("..", "secrets", "db_password.R")
#   if (file.exists(secrets_path)) {
#     env <- new.env(parent = emptyenv())
#     sys.source(secrets_path, envir = env)
#     if (exists("get_db_password", envir = env, mode = "function")) {
#       pw <- try(env$get_db_password(), silent = TRUE)
#       if (!inherits(pw, "try-error") && is.character(pw) && nzchar(pw)) {
#         return(pw)
#       }
#     }
#     warning("[DB] ../secrets/db_password.R present but get_db_password() returned nothing; falling back to env.", call. = FALSE)
#   }
#   # Fallback: environment variable
#   pw <- Sys.getenv("MSSQL_PWD", "")
#   if (!nzchar(pw)) stop("[DB] No password found. Provide ../secrets/db_password.R or set MSSQL_PWD.", call. = FALSE)
#   pw
# }


# ---- Load password from outside Silo (preferred), fallback to env ----
.read_pw_file <- function(path) {
  if (!file.exists(path)) return(NULL)
  # Read first non-empty line, trim whitespace and BOM
  ln <- try(readLines(path, warn = FALSE, n = 1, encoding = "UTF-8"), silent = TRUE)
  if (inherits(ln, "try-error") || !length(ln)) return(NULL)
  pw <- sub("^\ufeff", "", ln[[1]])   # strip UTF-8 BOM if present
  pw <- trimws(pw)
  if (!nzchar(pw)) return(NULL)
  pw
}

.get_password <- function() {
  # 1) Plain text file: ../../secrets/db_password.txt (up to Silo, then to MyRProjects, then secrets)
  pw <- .read_pw_file(file.path("..", "..", "secrets", "db_password.txt"))
  if (nzchar(pw)) return(pw)

  # 2) Back-compat: ../../secrets/db_password.R exporting get_db_password()
  rpath <- file.path("..", "..", "secrets", "db_password.R")
  if (file.exists(rpath)) {
    env <- new.env(parent = emptyenv())
    ok <- try(sys.source(rpath, envir = env), silent = TRUE)
    if (!inherits(ok, "try-error") && exists("get_db_password", envir = env, mode = "function")) {
      pw <- try(env$get_db_password(), silent = TRUE)
      if (!inherits(pw, "try-error") && is.character(pw) && nzchar(pw)) return(pw)
    }
    # As a last resort, try to treat the .R file as plain text (first line)
    pw <- .read_pw_file(rpath)
    if (nzchar(pw)) return(pw)
  }
  
  # 3) Environment variable fallback
  pw <- Sys.getenv("MSSQL_PWD", "")
  if (nzchar(pw)) return(pw)
  
  stop("[DB] No password found. Expected ../../secrets/db_password.txt (preferred), \
or a valid ../../secrets/db_password.R exporting get_db_password(), or env var MSSQL_PWD.", call. = FALSE)
}


# ---- Build merged config (public + password) ----
get_db_config <- function() {
  pub <- get_public_db_config()
  pwd <- .get_password()
  c(pub, list(pwd = pwd))
}

# ---- Memoized pool ----
.db_pool_env <- new.env(parent = emptyenv()); .db_pool_env$pool <- NULL

db_pool <- function() {
  if (!is.null(.db_pool_env$pool) && inherits(.db_pool_env$pool, "Pool")) return(.db_pool_env$pool)
  cfg <- get_db_config()
  p <- pool::dbPool(
    drv      = odbc::odbc(),
    Driver   = cfg$driver,
    Server   = cfg$server,
    Database = cfg$database,
    UID      = cfg$uid,
    PWD      = cfg$pwd,
    Port     = f_or(cfg$port, 1433),
    Encrypt  = f_or(cfg$encrypt, "yes"),
    TrustServerCertificate = f_or(cfg$trust_server_certificate, "yes"),
    timeout  = f_or(cfg$timeout, 10)
  )
  .db_pool_env$pool <- p
  p
}

# ---- Safe helpers (parameterized queries only) ----
db_query_params <- function(sql, params) {
  stopifnot(is.character(sql), length(sql) == 1)
  q_count <- lengths(regmatches(sql, gregexpr("\\?", sql, perl = TRUE)))
  if (q_count != length(params)) {
    stop(sprintf("Parameter count mismatch: %d placeholders vs %d params.", q_count, length(params)))
  }
  DBI::dbGetQuery(db_pool(), sql, params = params)
}

db_execute_params <- function(sql, params) {
  stopifnot(is.character(sql), length(sql) == 1)
  q_count <- lengths(regmatches(sql, gregexpr("\\?", sql, perl = TRUE)))
  if (q_count != length(params)) {
    stop(sprintf("Parameter count mismatch: %d placeholders vs %d params.", q_count, length(params)))
  }
  DBI::dbExecute(db_pool(), sql, params = params)
}

sql_in <- function(vec) {
  if (length(vec) == 0) return(list(clause = "IN (NULL)", params = list()))
  ph <- paste(rep("?", length(vec)), collapse = ",")
  list(clause = sprintf("IN (%s)", ph), params = as.list(vec))
}

safe_order_by <- function(column, direction = "ASC", allowed_cols) {
  conn <- db_pool()
  dir <- toupper(direction)
  if (!dir %in% c("ASC", "DESC")) dir <- "ASC"
  if (!column %in% allowed_cols) stop(sprintf("Disallowed ORDER BY column: %s", column))
  paste("ORDER BY", DBI::dbQuoteIdentifier(conn, column), dir)
}

db_pool_close <- function() {
  if (!is.null(.db_pool_env$pool)) {
    try(pool::poolClose(.db_pool_env$pool), silent = TRUE)
    .db_pool_env$pool <- NULL
  }
}

db_alive <- function() {
  p <- try(db_pool(), silent = TRUE)
  if (inherits(p, "try-error")) return(FALSE)
  isTRUE(try(DBI::dbIsValid(p), silent = TRUE))
}
