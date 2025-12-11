# R/db/variants_queries.R
# Database queries for Variants

# List variants with optional filtering
list_variants <- function(pool = db_pool(),
                         commodity = NULL,
                         grain_group = NULL,
                         variant_no_like = NULL,
                         active_only = TRUE,
                         missing_pattern = NULL,
                         order_col = "VariantNo",
                         limit = 1000) {

  sql <- "
    SELECT
      VariantID,
      VariantNo,
      GrainGroup,
      Commodity,
      Pattern,
      GrainGroupColour,
      GrainGroupColourName,
      EffectiveColour,
      MissingPattern,
      Notes,
      IsActive
    FROM dbo.vw_Variants
    WHERE 1=1
  "

  params <- list()

  if (active_only) {
    sql <- paste0(sql, " AND IsActive = 1")
  }

  if (!is.null(commodity) && nzchar(commodity)) {
    sql <- paste0(sql, " AND Commodity = ?")
    params <- c(params, list(commodity))
  }

  if (!is.null(grain_group) && nzchar(grain_group)) {
    sql <- paste0(sql, " AND GrainGroup = ?")
    params <- c(params, list(grain_group))
  }

  if (!is.null(variant_no_like) && nzchar(variant_no_like)) {
    sql <- paste0(sql, " AND VariantNo LIKE ?")
    params <- c(params, list(paste0("%", variant_no_like, "%")))
  }

  # Filter by missing Pattern
  if (!is.null(missing_pattern) && missing_pattern == TRUE) {
    sql <- paste0(sql, " AND MissingPattern = 1")
  }

  # Order and limit
  sql <- paste0(sql, sprintf(" ORDER BY %s", order_col))
  if (!is.null(limit)) {
    sql <- paste0(sql, sprintf(" OFFSET 0 ROWS FETCH NEXT %d ROWS ONLY", as.integer(limit)))
  }

  if (length(params) > 0) {
    df <- DBI::dbGetQuery(pool, sql, params = params)
  } else {
    df <- DBI::dbGetQuery(pool, sql)
  }

  df
}

# Get single variant by ID
get_variant <- function(variant_id, pool = db_pool()) {
  sql <- "
    SELECT
      VariantID,
      VariantNo,
      GrainGroup,
      Commodity,
      Pattern,
      GrainGroupColour,
      GrainGroupColourName,
      EffectiveColour,
      Notes,
      IsActive
    FROM dbo.vw_Variants
    WHERE VariantID = ?
  "

  df <- DBI::dbGetQuery(pool, sql, params = list(as.integer(variant_id)))
  if (nrow(df) == 0) return(NULL)
  as.list(df[1, ])
}

# Update variant attributes
update_variant_attributes <- function(variant_id, pattern = NULL, notes = NULL, pool = db_pool()) {
  sql <- "EXEC dbo.sp_UpdateVariantAttributes @VariantID = ?, @Pattern = ?, @Notes = ?"

  params <- list(
    as.integer(variant_id),
    if(is.null(pattern)) NA_character_ else as.character(pattern),
    if(is.null(notes)) NA_character_ else as.character(notes)
  )

  result <- try(DBI::dbExecute(pool, sql, params = params), silent = TRUE)

  if (inherits(result, "try-error")) {
    return(list(success = FALSE, message = conditionMessage(attr(result, "condition"))))
  }

  list(success = TRUE, message = "Variant attributes updated successfully")
}

# Get count of variants without Pattern
count_variants_missing_pattern <- function(pool = db_pool()) {
  sql <- "
    SELECT COUNT(*) AS MissingCount
    FROM dbo.vw_Variants
    WHERE IsActive = 1 AND MissingPattern = 1
  "

  df <- DBI::dbGetQuery(pool, sql)
  df$MissingCount[1]
}

# Get active pattern types for dropdowns (returns named vector: labels = PatternName, values = PatternCode)
list_pattern_types <- function(pool = db_pool()) {
  sql <- "
    SELECT PatternCode, PatternName
    FROM dbo.PatternTypes
    WHERE IsActive = 1
    ORDER BY ISNULL(DisplayOrder, 9999), PatternName
  "

  df <- DBI::dbGetQuery(pool, sql)
  if (!nrow(df)) return(character(0))

  setNames(df$PatternCode, df$PatternName)
}

# Get unique commodities
list_commodities <- function(pool = db_pool()) {
  sql <- "
    SELECT DISTINCT Commodity
    FROM dbo.Variants
    WHERE Commodity IS NOT NULL AND IsActive = 1
    ORDER BY Commodity
  "

  df <- DBI::dbGetQuery(pool, sql)
  df$Commodity
}

# Get unique grain groups
list_grain_groups <- function(pool = db_pool()) {
  sql <- "
    SELECT DISTINCT GrainGroup
    FROM dbo.Variants
    WHERE GrainGroup IS NOT NULL AND IsActive = 1
    ORDER BY GrainGroup
  "

  df <- DBI::dbGetQuery(pool, sql)
  df$GrainGroup
}

# Get grain groups for a specific commodity
list_grain_groups_for_commodity <- function(commodity, pool = db_pool()) {
  # If commodity is NULL or empty, return all grain groups
  if (is.null(commodity) || !nzchar(commodity)) {
    return(list_grain_groups(pool))
  }

  sql <- "
    SELECT DISTINCT GrainGroup
    FROM dbo.Variants
    WHERE Commodity = ? AND IsActive = 1
    ORDER BY GrainGroup
  "

  df <- DBI::dbGetQuery(pool, sql, params = list(commodity))
  df$GrainGroup
}

# Sync variants from Franklin
sync_variants_from_franklin <- function(pool = db_pool()) {
  sql <- "EXEC dbo.sp_SyncVariantsFromFranklin"

  result <- try(DBI::dbGetQuery(pool, sql), silent = TRUE)

  if (inherits(result, "try-error")) {
    return(list(success = FALSE, message = conditionMessage(attr(result, "condition"))))
  }

  list(success = TRUE, message = "Variants synced successfully from Franklin")
}
