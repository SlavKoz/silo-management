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

# ---- 4. Query table constraints ----
cat("Fetching table constraints...\n")
sql_constraints <- "
SELECT
    tc.TABLE_SCHEMA,
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE,
    kcu.COLUMN_NAME,
    kcu.ORDINAL_POSITION AS ColumnOrder,
    rc.UNIQUE_CONSTRAINT_NAME AS ReferencedConstraint,
    kcu2.TABLE_SCHEMA AS ReferencedSchema,
    kcu2.TABLE_NAME AS ReferencedTable,
    kcu2.COLUMN_NAME AS ReferencedColumn
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
    AND tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    ON tc.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
    AND tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu2
    ON rc.UNIQUE_CONSTRAINT_SCHEMA = kcu2.CONSTRAINT_SCHEMA
    AND rc.UNIQUE_CONSTRAINT_NAME = kcu2.CONSTRAINT_NAME
    AND kcu.ORDINAL_POSITION = kcu2.ORDINAL_POSITION
WHERE tc.TABLE_SCHEMA = 'dbo'
ORDER BY
    tc.TABLE_SCHEMA,
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    kcu.ORDINAL_POSITION;
"

table_constraints <- DBI::dbGetQuery(pool, sql_constraints)

cat("Fetched", nrow(table_constraints), "constraint definitions from",
    length(unique(paste(table_constraints$TABLE_SCHEMA, table_constraints$TABLE_NAME))),
    "tables.\n")

# ---- 5. Save to .claude folder ----
output_folder <- file.path(getwd(), ".claude")
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  cat("Created .claude folder\n")
}
output_file_structures <- file.path(output_folder, "table_structures.csv")
output_file_constraints <- file.path(output_folder, "table_constraints.csv")

# ---- 6. Write to CSV ----
write.csv(table_structures, output_file_structures, row.names = FALSE)
write.csv(table_constraints, output_file_constraints, row.names = FALSE)

cat("Table structures exported to:\n", output_file_structures, "\n")
cat("Table constraints exported to:\n", output_file_constraints, "\n")

# ---- 6. Clean up ----
# Note: Don't close the pool if the app is running - it's shared
# Only close if this is a standalone script execution
if (!exists(".db_pool_env", envir = .GlobalEnv)) {
  cat("Closing database connection...\n")
  pool::poolClose(pool)
} else {
  cat("Keeping pool open (shared with app)...\n")
}
