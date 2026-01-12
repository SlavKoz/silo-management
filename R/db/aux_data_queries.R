# R/db/aux_data_queries.R
# Simple read helpers for auxiliary dimension caches

list_crop_years <- function(pool = db_pool(), active_only = TRUE) {
  sql <- "
    SELECT CropYearID, Code, Name, IsActive
    FROM dbo.CropYears
    WHERE 1=1
  "
  params <- list()
  if (active_only) {
    sql <- paste0(sql, " AND IsActive = 1")
  }
  sql <- paste0(sql, " ORDER BY Code")
  DBI::dbGetQuery(pool, sql)
}

list_pools <- function(pool = db_pool(), active_only = TRUE) {
  sql <- "
    SELECT PoolID, PoolCode, PoolName, IsActive
    FROM dbo.Pools
    WHERE 1=1
  "
  if (active_only) {
    sql <- paste0(sql, " AND IsActive = 1")
  }
  sql <- paste0(sql, " ORDER BY PoolCode")
  DBI::dbGetQuery(pool, sql)
}
