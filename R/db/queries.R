# R/db/queries.R
# Minimal, SAFE (parameterized) queries for browsers

# ---- Allowed columns (for ORDER BY whitelisting) ----
.ALLOWED_SILOS_COLS <- c("SiloID","SiloCode","SiloName","Area","ContainerTypeID",
                         "VolumeM3","IsActive","CreatedAt","UpdatedAt")
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
# Queries Silos table with JOINs to get Area and Site information
list_silos <- function(area_id = NULL,
                       area_code_like = NULL,
                       code_like = NULL,
                       active = NULL,
                       ids = NULL,
                       order_col = "SiloCode",
                       order_dir = "ASC",
                       limit = 200,
                       offset = 0) {

  ob <- safe_order_by(order_col, order_dir, .ALLOWED_SILOS_COLS)

  where <- c(); params <- list()

  if (!is.null(area_id))          { where <- c(where, "s.AreaID = ?");         params <- c(params, list(as.integer(area_id))) }
  if (!is.null(area_code_like))   { where <- c(where, "a.AreaCode LIKE ?");   params <- c(params, list(area_code_like)) }
  if (!is.null(active))            { where <- c(where, "s.IsActive = ?");      params <- c(params, list(as.logical(active))) }
  if (!is.null(code_like))         { where <- c(where, "s.SiloCode LIKE ?");   params <- c(params, list(code_like)) }
  if (!is.null(ids) && length(ids)) {
    IN <- sql_in(ids); where <- c(where, paste("s.SiloID", IN$clause)); params <- c(params, IN$params)
  }
  where_sql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""

  sql <- sprintf("
    SELECT s.SiloID, s.SiloCode, s.SiloName,
           s.AreaID, a.AreaCode, a.AreaName,
           s.SiteID, site.SiteCode, site.SiteName,
           s.ContainerTypeID, s.VolumeM3, s.IsActive,
           s.CreatedAt, s.UpdatedAt
    FROM SiloOps.dbo.Silos s
    LEFT JOIN SiloOps.dbo.SiteAreas a ON s.AreaID = a.AreaID
    LEFT JOIN SiloOps.dbo.Sites site ON s.SiteID = site.SiteID
    %s
    %s
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  ", where_sql, ob)

  db_query_params(sql, c(params, list(as.integer(offset), as.integer(limit))))
}

get_silo_by_id <- function(silo_id) {
  db_query_params("
    SELECT s.SiloID, s.SiloCode, s.SiloName,
           s.AreaID, a.AreaCode, a.AreaName,
           s.SiteID, site.SiteCode, site.SiteName,
           s.ContainerTypeID, s.VolumeM3, s.IsActive,
           s.Notes, s.CreatedAt, s.UpdatedAt
    FROM SiloOps.dbo.Silos s
    LEFT JOIN SiloOps.dbo.SiteAreas a ON s.AreaID = a.AreaID
    LEFT JOIN SiloOps.dbo.Sites site ON s.SiteID = site.SiteID
    WHERE s.SiloID = ?
  ", list(as.integer(silo_id)))
}

upsert_silo <- function(data) {
  pool <- db_pool()

  # Extract and validate required fields
  silo_code <- f_or(data$SiloCode, "")
  silo_name <- f_or(data$SiloName, "")

  if (!nzchar(silo_code)) stop("SiloCode is required")
  if (!nzchar(silo_name)) stop("SiloName is required")

  # Handle VolumeM3 - required, must be positive
  volume_m3 <- NULL
  if (!is.null(data$VolumeM3)) {
    if (is.numeric(data$VolumeM3) && !is.na(data$VolumeM3)) {
      volume_m3 <- as.numeric(data$VolumeM3)
    } else if (is.character(data$VolumeM3) && nzchar(data$VolumeM3)) {
      volume_m3 <- as.numeric(data$VolumeM3)
    }
  }
  if (is.null(volume_m3) || is.na(volume_m3)) stop("VolumeM3 is required")
  if (volume_m3 <= 0) stop("VolumeM3 must be positive")

  # Handle ContainerTypeID from nested structure or top-level
  container_type_id <- NULL
  if (!is.null(data$Type$ContainerTypeID)) {
    if (is.character(data$Type$ContainerTypeID) && nzchar(data$Type$ContainerTypeID)) {
      container_type_id <- as.integer(data$Type$ContainerTypeID)
    } else if (is.numeric(data$Type$ContainerTypeID) && !is.na(data$Type$ContainerTypeID)) {
      container_type_id <- as.integer(data$Type$ContainerTypeID)
    }
  } else if (!is.null(data$ContainerTypeID)) {
    if (is.character(data$ContainerTypeID) && nzchar(data$ContainerTypeID)) {
      container_type_id <- as.integer(data$ContainerTypeID)
    } else if (is.numeric(data$ContainerTypeID) && !is.na(data$ContainerTypeID)) {
      container_type_id <- as.integer(data$ContainerTypeID)
    }
  }
  if (is.null(container_type_id) || is.na(container_type_id)) stop("ContainerTypeID is required")

  # Handle SiteID from nested structure or top-level (optional)
  site_id <- NULL
  if (!is.null(data$Location$SiteID)) {
    if (is.character(data$Location$SiteID) && nzchar(data$Location$SiteID)) {
      site_id <- as.integer(data$Location$SiteID)
    } else if (is.numeric(data$Location$SiteID) && !is.na(data$Location$SiteID)) {
      site_id <- as.integer(data$Location$SiteID)
    }
  } else if (!is.null(data$SiteID)) {
    if (is.character(data$SiteID) && nzchar(data$SiteID)) {
      site_id <- as.integer(data$SiteID)
    } else if (is.numeric(data$SiteID) && !is.na(data$SiteID)) {
      site_id <- as.integer(data$SiteID)
    }
  }

  # Handle AreaID from nested structure or top-level (optional)
  area_id <- NULL
  if (!is.null(data$Location$AreaID)) {
    if (is.character(data$Location$AreaID) && nzchar(data$Location$AreaID)) {
      area_id <- as.integer(data$Location$AreaID)
    } else if (is.numeric(data$Location$AreaID) && !is.na(data$Location$AreaID)) {
      area_id <- as.integer(data$Location$AreaID)
    }
  } else if (!is.null(data$AreaID)) {
    if (is.character(data$AreaID) && nzchar(data$AreaID)) {
      area_id <- as.integer(data$AreaID)
    } else if (is.numeric(data$AreaID) && !is.na(data$AreaID)) {
      area_id <- as.integer(data$AreaID)
    }
  }

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

  # Handle Notes from nested structure or top-level
  notes <- NULL
  if (!is.null(data$Notes$Notes)) {
    if (nzchar(data$Notes$Notes)) notes <- data$Notes$Notes
  } else if (!is.null(data$Notes)) {
    if (is.character(data$Notes) && nzchar(data$Notes)) notes <- data$Notes
  }

  # Check if update or insert
  silo_id <- if (!is.null(data$SiloID) && !is.na(data$SiloID)) as.integer(data$SiloID) else NULL

  if (!is.null(silo_id) && silo_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.Silos
            SET SiloCode = ?, SiloName = ?, VolumeM3 = ?,
                ContainerTypeID = ?, SiteID = ?, AreaID = ?,
                IsActive = ?, Notes = ?, UpdatedAt = SYSUTCDATETIME()
            WHERE SiloID = ?"

    DBI::dbExecute(pool, sql, params = list(
      silo_code,
      silo_name,
      volume_m3,
      container_type_id,
      if (!is.null(site_id)) site_id else NA_integer_,
      if (!is.null(area_id)) area_id else NA_integer_,
      is_active,
      if (!is.null(notes)) notes else NA_character_,
      silo_id
    ))

    return(silo_id)

  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.Silos
            (SiloCode, SiloName, VolumeM3, ContainerTypeID, SiteID, AreaID, IsActive, Notes, CreatedAt, UpdatedAt)
            OUTPUT INSERTED.SiloID
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      silo_code,
      silo_name,
      volume_m3,
      container_type_id,
      if (!is.null(site_id)) site_id else NA_integer_,
      if (!is.null(area_id)) area_id else NA_integer_,
      is_active,
      if (!is.null(notes)) notes else NA_character_
    ))

    return(result$SiloID[1])
  }
}

