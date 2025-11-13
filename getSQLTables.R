# ================================
# Script: getSQLTables.R
# Purpose: Export all SQL Server table structures to a CSV file
# Uses existing database connection from the Silo app
# ================================

library(DBI)
library(odbc)
library(pool)

# ---- 1. Load existing database connection helpers ----
# Load helper to get f_or function
if (file.exists("R/utils/f_helper_core.R")) {
  source("R/utils/f_helper_core.R", local = TRUE)
}

# Load database credentials and connection wrappers
if (file.exists("R/db/creds_public.R")) {
  source("R/db/creds_public.R", local = TRUE)
}
if (file.exists("R/db/connect_wrappers.R")) {
  source("R/db/connect_wrappers.R", local = TRUE)
}

# ---- 2. Get connection from existing pool ----
cat("Connecting to database using existing configuration...\n")
pool <- db_pool()

# ---- 3. Query table structures ----
cat("Fetching table structures...\n")
sql_struct <- "
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    ORDINAL_POSITION      AS ColumnOrder,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME,
    ORDINAL_POSITION;
"

table_structures <- DBI::dbGetQuery(pool, sql_struct)

cat("Fetched", nrow(table_structures), "column definitions from",
    length(unique(paste(table_structures$TABLE_SCHEMA, table_structures$TABLE_NAME))),
    "tables.\n")

# ---- 4. Use the directory the script is run from ----
output_folder <- getwd()
output_file   <- file.path(output_folder, "table_structures.csv")

# ---- 5. Write to CSV ----
write.csv(table_structures, output_file, row.names = FALSE)

cat("Table structures exported to:\n", output_file, "\n")

# ---- 6. Clean up ----
# Note: Don't close the pool if the app is running - it's shared
# Only close if this is a standalone script execution
if (!exists(".db_pool_env", envir = .GlobalEnv)) {
  cat("Closing database connection...\n")
  pool::poolClose(pool)
} else {
  cat("Keeping pool open (shared with app)...\n")
}
