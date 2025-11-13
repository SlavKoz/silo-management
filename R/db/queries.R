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
    SELECT ShapeTemplateID, TemplateCode, ShapeType, Radius, Width, Height, RotationDeg,
           DefaultFill, DefaultBorder, DefaultBorderPx, Notes
    FROM SiloOps.dbo.ShapeTemplates
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)

  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_shape_template_by_id <- function(shape_template_id) {
  db_query_params("
    SELECT ShapeTemplateID, TemplateCode, ShapeType, Radius, Width, Height, RotationDeg,
           DefaultFill, DefaultBorder, DefaultBorderPx, Notes
    FROM SiloOps.dbo.ShapeTemplates
    WHERE ShapeTemplateID = ?
  ", list(as.integer(shape_template_id)))
}

# Save (upsert) shape template
# If id is NULL or 0, creates new; otherwise updates existing
upsert_shape_template <- function(data) {
  # Extract ID (NULL or 0 means new record)
  id <- f_or(data$ShapeTemplateID, 0)
  is_new <- is.null(id) || id == 0 || id == ""

  # Determine which geometry fields to use based on ShapeType
  shape_type <- f_or(data$ShapeType, "CIRCLE")

  if (is_new) {
    # INSERT new record
    sql <- "
      INSERT INTO SiloOps.dbo.ShapeTemplates (
        TemplateCode, ShapeType, Radius, Width, Height, RotationDeg,
        DefaultFill, DefaultBorder, DefaultBorderPx, Notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      SELECT SCOPE_IDENTITY() AS NewID;
    "
    params <- list(
      as.character(f_or(data$TemplateCode, "")),
      as.character(shape_type),
      if (shape_type %in% c("CIRCLE", "TRIANGLE")) {
        val <- data$Geometry$Radius
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      if (shape_type == "RECTANGLE") {
        val <- data$Geometry$Width
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      if (shape_type == "RECTANGLE") {
        val <- data$Geometry$Height
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      as.numeric(f_or(data$Geometry$RotationDeg, 0)),
      as.character(f_or(data$Graphics$DefaultFill, "#FFFFFF")),
      as.character(f_or(data$Graphics$DefaultBorder, "#000000")),
      as.numeric(f_or(data$Graphics$DefaultBorderPx, 1)),
      as.character(f_or(data$Notes, ""))
    )

    result <- db_query_params(sql, params)
    return(if (nrow(result) > 0) as.integer(result$NewID[1]) else NULL)

  } else {
    # UPDATE existing record
    sql <- "
      UPDATE SiloOps.dbo.ShapeTemplates
      SET TemplateCode = ?,
          ShapeType = ?,
          Radius = ?,
          Width = ?,
          Height = ?,
          RotationDeg = ?,
          DefaultFill = ?,
          DefaultBorder = ?,
          DefaultBorderPx = ?,
          Notes = ?
      WHERE ShapeTemplateID = ?
    "
    params <- list(
      as.character(f_or(data$TemplateCode, "")),
      as.character(shape_type),
      if (shape_type %in% c("CIRCLE", "TRIANGLE")) {
        val <- data$Geometry$Radius
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      if (shape_type == "RECTANGLE") {
        val <- data$Geometry$Width
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      if (shape_type == "RECTANGLE") {
        val <- data$Geometry$Height
        if (is.null(val) || is.na(val) || val == "") NA_real_ else as.numeric(val)
      } else NA_real_,
      as.numeric(f_or(data$Geometry$RotationDeg, 0)),
      as.character(f_or(data$Graphics$DefaultFill, "#FFFFFF")),
      as.character(f_or(data$Graphics$DefaultBorder, "#000000")),
      as.numeric(f_or(data$Graphics$DefaultBorderPx, 1)),
      as.character(f_or(data$Notes, "")),
      as.integer(id)
    )

    db_query_params(sql, params)
    return(as.integer(id))
  }
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
  
  sql <- sprintf("
    SELECT
      ct.ContainerTypeID, ct.TypeCode, ct.TypeName, ct.Description,
      ct.CreatedAt, ct.UpdatedAt,
      ct.DefaultFill, ct.DefaultBorder, ct.DefaultBorderPx,
      ct.BottomType,
      ct.Icon,
      -- Get icon image as base64 string
      CAST('' AS xml).value('xs:base64Binary(sql:column(\"png_32_b64\"))', 'varchar(max)') AS IconImage
    FROM SiloOps.dbo.ContainerTypes ct
    LEFT JOIN SiloOps.dbo.Icons i ON ct.Icon = i.id
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
      Icon
    FROM SiloOps.dbo.ContainerTypes
    WHERE ContainerTypeID = ?
  ", list(as.integer(id)))
}

# Save (upsert) container type
# If id is NULL or 0, creates new; otherwise updates existing
upsert_container_type <- function(data) {
  # Extract ID (NULL or 0 means new record)
  id <- f_or(data$ContainerTypeID, 0)
  is_new <- is.null(id) || id == 0 || id == ""

  if (is_new) {
    # INSERT new record
    sql <- "
      INSERT INTO SiloOps.dbo.ContainerTypes (
        TypeCode, TypeName, Description,
        DefaultFill, DefaultBorder, DefaultBorderPx,
        BottomType, Icon, CreatedAt, UpdatedAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), GETDATE());
      SELECT SCOPE_IDENTITY() AS NewID;
    "
    params <- list(
      as.character(f_or(data$TypeCode, "")),
      as.character(f_or(data$TypeName, "")),
      as.character(f_or(data$Description, "")),
      as.character(f_or(data$Graphics$DefaultFill, "#cccccc")),
      as.character(f_or(data$Graphics$DefaultBorder, "#333333")),
      as.numeric(f_or(data$Graphics$DefaultBorderPx, 1)),
      as.character(f_or(data$BottomType, "FLAT")),
      if (!is.null(data$IconID) && nzchar(data$IconID)) as.integer(data$IconID) else NULL
    )

    result <- db_query_params(sql, params)
    return(if (nrow(result) > 0) as.integer(result$NewID[1]) else NULL)

  } else {
    # UPDATE existing record
    sql <- "
      UPDATE SiloOps.dbo.ContainerTypes
      SET TypeCode = ?,
          TypeName = ?,
          Description = ?,
          DefaultFill = ?,
          DefaultBorder = ?,
          DefaultBorderPx = ?,
          BottomType = ?,
          Icon = ?,
          UpdatedAt = GETDATE()
      WHERE ContainerTypeID = ?
    "
    params <- list(
      as.character(f_or(data$TypeCode, "")),
      as.character(f_or(data$TypeName, "")),
      as.character(f_or(data$Description, "")),
      as.character(f_or(data$Graphics$DefaultFill, "#cccccc")),
      as.character(f_or(data$Graphics$DefaultBorder, "#333333")),
      as.numeric(f_or(data$Graphics$DefaultBorderPx, 1)),
      as.character(f_or(data$BottomType, "FLAT")),
      if (!is.null(data$IconID) && nzchar(data$IconID)) as.integer(data$IconID) else NULL,
      as.integer(id)
    )

    db_execute_params(sql, params)
    return(as.integer(id))
  }
}

# Get icons for picker (display names with optional thumbnails)
# list_icons_for_picker <- function(limit = 1000) {
#   db_query_params("
#     SELECT TOP (?)
#       id,
#       icon_name,
#       CAST(png_32_b64 AS VARCHAR(MAX)) AS png_32_b64
#     FROM SiloOps.dbo.Icons
#     ORDER BY icon_name
#   ", list(as.integer(limit)))
# }

# R/db/queries.R (or where list_icons_for_picker() lives)
list_icons_for_picker <- function(limit = 1000) {
  db_query_params("
    SELECT TOP (?)
      id,
      icon_name,
      -- Convert VARBINARY(MAX) -> base64 string (no prefix)
      CAST('' AS xml).value('xs:base64Binary(sql:column(\"png_32_b64\"))', 'varchar(max)') AS png_32_b64,
      svg,
      primary_color
    FROM dbo.Icons
    ORDER BY icon_name
  ", list(as.integer(limit)))
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

# ---- Icon Browser Wrappers ----
# These functions match the interface expected by f_browser_icons.R

# Check if Icons table exists and has correct schema
check_icons_table <- function(conn) {
  # Check if table exists
  table_check <- tryCatch({
    DBI::dbGetQuery(conn, "
      SELECT OBJECT_ID('Icons', 'U') AS table_id
    ")
  }, error = function(e) NULL)

  if (is.null(table_check) || is.na(table_check$table_id[1])) {
    return(list(exists = FALSE, message = "Icons table does not exist"))
  }

  # Check column definitions
  cols <- tryCatch({
    DBI::dbGetQuery(conn, "
      SELECT
        c.name AS column_name,
        t.name AS data_type,
        c.max_length
      FROM sys.columns c
      JOIN sys.types t ON c.user_type_id = t.user_type_id
      WHERE c.object_id = OBJECT_ID('Icons')
    ")
  }, error = function(e) NULL)

  if (is.null(cols) || nrow(cols) == 0) {
    return(list(exists = FALSE, message = "Could not read Icons table schema"))
  }

  # Check for svg column and its size
  svg_col <- cols[cols$column_name == "svg", ]
  if (nrow(svg_col) == 0) {
    return(list(exists = FALSE, message = "Icons table missing 'svg' column"))
  }

  # Check if svg is nvarchar(max) (max_length = -1)
  if (svg_col$data_type != "nvarchar" || svg_col$max_length != -1) {
    return(list(
      exists = TRUE,
      needs_fix = TRUE,
      message = sprintf("SVG column is %s(%s) but should be nvarchar(max)",
                       svg_col$data_type,
                       if(svg_col$max_length == -1) "max" else as.character(svg_col$max_length))
    ))
  }

  return(list(exists = TRUE, needs_fix = FALSE, message = "Icons table schema is correct"))
}

# Fetch all icons for library display
fetch_icons <- function(conn) {
  sql <- "
    SELECT
      id,
      icon_name,
      primary_color,
      svg,
      png_32_b64
    FROM Icons
    ORDER BY id DESC
  "

  df <- DBI::dbGetQuery(conn, sql)

  # Convert varbinary to base64 in R (more reliable than SQL)
  if (nrow(df) > 0 && "png_32_b64" %in% names(df)) {
    df$png_32_b64 <- sapply(df$png_32_b64, function(x) {
      if (is.null(x) || length(x) == 0) return("")
      if (is.list(x)) x <- x[[1]]  # Unwrap if it's a list
      if (is.raw(x)) {
        base64enc::base64encode(x)
      } else {
        ""
      }
    })
  }

  df
}

# Insert new icon
# payload: list with icon_name, svg, png_32_b64, primary_color
insert_icon <- function(conn, payload) {
  # Decode base64 PNG
  png32 <- base64enc::base64decode(payload$png_32_b64)

  # Truncate fields to safe sizes to avoid SQL truncation errors
  icon_name <- substr(payload$icon_name, 1, 100)  # Assuming nvarchar(100)
  primary_color <- substr(payload$primary_color, 1, 7)  # Just #RRGGBB

  # Log sizes for debugging
  cat("Insert sizes - icon_name:", nchar(icon_name),
      "primary_color:", nchar(primary_color),
      "svg:", nchar(payload$svg),
      "png32:", length(png32), "bytes\n")

  sql <- "
    INSERT INTO Icons (icon_name, primary_color, svg, png_32_b64, created_at)
    VALUES (?, ?, ?, ?, SYSUTCDATETIME())
  "

  # Use blob package to properly handle binary data
  if (!requireNamespace("blob", quietly = TRUE)) {
    stop("blob package required for binary data. Install with: install.packages('blob')")
  }

  DBI::dbExecute(conn, sql, params = list(
    icon_name,
    primary_color,
    payload$svg,
    blob::blob(png32)
  ))
}

# Check if icon is used in other tables
check_icon_usage <- function(conn, id) {
  # List of tables and columns that reference icons
  # Add more as schema evolves
  usage_checks <- list(
    list(table = "ContainerTypes", column = "Icon", label = "Container Types")
    # Add more tables here as they're added to the schema
    # list(table = "OtherTable", column = "IconID", label = "Other Items")
  )

  usage <- list()

  for (check in usage_checks) {
    sql <- sprintf("
      SELECT COUNT(*) AS n
      FROM SiloOps.dbo.%s
      WHERE %s = ?
    ", check$table, check$column)

    count <- tryCatch({
      result <- DBI::dbGetQuery(conn, sql, params = list(as.integer(id)))
      result$n[1]
    }, error = function(e) {
      # If column doesn't exist yet (schema not migrated), return 0
      0L
    })

    if (count > 0) {
      usage[[check$label]] <- count
    }
  }

  usage
}

# Delete icon by ID
delete_icon <- function(conn, id) {
  sql <- "DELETE FROM Icons WHERE id = ?"
  DBI::dbExecute(conn, sql, params = list(as.integer(id)))
}


# ==============================================================================
# CANVASES QUERIES
# ==============================================================================

# Check if Canvases table exists
check_canvases_table <- function(conn) {
  table_check <- tryCatch({
    DBI::dbGetQuery(conn, "SELECT OBJECT_ID('Canvases', 'U') AS table_id")
  }, error = function(e) NULL)

  if (is.null(table_check) || is.na(table_check$table_id[1])) {
    return(list(exists = FALSE, message = "Canvases table does not exist"))
  }

  return(list(exists = TRUE, message = "Canvases table exists"))
}

# Fetch all canvases for library display
fetch_canvases <- function(conn) {
  sql <- "
    SELECT
      id,
      canvas_name,
      width_px,
      height_px,
      bg_png_b64
    FROM Canvases
    ORDER BY id DESC
  "

  df <- DBI::dbGetQuery(conn, sql)

  # Convert varbinary to base64 if needed
  if (nrow(df) > 0 && "bg_png_b64" %in% names(df)) {
    df$bg_png_b64 <- sapply(df$bg_png_b64, function(x) {
      if (is.null(x) || length(x) == 0) return("")
      if (is.list(x)) x <- x[[1]]
      if (is.raw(x)) {
        base64enc::base64encode(x)
      } else if (is.character(x)) {
        x  # Already a string
      } else {
        ""
      }
    })
  }

  df
}

# Insert new canvas
# payload: list with canvas_name, width_px, height_px, bg_png_b64
insert_canvas <- function(conn, payload) {
  # Truncate name to safe size
  canvas_name <- substr(payload$canvas_name, 1, 200)

  cat("Insert canvas - name:", canvas_name,
      "dimensions:", payload$width_px, "x", payload$height_px,
      "png size:", nchar(payload$bg_png_b64), "chars\n")

  sql <- "
    INSERT INTO Canvases (canvas_name, width_px, height_px, bg_png_b64, created_utc, updated_utc)
    VALUES (?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())
  "

  DBI::dbExecute(conn, sql, params = list(
    canvas_name,
    as.integer(payload$width_px),
    as.integer(payload$height_px),
    payload$bg_png_b64
  ))
}

# Check if canvas is used (placeholder for future use - e.g., in layouts, placements)
check_canvas_usage <- function(conn, id) {
  # Placeholder - add tables that reference canvases as they're created
  usage_checks <- list(
    # Example: list(table = "Layouts", column = "CanvasID", label = "Layouts")
  )

  usage <- list()

  for (check in usage_checks) {
    sql <- sprintf("
      SELECT COUNT(*) AS n
      FROM SiloOps.dbo.%s
      WHERE %s = ?
    ", check$table, check$column)

    count <- tryCatch({
      result <- DBI::dbGetQuery(conn, sql, params = list(as.integer(id)))
      result$n[1]
    }, error = function(e) {
      0L
    })

    if (count > 0) {
      usage[[check$label]] <- count
    }
  }

  usage
}

# Delete canvas by ID
delete_canvas <- function(conn, id) {
  sql <- "DELETE FROM Canvases WHERE id = ?"
  DBI::dbExecute(conn, sql, params = list(as.integer(id)))
}

# ==============================================================================
# REFERENCE INTEGRITY CHECKS (Metadata-Driven)
# ==============================================================================

#' Check if a record can be safely deleted (referential integrity check)
#'
#' Uses REFERENCE_MAP from R/db/reference_config.R to check dependencies
#'
#' @param table_name Name of table (e.g., "Icons", "ContainerTypes")
#' @param record_id ID value to check
#' @return List with:
#'   - can_delete: logical, TRUE if safe to delete
#'   - usage: list of data.frames, one per dependency with actual records
#'   - message: character, user-friendly message
#'   - message_html: character, HTML formatted message for showNotification
#' @examples
#' check_deletion_safety("Icons", 42)
#' # Returns: list(can_delete = FALSE, usage = list(...), message = "...", message_html = "...")
check_deletion_safety <- function(table_name, record_id) {
  # Load reference configuration
  if (!exists("REFERENCE_MAP", envir = .GlobalEnv)) {
    source("R/db/reference_config.R", envir = .GlobalEnv)
  }

  config <- get("REFERENCE_MAP", envir = .GlobalEnv)[[table_name]]

  if (is.null(config)) {
    return(list(
      can_delete = TRUE,
      usage = NULL,
      message = "No dependencies defined",
      message_html = NULL
    ))
  }

  usage_list <- list()
  usage_summary <- character()

  # Check each dependency
  for (dep in config$dependencies) {
    # Build query to find records using this ID
    select_cols <- paste(dep$display_columns, collapse = ", ")
    sql <- sprintf("
      SELECT %s
      FROM %s
      WHERE %s = ?
    ", select_cols, dep$table, dep$foreign_key)

    result <- tryCatch({
      db_query_params(sql, list(record_id))
    }, error = function(e) {
      data.frame() # Empty on error
    })

    if (!is.null(result) && nrow(result) > 0) {
      usage_list[[dep$display_name_plural]] <- result

      # Create summary text
      count <- nrow(result)
      display_name <- if (count == 1) dep$display_name else dep$display_name_plural
      usage_summary <- c(usage_summary, sprintf("%d %s", count, display_name))
    }
  }

  # Build result
  if (length(usage_list) > 0) {
    # Create user-friendly message
    message_text <- sprintf("Cannot delete: used by %s", paste(usage_summary, collapse = ", "))

    # Create HTML message with details
    html_parts <- c("<strong>Cannot delete this record</strong><br/>")
    html_parts <- c(html_parts, sprintf("It is currently used by %s:<br/><br/>", paste(usage_summary, collapse = ", ")))

    for (dep_name in names(usage_list)) {
      records <- usage_list[[dep_name]]
      html_parts <- c(html_parts, sprintf("<strong>%s:</strong><br/>", dep_name))

      # Show first 5 records
      show_count <- min(5, nrow(records))
      for (i in 1:show_count) {
        row_text <- paste(vapply(seq_along(records), function(j) {
          as.character(records[i, j])
        }, character(1)), collapse = " - ")
        html_parts <- c(html_parts, sprintf("• %s<br/>", row_text))
      }

      if (nrow(records) > 5) {
        html_parts <- c(html_parts, sprintf("• ... and %d more<br/>", nrow(records) - 5))
      }
      html_parts <- c(html_parts, "<br/>")
    }

    html_parts <- c(html_parts, "Please remove or reassign these references before deleting.")

    return(list(
      can_delete = FALSE,
      usage = usage_list,
      message = message_text,
      message_html = paste(html_parts, collapse = "")
    ))
  }

  # Safe to delete
  return(list(
    can_delete = TRUE,
    usage = NULL,
    message = "Safe to delete",
    message_html = NULL
  ))
}

# ==============================================================================
# SITES
# ==============================================================================

list_sites <- function(code_like = NULL, order_col = "SiteCode", limit = 1000) {
  pool <- db_pool()

  sql <- sprintf(
    "SELECT TOP %d SiteID, SiteCode, SiteName, Latitude, Longitude,
            GoogleMapsURL, AddressLine1, AddressLine2, City, County, Postcode, IsActive
     FROM SiloOps.dbo.Sites",
    limit
  )

  # Add WHERE clause if filtering
  if (!is.null(code_like) && nzchar(code_like)) {
    safe_like <- gsub("'", "''", code_like)
    sql <- paste0(sql, sprintf(" WHERE SiteCode LIKE '%%%s%%' OR SiteName LIKE '%%%s%%'", safe_like, safe_like))
  }

  # Add ORDER BY
  allowed_cols <- c("SiteID", "SiteCode", "SiteName", "CreatedAt", "UpdatedAt")
  if (order_col %in% allowed_cols) {
    sql <- paste0(sql, sprintf(" ORDER BY %s", order_col))
  } else {
    sql <- paste0(sql, " ORDER BY SiteCode")
  }

  DBI::dbGetQuery(pool, sql)
}

get_site_by_id <- function(site_id) {
  pool <- db_pool()

  sql <- "SELECT SiteID, SiteCode, SiteName, Latitude, Longitude,
                 GoogleMapsURL, AddressLine1, AddressLine2, City, County, Postcode, IsActive
          FROM SiloOps.dbo.Sites
          WHERE SiteID = ?"

  DBI::dbGetQuery(pool, sql, params = list(as.integer(site_id)))
}

upsert_site <- function(data) {
  pool <- db_pool()

  # Extract and validate required fields
  site_code <- f_or(data$SiteCode, "")
  site_name <- f_or(data$SiteName, "")

  if (!nzchar(site_code)) stop("SiteCode is required")
  if (!nzchar(site_name)) stop("SiteName is required")

  # Handle IsActive - checkbox returns TRUE/FALSE or NULL
  is_active <- TRUE  # Default
  if (!is.null(data$IsActive)) {
    if (is.logical(data$IsActive)) {
      is_active <- data$IsActive
    } else if (is.character(data$IsActive)) {
      is_active <- tolower(data$IsActive) %in% c("true", "1", "yes")
    } else {
      is_active <- as.logical(data$IsActive)
    }
  }

  # Check if update or insert
  site_id <- if (!is.null(data$SiteID) && !is.na(data$SiteID)) as.integer(data$SiteID) else NULL

  if (!is.null(site_id) && site_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.Sites
            SET SiteCode = ?, SiteName = ?, Latitude = ?, Longitude = ?,
                GoogleMapsURL = ?,
                AddressLine1 = ?, AddressLine2 = ?, City = ?, County = ?, Postcode = ?,
                IsActive = ?, UpdatedAt = SYSUTCDATETIME()
            WHERE SiteID = ?"

    DBI::dbExecute(pool, sql, params = list(
      site_code,
      site_name,
      if (!is.null(data$Latitude) && !is.na(data$Latitude)) as.numeric(data$Latitude) else NA_real_,
      if (!is.null(data$Longitude) && !is.na(data$Longitude)) as.numeric(data$Longitude) else NA_real_,
      if (!is.null(data$GoogleMapsURL) && nzchar(data$GoogleMapsURL)) data$GoogleMapsURL else NA_character_,
      if (!is.null(data$AddressLine1) && nzchar(data$AddressLine1)) data$AddressLine1 else NA_character_,
      if (!is.null(data$AddressLine2) && nzchar(data$AddressLine2)) data$AddressLine2 else NA_character_,
      if (!is.null(data$City) && nzchar(data$City)) data$City else NA_character_,
      if (!is.null(data$County) && nzchar(data$County)) data$County else NA_character_,
      if (!is.null(data$Postcode) && nzchar(data$Postcode)) data$Postcode else NA_character_,
      is_active,
      site_id
    ))

    return(site_id)

  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.Sites (SiteCode, SiteName, Latitude, Longitude, GoogleMapsURL, AddressLine1, AddressLine2, City, County, Postcode, IsActive, CreatedAt, UpdatedAt)
            OUTPUT INSERTED.SiteID
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      site_code,
      site_name,
      if (!is.null(data$Latitude) && !is.na(data$Latitude)) as.numeric(data$Latitude) else NA_real_,
      if (!is.null(data$Longitude) && !is.na(data$Longitude)) as.numeric(data$Longitude) else NA_real_,
      if (!is.null(data$GoogleMapsURL) && nzchar(data$GoogleMapsURL)) data$GoogleMapsURL else NA_character_,
      if (!is.null(data$AddressLine1) && nzchar(data$AddressLine1)) data$AddressLine1 else NA_character_,
      if (!is.null(data$AddressLine2) && nzchar(data$AddressLine2)) data$AddressLine2 else NA_character_,
      if (!is.null(data$City) && nzchar(data$City)) data$City else NA_character_,
      if (!is.null(data$County) && nzchar(data$County)) data$County else NA_character_,
      if (!is.null(data$Postcode) && nzchar(data$Postcode)) data$Postcode else NA_character_,
      is_active
    ))

    return(result$SiteID[1])
  }
}

# ==============================================================================
# SITE AREAS
# ==============================================================================

list_areas <- function(site_id = NULL, code_like = NULL, order_col = "AreaCode", limit = 1000) {
  pool <- db_pool()

  sql <- sprintf(
    "SELECT TOP %d a.AreaID, a.SiteID, a.AreaCode, a.AreaName, a.Notes,
            s.SiteCode, s.SiteName
     FROM SiloOps.dbo.SiteAreas a
     LEFT JOIN SiloOps.dbo.Sites s ON a.SiteID = s.SiteID",
    limit
  )

  # Add WHERE clause if filtering
  where_clauses <- c()
  if (!is.null(site_id) && !is.na(site_id)) {
    where_clauses <- c(where_clauses, sprintf("a.SiteID = %d", as.integer(site_id)))
  }
  if (!is.null(code_like) && nzchar(code_like)) {
    safe_like <- gsub("'", "''", code_like)
    where_clauses <- c(where_clauses, sprintf("(a.AreaCode LIKE '%%%s%%' OR a.AreaName LIKE '%%%s%%')", safe_like, safe_like))
  }

  if (length(where_clauses) > 0) {
    sql <- paste0(sql, " WHERE ", paste(where_clauses, collapse = " AND "))
  }

  # Add ORDER BY
  allowed_cols <- c("AreaID", "AreaCode", "AreaName", "SiteCode")
  if (order_col %in% allowed_cols) {
    sql <- paste0(sql, sprintf(" ORDER BY %s", order_col))
  } else {
    sql <- paste0(sql, " ORDER BY a.AreaCode")
  }

  DBI::dbGetQuery(pool, sql)
}

get_area_by_id <- function(area_id) {
  pool <- db_pool()

  sql <- "SELECT a.AreaID, a.SiteID, a.AreaCode, a.AreaName, a.Notes,
                 s.SiteCode, s.SiteName
          FROM SiloOps.dbo.SiteAreas a
          LEFT JOIN SiloOps.dbo.Sites s ON a.SiteID = s.SiteID
          WHERE a.AreaID = ?"

  DBI::dbGetQuery(pool, sql, params = list(as.integer(area_id)))
}

upsert_area <- function(data) {
  pool <- db_pool()

  # Extract and validate required fields
  area_code <- f_or(data$AreaCode, "")
  area_name <- f_or(data$AreaName, "")

  # Handle SiteID from select dropdown (could be string, empty string, or NA)
  site_id <- NULL
  if (!is.null(data$SiteID)) {
    if (is.character(data$SiteID) && nzchar(data$SiteID)) {
      site_id <- as.integer(data$SiteID)
    } else if (is.numeric(data$SiteID) && !is.na(data$SiteID)) {
      site_id <- as.integer(data$SiteID)
    }
  }

  if (!nzchar(area_code)) stop("AreaCode is required")
  if (!nzchar(area_name)) stop("AreaName is required")
  if (is.null(site_id) || is.na(site_id)) stop("SiteID is required")

  # Check if update or insert
  area_id <- if (!is.null(data$AreaID) && !is.na(data$AreaID)) as.integer(data$AreaID) else NULL

  if (!is.null(area_id) && area_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.SiteAreas
            SET SiteID = ?, AreaCode = ?, AreaName = ?, Notes = ?
            WHERE AreaID = ?"

    DBI::dbExecute(pool, sql, params = list(
      site_id,
      area_code,
      area_name,
      if (!is.null(data$Notes) && nzchar(data$Notes)) data$Notes else NA_character_,
      area_id
    ))

    return(area_id)

  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.SiteAreas (SiteID, AreaCode, AreaName, Notes)
            OUTPUT INSERTED.AreaID
            VALUES (?, ?, ?, ?)"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      site_id,
      area_code,
      area_name,
      if (!is.null(data$Notes) && nzchar(data$Notes)) data$Notes else NA_character_
    ))

    return(result$AreaID[1])
  }
}

# ==============================================================================
# OFFLINE REASON TYPES
# ==============================================================================

list_offline_reasons <- function(code_like = NULL, order_col = "ReasonTypeCode", limit = 1000) {
  pool <- db_pool()

  sql <- sprintf(
    "SELECT TOP %d ReasonTypeID, ReasonTypeCode, ReasonTypeName, Icon
     FROM SiloOps.dbo.OfflineReasonTypes",
    limit
  )

  # Add WHERE clause if filtering
  if (!is.null(code_like) && nzchar(code_like)) {
    safe_like <- gsub("'", "''", code_like)
    sql <- paste0(sql, sprintf(" WHERE ReasonTypeCode LIKE '%%%s%%' OR ReasonTypeName LIKE '%%%s%%'", safe_like, safe_like))
  }

  # Add ORDER BY
  allowed_cols <- c("ReasonTypeID", "ReasonTypeCode", "ReasonTypeName")
  if (order_col %in% allowed_cols) {
    sql <- paste0(sql, sprintf(" ORDER BY %s", order_col))
  } else {
    sql <- paste0(sql, " ORDER BY ReasonTypeCode")
  }

  DBI::dbGetQuery(pool, sql)
}

get_offline_reason_by_id <- function(reason_id) {
  pool <- db_pool()

  sql <- "SELECT ReasonTypeID, ReasonTypeCode, ReasonTypeName, Icon
          FROM SiloOps.dbo.OfflineReasonTypes
          WHERE ReasonTypeID = ?"

  DBI::dbGetQuery(pool, sql, params = list(as.integer(reason_id)))
}

upsert_offline_reason <- function(data) {
  pool <- db_pool()

  # Extract and validate required fields
  reason_code <- f_or(data$ReasonTypeCode, "")
  reason_name <- f_or(data$ReasonTypeName, "")

  if (!nzchar(reason_code)) stop("ReasonTypeCode is required")
  if (!nzchar(reason_name)) stop("ReasonTypeName is required")

  # Handle Icon (could be empty string or NA from dropdown)
  icon_id <- NULL
  if (!is.null(data$Icon)) {
    if (is.character(data$Icon) && nzchar(data$Icon)) {
      icon_id <- as.integer(data$Icon)
    } else if (is.numeric(data$Icon) && !is.na(data$Icon)) {
      icon_id <- as.integer(data$Icon)
    }
  }

  # Check if update or insert
  reason_id <- if (!is.null(data$ReasonTypeID) && !is.na(data$ReasonTypeID)) as.integer(data$ReasonTypeID) else NULL

  if (!is.null(reason_id) && reason_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.OfflineReasonTypes
            SET ReasonTypeCode = ?, ReasonTypeName = ?, Icon = ?
            WHERE ReasonTypeID = ?"

    DBI::dbExecute(pool, sql, params = list(
      reason_code,
      reason_name,
      if (!is.null(icon_id) && !is.na(icon_id)) icon_id else NA_integer_,
      reason_id
    ))

    return(reason_id)

  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.OfflineReasonTypes (ReasonTypeCode, ReasonTypeName, Icon)
            OUTPUT INSERTED.ReasonTypeID
            VALUES (?, ?, ?)"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      reason_code,
      reason_name,
      if (!is.null(icon_id) && !is.na(icon_id)) icon_id else NA_integer_
    ))

    return(result$ReasonTypeID[1])
  }
}