# Delete silo
delete_silo <- function(silo_id) {
  pool <- db_pool()
  sql <- "DELETE FROM SiloOps.dbo.Silos WHERE SiloID = ?"
  DBI::dbExecute(pool, sql, params = list(as.integer(silo_id)))
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

# Save (upsert) placement
upsert_placement <- function(data) {
  pool <- db_pool()

  # Extract fields
  silo_id <- as.integer(f_or(data$SiloID, NA))
  layout_id <- as.integer(f_or(data$LayoutID, NA))
  shape_template_id <- as.integer(f_or(data$ShapeTemplateID, NA))
  center_x <- as.numeric(f_or(data$CenterX, 0))
  center_y <- as.numeric(f_or(data$CenterY, 0))
  z_index <- if (!is.null(data$ZIndex) && !is.na(data$ZIndex)) as.integer(data$ZIndex) else NA_integer_

  # Handle booleans
  is_visible <- TRUE
  if (!is.null(data$IsVisible)) {
    if (is.logical(data$IsVisible)) {
      is_visible <- data$IsVisible
    } else if (is.character(data$IsVisible)) {
      is_visible <- tolower(data$IsVisible) %in% c("true", "1", "yes")
    } else {
      is_visible <- as.logical(data$IsVisible)
    }
  }

  is_interactive <- TRUE
  if (!is.null(data$IsInteractive)) {
    if (is.logical(data$IsInteractive)) {
      is_interactive <- data$IsInteractive
    } else if (is.character(data$IsInteractive)) {
      is_interactive <- tolower(data$IsInteractive) %in% c("true", "1", "yes")
    } else {
      is_interactive <- as.logical(data$IsInteractive)
    }
  }

  # Validate required fields
  if (is.na(silo_id)) stop("SiloID is required")
  if (is.na(layout_id)) stop("LayoutID is required")
  if (is.na(shape_template_id)) stop("ShapeTemplateID is required")

  # Check if update or insert
  placement_id <- if (!is.null(data$PlacementID) && !is.na(data$PlacementID)) as.integer(data$PlacementID) else NULL

  if (!is.null(placement_id) && placement_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.SiloPlacements
            SET SiloID = ?, LayoutID = ?, ShapeTemplateID = ?,
                CenterX = ?, CenterY = ?, ZIndex = ?,
                IsVisible = ?, IsInteractive = ?
            WHERE PlacementID = ?"

    DBI::dbExecute(pool, sql, params = list(
      silo_id, layout_id, shape_template_id,
      center_x, center_y, z_index,
      is_visible, is_interactive,
      placement_id
    ))

    return(placement_id)
  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.SiloPlacements
            (SiloID, LayoutID, ShapeTemplateID, CenterX, CenterY, ZIndex,
             IsVisible, IsInteractive, CreatedAt)
            OUTPUT INSERTED.PlacementID
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME())"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      silo_id, layout_id, shape_template_id,
      center_x, center_y, z_index,
      is_visible, is_interactive
    ))

    return(result$PlacementID[1])
  }
}

