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

