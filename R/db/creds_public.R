# Silo/R/db/creds_public.R
# Public DB config (no password). Safe to commit/share.
# Password is injected by connect_wrappers.R from ../secrets/db_password.R or env.

get_public_db_config <- function() {
  list(
    driver   = "ODBC Driver 17 for SQL Server",  # or "{ODBC Driver 18 for SQL Server}"
    server   = "sql.camgrain.co.uk",
    database = "SiloOps",
    uid      = "queryuser",
    port     = 1433,
    encrypt  = "yes",
    trust_server_certificate = "yes",
    timeout  = 10
    # NO password field here
  )
}