# Delete placement
delete_placement <- function(placement_id) {
  pool <- db_pool()
  sql <- "DELETE FROM SiloOps.dbo.SiloPlacements WHERE PlacementID = ?"
  DBI::dbExecute(pool, sql, params = list(as.integer(placement_id)))
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

# ---- Canvases -------------------------------------------------------------

list_canvases <- function(limit = 100) {
  pool <- db_pool()
  sql <- sprintf("
    SELECT TOP %d id, canvas_name, width_px, height_px, bg_png_b64, created_utc, updated_utc
    FROM SiloOps.dbo.Canvases
    ORDER BY canvas_name
  ", as.integer(limit))

  DBI::dbGetQuery(pool, sql)
}

get_canvas_by_id <- function(canvas_id) {
  db_query_params("
    SELECT id, canvas_name, width_px, height_px, bg_png_b64, created_utc, updated_utc
    FROM SiloOps.dbo.Canvases
    WHERE id = ?
  ", list(as.integer(canvas_id)))
}

# ---- Canvas Layouts -------------------------------------------------------

list_canvas_layouts <- function(limit = 100, offset = 0) {
  sql <- "
    SELECT LayoutID, LayoutName, WidthUnits, HeightUnits, IsDefault,
           CanvasID, BackgroundRotation, BackgroundPanX, BackgroundPanY,
           BackgroundZoom, BackgroundScaleX, BackgroundScaleY,
           CreatedAt, UpdatedAt
    FROM SiloOps.dbo.CanvasLayouts
    ORDER BY LayoutName
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  "
  db_query_params(sql, list(as.integer(offset), as.integer(limit)))
}

get_layout_by_id <- function(layout_id) {
  db_query_params("
    SELECT LayoutID, LayoutName, WidthUnits, HeightUnits, IsDefault,
           CanvasID, BackgroundRotation, BackgroundPanX, BackgroundPanY,
           BackgroundZoom, BackgroundScaleX, BackgroundScaleY,
           CreatedAt, UpdatedAt
    FROM SiloOps.dbo.CanvasLayouts
    WHERE LayoutID = ?
  ", list(as.integer(layout_id)))
}

# Update layout background settings
update_layout_background <- function(layout_id, canvas_id = NULL, rotation = NULL,
                                    pan_x = NULL, pan_y = NULL, zoom = NULL,
                                    scale_x = NULL, scale_y = NULL) {
  pool <- db_pool()

  updates <- c()
  params <- list()

  if (!is.null(canvas_id)) {
    updates <- c(updates, "CanvasID = ?")
    params <- c(params, list(if(canvas_id == "") NULL else as.integer(canvas_id)))
  }
  if (!is.null(rotation)) {
    updates <- c(updates, "BackgroundRotation = ?")
    params <- c(params, list(as.numeric(rotation)))
  }
  if (!is.null(pan_x)) {
    updates <- c(updates, "BackgroundPanX = ?")
    params <- c(params, list(as.numeric(pan_x)))
  }
  if (!is.null(pan_y)) {
    updates <- c(updates, "BackgroundPanY = ?")
    params <- c(params, list(as.numeric(pan_y)))
  }
  if (!is.null(zoom)) {
    updates <- c(updates, "BackgroundZoom = ?")
    params <- c(params, list(as.numeric(zoom)))
  }
  if (!is.null(scale_x)) {
    updates <- c(updates, "BackgroundScaleX = ?")
    params <- c(params, list(as.numeric(scale_x)))
  }
  if (!is.null(scale_y)) {
    updates <- c(updates, "BackgroundScaleY = ?")
    params <- c(params, list(as.numeric(scale_y)))
  }

  if (length(updates) == 0) return(FALSE)

  updates <- c(updates, "UpdatedAt = GETDATE()")
  params <- c(params, list(as.integer(layout_id)))

  sql <- sprintf("
    UPDATE SiloOps.dbo.CanvasLayouts
    SET %s
    WHERE LayoutID = ?
  ", paste(updates, collapse = ", "))

  DBI::dbExecute(pool, sql, params = params)
  return(TRUE)
}

#' Create New Canvas Layout
#' @param layout_name Name for the new layout
#' @return The LayoutID of the newly created layout
#' @note Width/Height default to 1000, but are primarily determined by background canvas
create_canvas_layout <- function(layout_name) {
  pool <- db_pool()

  # Use OUTPUT clause to get the inserted ID in a single statement
  sql <- "
    INSERT INTO SiloOps.dbo.CanvasLayouts
      (LayoutName, WidthUnits, HeightUnits, IsDefault, CreatedAt, UpdatedAt)
    OUTPUT INSERTED.LayoutID
    VALUES (?, 1000, 1000, 0, GETDATE(), GETDATE());
  "

  result <- db_query_params(sql, list(as.character(layout_name)))

  if (!is.null(result) && nrow(result) > 0 && !is.na(result$LayoutID[1])) {
    return(as.integer(result$LayoutID[1]))
  } else {
    stop("Failed to create layout - no ID returned")
  }
}

# ---- Canvas Layouts -------------------------------------------------------

list_canvas_layouts <- function(limit = 100, offset = 0) {
  sql <- "
    SELECT LayoutID, LayoutName, WidthUnits, HeightUnits, IsDefault,
           CanvasID, BackgroundRotation, BackgroundPanX, BackgroundPanY,
           BackgroundZoom, BackgroundScaleX, BackgroundScaleY,
           CreatedAt, UpdatedAt
    FROM SiloOps.dbo.CanvasLayouts
    ORDER BY LayoutName
    OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
  "
  db_query_params(sql, list(as.integer(offset), as.integer(limit)))
}

get_layout_by_id <- function(layout_id) {
  db_query_params("
    SELECT LayoutID, LayoutName, WidthUnits, HeightUnits, IsDefault,
           CanvasID, BackgroundRotation, BackgroundPanX, BackgroundPanY,
           BackgroundZoom, BackgroundScaleX, BackgroundScaleY,
           CreatedAt, UpdatedAt
    FROM SiloOps.dbo.CanvasLayouts
    WHERE LayoutID = ?
  ", list(as.integer(layout_id)))
}

# Update layout background settings
update_layout_background <- function(layout_id, canvas_id = NULL, rotation = NULL,
                                     pan_x = NULL, pan_y = NULL, zoom = NULL,
                                     scale_x = NULL, scale_y = NULL) {
  pool <- db_pool()
  
  updates <- c()
  params <- list()
  
  if (!is.null(canvas_id)) {
    updates <- c(updates, "CanvasID = ?")
    params <- c(params, list(if (canvas_id == "") NULL else as.integer(canvas_id)))
  }
  if (!is.null(rotation)) {
    updates <- c(updates, "BackgroundRotation = ?")
    params <- c(params, list(as.numeric(rotation)))
  }
  if (!is.null(pan_x)) {
    updates <- c(updates, "BackgroundPanX = ?")
    params <- c(params, list(as.numeric(pan_x)))
  }
  if (!is.null(pan_y)) {
    updates <- c(updates, "BackgroundPanY = ?")
    params <- c(params, list(as.numeric(pan_y)))
  }
  if (!is.null(zoom)) {
    updates <- c(updates, "BackgroundZoom = ?")
    params <- c(params, list(as.numeric(zoom)))
  }
  if (!is.null(scale_x)) {
    updates <- c(updates, "BackgroundScaleX = ?")
    params <- c(params, list(as.numeric(scale_x)))
  }
  if (!is.null(scale_y)) {
    updates <- c(updates, "BackgroundScaleY = ?")
    params <- c(params, list(as.numeric(scale_y)))
  }
  
  if (length(updates) == 0) return(FALSE)
  
  updates <- c(updates, "UpdatedAt = GETDATE()")
  params <- c(params, list(as.integer(layout_id)))
  
  sql <- sprintf("
    UPDATE SiloOps.dbo.CanvasLayouts
    SET %s
    WHERE LayoutID = ?
  ", paste(updates, collapse = ", "))
  
  DBI::dbExecute(pool, sql, params = params)
  return(TRUE)
}

#' Create New Canvas Layout
#' @param layout_name Name for the new layout
#' @return The LayoutID of the newly created layout
#' @note Width/Height default to 1000, but are primarily determined by background canvas
create_canvas_layout <- function(layout_name) {
  pool <- db_pool()
  
  # Use OUTPUT clause to get the inserted ID in a single statement
  sql <- "
    INSERT INTO SiloOps.dbo.CanvasLayouts
      (LayoutName, WidthUnits, HeightUnits, IsDefault, CreatedAt, UpdatedAt)
    OUTPUT INSERTED.LayoutID
    VALUES (?, 1000, 1000, 0, GETDATE(), GETDATE());
  "
  
  result <- db_query_params(sql, list(as.character(layout_name)))
  
  if (!is.null(result) && nrow(result) > 0 && !is.na(result$LayoutID[1])) {
    return(as.integer(result$LayoutID[1]))
  } else {
    stop("Failed to create layout - no ID returned")
  }
}

#' Delete Canvas Layout                                               
#' @param layout_id ID of the layout to delete                        
#' @return TRUE if the delete executes without error                  
delete_canvas_layout <- function(layout_id) {                         
  pool <- db_pool()                                                   
  sql <- "                                                            
    DELETE FROM SiloOps.dbo.CanvasLayouts                             
    WHERE LayoutID = ?                                                
  "                                                                   
  DBI::dbExecute(pool, sql, params = list(as.integer(layout_id)))     
  return(TRUE)                                                        
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

# ==============================================================================
# OPERATIONS
# ==============================================================================

list_operations <- function(code_like = NULL, order_col = "OpCode", limit = 1000) {
  pool <- db_pool()

  sql <- sprintf(
    "SELECT TOP %d OperationID, OpCode, OpName, RequiresParams, ParamsSchemaJSON
     FROM SiloOps.dbo.Operations",
    limit
  )

  # Add WHERE clause if filtering
  if (!is.null(code_like) && nzchar(code_like)) {
    safe_like <- gsub("'", "''", code_like)
    sql <- paste0(sql, sprintf(" WHERE OpCode LIKE '%%%s%%' OR OpName LIKE '%%%s%%'", safe_like, safe_like))
  }

  # Add ORDER BY
  allowed_cols <- c("OperationID", "OpCode", "OpName")
  if (order_col %in% allowed_cols) {
    sql <- paste0(sql, sprintf(" ORDER BY %s", order_col))
  } else {
    sql <- paste0(sql, " ORDER BY OpCode")
  }

  DBI::dbGetQuery(pool, sql)
}

get_operation_by_id <- function(operation_id) {
  pool <- db_pool()

  sql <- "SELECT OperationID, OpCode, OpName, RequiresParams, ParamsSchemaJSON
          FROM SiloOps.dbo.Operations
          WHERE OperationID = ?"

  DBI::dbGetQuery(pool, sql, params = list(as.integer(operation_id)))
}

upsert_operation <- function(data) {
  pool <- db_pool()

  # Extract and validate required fields
  op_code <- f_or(data$OpCode, "")
  op_name <- f_or(data$OpName, "")

  if (!nzchar(op_code)) stop("OpCode is required")
  if (!nzchar(op_name)) stop("OpName is required")

  # Handle RequiresParams - checkbox/switch returns TRUE/FALSE
  requires_params <- FALSE  # Default
  if (!is.null(data$RequiresParams)) {
    if (is.logical(data$RequiresParams)) {
      requires_params <- data$RequiresParams
    } else if (is.character(data$RequiresParams)) {
      requires_params <- tolower(data$RequiresParams) %in% c("true", "1", "yes")
    } else {
      requires_params <- as.logical(data$RequiresParams)
    }
  }

  # Check if update or insert
  operation_id <- if (!is.null(data$OperationID) && !is.na(data$OperationID)) as.integer(data$OperationID) else NULL

  if (!is.null(operation_id) && operation_id > 0) {
    # UPDATE
    sql <- "UPDATE SiloOps.dbo.Operations
            SET OpCode = ?, OpName = ?, RequiresParams = ?, ParamsSchemaJSON = ?,
                UpdatedAt = SYSUTCDATETIME()
            WHERE OperationID = ?"

    DBI::dbExecute(pool, sql, params = list(
      op_code,
      op_name,
      requires_params,
      if (!is.null(data$ParamsSchemaJSON) && nzchar(data$ParamsSchemaJSON)) data$ParamsSchemaJSON else NA_character_,
      operation_id
    ))

    return(operation_id)

  } else {
    # INSERT
    sql <- "INSERT INTO SiloOps.dbo.Operations (OpCode, OpName, RequiresParams, ParamsSchemaJSON, CreatedAt, UpdatedAt)
            OUTPUT INSERTED.OperationID
            VALUES (?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())"

    result <- DBI::dbGetQuery(pool, sql, params = list(
      op_code,
      op_name,
      requires_params,
      if (!is.null(data$ParamsSchemaJSON) && nzchar(data$ParamsSchemaJSON)) data$ParamsSchemaJSON else NA_character_
    ))

    return(result$OperationID[1])
  }
}

