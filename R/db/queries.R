# R/db/queries.R
# Minimal, SAFE (parameterized) queries for browsers

# ---- Allowed columns (for ORDER BY whitelisting) ----
.ALLOWED_SILOS_COLS <- c("SiloID","SiloCode","SiloName","Area","ContainerTypeID",
                         "VolumeM3","AllowMixedVariants","IsActive","CreatedAt","UpdatedAt")
.ALLOWED_PLACEMENTS_COLS <- c("PlacementID","SiloID","LayoutID","ShapeTemplateID","CenterX",
                              "CenterY","ZIndex","IsVisible","IsInteractive","CreatedAt")
.ALLOWED_SHAPES_COLS <- c("ShapeTemplateID","TemplateCode","ShapeType","Radius",
                          "Width","Height","RotationDeg")
.ALLOWED_CONTAINER_TYPES_COLS <- c(
  "ContainerTypeID","TypeCode","TypeName","Description",
  "CreatedAt","UpdatedAt","DefaultFill","DefaultBorder","DefaultBorderPx","BottomType","Icon"
)

# ---- Silos ---------------------------------------------------------------

# List silos with optional filters + pagination
list_silos <- function(area = NULL,
                       code_like = NULL,
                       active = NULL,
                       ids = NULL,
                       order_col = "SiloCode",
                       order_dir = "ASC",
                       limit = 200,
                       offset = 0) {
  
  ob <- safe_order_by(order_col, order_dir, .ALLOWED_SILOS_COLS)
  
  where <- c(); params <- list()
  
  if (!is.null(area))        { where <- c(where, "Area = ?");        params <- c(params, list(area)) }
  if (!is.null(active))      { where <- c(where, "IsActive = ?");    params <- c(params, list(as.logical(active))) }
  if (!is.null(code_like))   { where <- c(where, "SiloCode LIKE ?"); params <- c(params, list(code_like)) } # e.g. "%CG-%"
  if (!is.null(ids) && length(ids)) {
    IN <- sql_in(ids); where <- c(where, paste("SiloID", IN$clause)); params <- c(params, IN$params)
  }
  where_sql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
  
  sql <- sprintf("
    SELECT SiloID, SiloCode, SiloName, Area, ContainerTypeID,
           VolumeM3, AllowMixedVariants, IsActive, CreatedAt, UpdatedAt
    FROM SiloOps.dbo.Silos
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)
  
  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_silo_by_id <- function(silo_id) {
  db_query_params("
    SELECT SiloID, SiloCode, SiloName, Area, ContainerTypeID,
           VolumeM3, AllowMixedVariants, IsActive, CreatedAt, UpdatedAt
    FROM SiloOps.dbo.Silos
    WHERE SiloID = ?
  ", list(as.integer(silo_id)))
}

# ---- Placements ----------------------------------------------------------

list_placements <- function(layout_id = NULL,
                            silo_id = NULL,
                            visible = NULL,
                            order_col = "PlacementID",
                            order_dir = "ASC",
                            limit = 200,
                            offset = 0) {
  
  ob <- safe_order_by(order_col, order_dir, .ALLOWED_PLACEMENTS_COLS)
  
  where <- c(); params <- list()
  if (!is.null(layout_id)) { where <- c(where, "LayoutID = ?");    params <- c(params, list(as.integer(layout_id))) }
  if (!is.null(silo_id))   { where <- c(where, "SiloID = ?");      params <- c(params, list(as.integer(silo_id))) }
  if (!is.null(visible))   { where <- c(where, "IsVisible = ?");   params <- c(params, list(as.logical(visible))) }
  
  where_sql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
  
  sql <- sprintf("
    SELECT PlacementID, SiloID, LayoutID, ShapeTemplateID, CenterX, CenterY,
           ZIndex, IsVisible, IsInteractive, CreatedAt
    FROM SiloOps.dbo.SiloPlacements
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)
  
  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_placement_by_id <- function(placement_id) {
  db_query_params("
    SELECT PlacementID, SiloID, LayoutID, ShapeTemplateID, CenterX, CenterY,
           ZIndex, IsVisible, IsInteractive, CreatedAt
    FROM SiloOps.dbo.SiloPlacements
    WHERE PlacementID = ?
  ", list(as.integer(placement_id)))
}

# ---- Shape templates (for browsers / pickers) ---------------------------

list_shape_templates <- function(shape_type = NULL,
                                 code_like = NULL,
                                 order_col = "TemplateCode",
                                 order_dir = "ASC",
                                 limit = 200,
                                 offset = 0) {
  
  ob <- safe_order_by(order_col, order_dir, .ALLOWED_SHAPES_COLS)
  
  where <- c(); params <- list()
  if (!is.null(shape_type)) { where <- c(where, "ShapeType = ?");   params <- c(params, list(shape_type)) }
  if (!is.null(code_like))  { where <- c(where, "TemplateCode LIKE ?"); params <- c(params, list(code_like)) }
  
  where_sql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
  
  sql <- sprintf("
    SELECT ShapeTemplateID, TemplateCode, ShapeType, Radius, Width, Height, RotationDeg
    FROM SiloOps.dbo.ShapeTemplates
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)
  
  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_shape_by_id <- function(shape_template_id) {
  db_query_params("
    SELECT ShapeTemplateID, TemplateCode, ShapeType, Radius, Width, Height, RotationDeg
    FROM SiloOps.dbo.ShapeTemplates
    WHERE ShapeTemplateID = ?
  ", list(as.integer(shape_template_id)))
}



# ---- Container Types -------------------------------------------------------

# List for selector/table
list_container_types <- function(code_like = NULL,
                                 order_col = "TypeCode",
                                 order_dir = "ASC",
                                 limit = 500,
                                 offset = 0) {
  ob <- safe_order_by(order_col, order_dir, .ALLOWED_CONTAINER_TYPES_COLS)
  
  where <- c(); params <- list()
  if (!is.null(code_like)) { where <- c(where, "TypeCode LIKE ?"); params <- c(params, list(code_like)) }
  where_sql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
  
  # NOTE: Icon column is virtual for now (see browser module); DB does not have it yet.
  sql <- sprintf("
    SELECT
      ContainerTypeID, TypeCode, TypeName, Description,
      CreatedAt, UpdatedAt,
      DefaultFill, DefaultBorder, DefaultBorderPx,
      BottomType,
      CAST(NULL AS nvarchar(30)) AS Icon   -- placeholder until DB migration
    FROM SiloOps.dbo.ContainerTypes
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)
  
  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_container_type_by_id <- function(id) {
  db_query_params("
    SELECT
      ContainerTypeID, TypeCode, TypeName, Description,
      CreatedAt, UpdatedAt,
      DefaultFill, DefaultBorder, DefaultBorderPx,
      BottomType,
      CAST(NULL AS nvarchar(30)) AS Icon
    FROM SiloOps.dbo.ContainerTypes
    WHERE ContainerTypeID = ?
  ", list(as.integer(id)))
}

# Delete guard checks (for later wiring)
# 1) Silos referencing this type (if there's a FK/column)
count_silos_with_type <- function(container_type_id) {
  # if schema uses ContainerTypeID in Silos; adjust if different
  db_query_params("
    SELECT COUNT(*) AS n
    FROM SiloOps.dbo.Silos
    WHERE ContainerTypeID = ?
  ", list(as.integer(container_type_id)))$n[1] %||% 0L
}

# 2) Operations referencing this type
count_operations_for_type <- function(container_type_id) {
  db_query_params("
    SELECT COUNT(*) AS n
    FROM SiloOps.dbo.ContainerTypeOperations
    WHERE ContainerTypeID = ?
  ", list(as.integer(container_type_id)))$n[1] %||% 0L
}


# ---- Utility: safe LIKE builder (use with code_like params) -------------
like_contains <- function(x) sprintf("%%%s%%", x)
like_prefix   <- function(x) sprintf("%s%%", x)
like_suffix   <- function(x) sprintf("%%%s", x)


# R/db/icons_queries.R
# Expect a table, e.g., dbo.Icons (Id int identity pk, Display nvarchar(100), ColorHex char(7), Svg nvarchar(max), Png32 varbinary(max), Png64 varbinary(max), CreatedAt)
# Adjust names to match your schema.

icons_lib_list <- function(conn) {
  DBI::dbGetQuery(conn, "
    SELECT Id AS id, Display AS display, ColorHex AS color_hex,
           CONVERT(varchar(max), CAST(N'' as xml).value('xs:base64Binary(sql:column(\"Png64\"))', 'varchar(max)')) AS png_64_b64
    FROM dbo.Icons
    ORDER BY Id DESC
  ")
}

icons_lib_insert <- function(conn, display, svg, png_32_b64, png_64_b64, color_hex) {
  # decode base64 → varbinary
  png32 <- base64enc::base64decode(png_32_b64)
  png64 <- base64enc::base64decode(png_64_b64)
  q <- "INSERT INTO dbo.Icons (Display, ColorHex, Svg, Png32, Png64, CreatedAt)
        VALUES (?, ?, ?, ?, ?, SYSUTCDATETIME())"
  DBI::dbExecute(conn, q, params = list(display, color_hex, svg, DBI::dbBlob(png32), DBI::dbBlob(png64)))
}

icons_lib_delete <- function(conn, ids) {
  if (!length(ids)) return(invisible(TRUE))
  ids <- as.integer(ids)
  q <- sprintf("DELETE FROM dbo.Icons WHERE Id IN (%s)", paste(ids, collapse = ","))
  DBI::dbExecute(conn, q)
}

