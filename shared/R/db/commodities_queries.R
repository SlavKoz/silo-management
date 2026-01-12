# R/db/commodities_queries.R
# Simple readers for commodities and grain groups (no write ops)

list_commodities_full <- function(pool = db_pool(), active_only = TRUE, limit = 1000) {
  sql <- "
    SELECT
      CommodityID,
      CommodityCode,
      CommodityName,
      BaseColour,
      ColourName,
      DisplayOrder,
      Notes,
      IsActive,
      IsMajor,
      Icon,
      MissingColour
    FROM dbo.vw_Commodities
    WHERE 1=1
  "

  if (isTRUE(active_only)) {
    sql <- paste0(sql, " AND IsActive = 1")
  }

  sql <- paste0(sql, " ORDER BY ISNULL(DisplayOrder, 9999), CommodityCode")

  if (!is.null(limit)) {
    sql <- paste0(sql, sprintf(" OFFSET 0 ROWS FETCH NEXT %d ROWS ONLY", as.integer(limit)))
  }

  DBI::dbGetQuery(pool, sql)
}

get_commodity <- function(commodity_id, pool = db_pool()) {
  sql <- "
    SELECT
      CommodityID,
      CommodityCode,
      CommodityName,
      BaseColour,
      ColourName,
      DisplayOrder,
      Notes,
      IsActive,
      IsMajor,
      Icon,
      MissingColour
    FROM dbo.vw_Commodities
    WHERE CommodityID = ?
  "
  df <- DBI::dbGetQuery(pool, sql, params = list(as.integer(commodity_id)))
  if (!nrow(df)) return(NULL)
  as.list(df[1, ])
}

update_commodity_attributes <- function(commodity_id,
                                        base_colour = NULL,
                                        colour_name = NULL,
                                        display_order = NULL,
                                        notes = NULL,
                                        is_active = NULL,
                                        is_major = NULL,
                                        icon = NULL,
                                        pool = db_pool()) {
  sql <- "
    UPDATE dbo.CommodityAttributes
      SET BaseColour   = COALESCE(?, BaseColour),
          ColourName   = COALESCE(?, ColourName),
          DisplayOrder = COALESCE(?, DisplayOrder),
          Notes        = COALESCE(?, Notes),
          Icon         = COALESCE(?, Icon)
    WHERE CommodityID = ?;

    UPDATE dbo.Commodities
      SET IsActive = COALESCE(?, IsActive),
          IsMajor  = COALESCE(?, IsMajor)
    WHERE CommodityID = ?;
  "

  # Handle NULL and empty string values for nullable fields
  # Convert NULL to NA for proper SQL NULL handling
  # Also convert empty strings to NA for cleaner database values
  if (is.null(display_order) || (is.character(display_order) && !nzchar(display_order))) display_order <- NA
  if (is.null(icon) || (is.character(icon) && !nzchar(icon))) icon <- NA
  if (is.null(notes) || (is.character(notes) && !nzchar(notes))) notes <- NA
  if (is.null(base_colour) || (is.character(base_colour) && !nzchar(base_colour))) base_colour <- NA
  if (is.null(colour_name) || (is.character(colour_name) && !nzchar(colour_name))) colour_name <- NA

  params <- list(
    base_colour,
    colour_name,
    display_order,
    notes,
    icon,
    as.integer(commodity_id),
    if (is.null(is_active)) NA else as.integer(is_active),
    if (is.null(is_major)) NA else as.integer(is_major),
    as.integer(commodity_id)
  )

  tryCatch({
    DBI::dbExecute(pool, sql, params = params)
    list(success = TRUE, message = "Commodity updated")
  }, error = function(e) {
    list(success = FALSE, message = conditionMessage(e))
  })
}

list_grain_groups_full <- function(pool = db_pool(), active_only = TRUE, commodity_code = NULL, limit = 1000) {
  sql <- "
    SELECT
      GrainGroupID,
      GrainGroupCode,
      GrainGroupName,
      CommodityID,
      CommodityCode,
      CommodityName,
      LightnessModifier,
      ColourName,
      CommodityColourName,
      BaseColour,
      CommodityBaseColour,
      DisplayOrder,
      Notes,
      IsActive,
      MissingColour
    FROM dbo.vw_GrainGroups
    WHERE 1=1
  "
  params <- list()
  if (isTRUE(active_only)) {
    sql <- paste0(sql, " AND IsActive = 1")
  }
  if (!is.null(commodity_code) && nzchar(commodity_code)) {
    sql <- paste0(sql, " AND CommodityCode = ?")
    params <- c(params, list(commodity_code))
  }

  sql <- paste0(sql, " ORDER BY ISNULL(DisplayOrder, 9999), CommodityCode, GrainGroupCode")
  if (!is.null(limit)) {
    sql <- paste0(sql, sprintf(" OFFSET 0 ROWS FETCH NEXT %d ROWS ONLY", as.integer(limit)))
  }

  if (length(params)) {
    DBI::dbGetQuery(pool, sql, params = params)
  } else {
    DBI::dbGetQuery(pool, sql)
  }
}

get_grain_group <- function(grain_group_id, pool = db_pool()) {
  sql <- "
    SELECT
      GrainGroupID,
      GrainGroupCode,
      GrainGroupName,
      CommodityID,
      CommodityCode,
      CommodityName,
      LightnessModifier,
      ColourName,
      CommodityColourName,
      BaseColour,
      CommodityBaseColour,
      DisplayOrder,
      Notes,
      IsActive,
      MissingColour
    FROM dbo.vw_GrainGroups
    WHERE GrainGroupID = ?
  "
  df <- DBI::dbGetQuery(pool, sql, params = list(as.integer(grain_group_id)))
  if (!nrow(df)) return(NULL)
  as.list(df[1, ])
}

update_grain_group_attributes <- function(grain_group_id,
                                          lightness_modifier = NULL,
                                          colour_name = NULL,
                                          display_order = NULL,
                                          notes = NULL,
                                          is_active = NULL,
                                          pool = db_pool()) {
  sql <- "
    UPDATE dbo.GrainGroupAttributes
      SET LightnessModifier = COALESCE(?, LightnessModifier),
          ColourName        = COALESCE(?, ColourName),
          DisplayOrder      = COALESCE(?, DisplayOrder),
          Notes             = COALESCE(?, Notes)
    WHERE GrainGroupID = ?;

    UPDATE dbo.GrainGroups
      SET IsActive = COALESCE(?, IsActive)
    WHERE GrainGroupID = ?;
  "

  # Handle NULL and empty string values for nullable fields
  # Convert NULL to NA for proper SQL NULL handling
  if (is.null(lightness_modifier) || (is.character(lightness_modifier) && !nzchar(lightness_modifier))) lightness_modifier <- NA
  if (is.null(colour_name) || (is.character(colour_name) && !nzchar(colour_name))) colour_name <- NA
  if (is.null(display_order) || (is.character(display_order) && !nzchar(display_order))) display_order <- NA
  if (is.null(notes) || (is.character(notes) && !nzchar(notes))) notes <- NA

  params <- list(
    lightness_modifier,
    colour_name,
    display_order,
    notes,
    as.integer(grain_group_id),
    if (is.null(is_active)) NA else as.integer(is_active),
    as.integer(grain_group_id)
  )

  tryCatch({
    DBI::dbExecute(pool, sql, params = params)
    list(success = TRUE, message = "Grain group updated")
  }, error = function(e) {
    list(success = FALSE, message = conditionMessage(e))
  })
}
