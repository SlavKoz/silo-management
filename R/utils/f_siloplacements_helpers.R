# R/utils/f_siloplacements_helpers.R
# Helper functions for SiloPlacements canvas browser

#' Build canvas shapes from placements data
#'
#' @param placements Data frame of placement records
#' @param silos Data frame of silo records
#' @param templates Data frame of shape template records
#'
#' @return List of shape objects for canvas rendering
build_canvas_shapes <- function(placements, silos, templates) {
  if (!nrow(placements)) {
    return(list())
  }

  shapes <- lapply(seq_len(nrow(placements)), function(i) {
    p <- placements[i, ]

    # Find silo info
    silo <- silos[silos$SiloID == p$SiloID, ]
    silo_code <- if (nrow(silo) > 0) silo$SiloCode[1] else paste0("S", p$SiloID)

    # Find shape template
    template <- templates[templates$ShapeTemplateID == p$ShapeTemplateID, ]
    shape_type <- if (nrow(template) > 0) template$ShapeType[1] else "CIRCLE"

    # Build shape object based on type
    if (shape_type == "CIRCLE") {
      radius <- if (nrow(template) > 0 && !is.na(template$Radius[1])) as.numeric(template$Radius[1]) else 20
      list(
        id = as.character(p$PlacementID),
        type = "circle",
        x = as.numeric(p$CenterX),
        y = as.numeric(p$CenterY),
        r = radius,
        label = silo_code,
        fill = "rgba(59, 130, 246, 0.2)",
        stroke = "rgba(59, 130, 246, 0.8)",
        strokeWidth = 2
      )
    } else if (shape_type == "RECTANGLE") {
      width <- if (nrow(template) > 0 && !is.na(template$Width[1])) as.numeric(template$Width[1]) else 40
      height <- if (nrow(template) > 0 && !is.na(template$Height[1])) as.numeric(template$Height[1]) else 40
      list(
        id = as.character(p$PlacementID),
        type = "rect",
        x = as.numeric(p$CenterX) - width / 2,
        y = as.numeric(p$CenterY) - height / 2,
        w = width,
        h = height,
        label = silo_code,
        fill = "rgba(34, 197, 94, 0.2)",
        stroke = "rgba(34, 197, 94, 0.8)",
        strokeWidth = 2
      )
    } else if (shape_type == "TRIANGLE") {
      radius <- if (nrow(template) > 0 && !is.na(template$Radius[1])) as.numeric(template$Radius[1]) else 20
      list(
        id = as.character(p$PlacementID),
        type = "triangle",
        x = as.numeric(p$CenterX),
        y = as.numeric(p$CenterY),
        r = radius,
        label = silo_code,
        fill = "rgba(168, 85, 247, 0.2)",
        stroke = "rgba(168, 85, 247, 0.8)",
        strokeWidth = 2
      )
    } else {
      # Fallback to circle for unknown types
      list(
        id = as.character(p$PlacementID),
        type = "circle",
        x = as.numeric(p$CenterX),
        y = as.numeric(p$CenterY),
        r = 20,
        label = silo_code,
        fill = "rgba(59, 130, 246, 0.2)",
        stroke = "rgba(59, 130, 246, 0.8)",
        strokeWidth = 2
      )
    }
  })

  shapes
}

#' Build silo dropdown choices with site/area hierarchy
#'
#' @param current_layout_id Current layout ID
#' @param show_inactive Include inactive silos
#' @param search_all Search all sites/areas
#' @param pool Database connection pool
#'
#' @return List with choices (named vector) and all_silos (data frame)
build_silo_dropdown_choices <- function(current_layout_id, show_inactive = FALSE, search_all = FALSE, pool) {
  # Get all silos with optional placement info
  query <- paste0("
    SELECT
      s.SiloID,
      s.SiloCode,
      s.SiloName,
      s.IsActive,
      si.SiteID,
      si.SiteCode,
      si.SiteName,
      sa.AreaID,
      sa.AreaCode,
      sa.AreaName,
      p.PlacementID,
      p.LayoutID,
      p.CenterX,
      p.CenterY
    FROM Silos s
    LEFT JOIN Sites si ON s.SiteID = si.SiteID
    LEFT JOIN SiteAreas sa ON s.AreaID = sa.AreaID
    LEFT JOIN SiloPlacements p ON s.SiloID = p.SiloID AND p.LayoutID = ", current_layout_id, "
  ")

  # Add filter conditions
  where_clauses <- c()

  if (!show_inactive) {
    where_clauses <- c(where_clauses, "s.IsActive = 1")
  }

  if (!search_all) {
    # Filter by current layout's site
    current_layout_data <- try(get_layout_by_id(current_layout_id), silent = TRUE)
    if (!inherits(current_layout_data, "try-error") && nrow(current_layout_data) > 0) {
      site_id <- current_layout_data$SiteID[1]
      if (!is.null(site_id) && !is.na(site_id)) {
        where_clauses <- c(where_clauses, paste0("s.SiteID = ", site_id))
      }
    }
  }

  if (length(where_clauses) > 0) {
    query <- paste0(query, " WHERE ", paste(where_clauses, collapse = " AND "))
  }

  query <- paste0(query, " ORDER BY si.SiteName, sa.AreaName, s.SiloCode")

  all_silos <- try(DBI::dbGetQuery(pool, query), silent = FALSE)

  if (inherits(all_silos, "try-error") || nrow(all_silos) == 0) {
    return(list(choices = c("No silos found" = ""), all_silos = data.frame()))
  }

  # Get current layout's site for comparison
  current_layout_data <- try(get_layout_by_id(current_layout_id), silent = TRUE)
  current_site_id <- NULL
  if (!inherits(current_layout_data, "try-error") && nrow(current_layout_data) > 0) {
    current_site_id <- current_layout_data$SiteID[1]
  }

  # Build choices: "SiteName / AreaName / SiloCode - SiloName"
  # Mark items not from current site or without placement with brackets
  choice_labels <- sapply(1:nrow(all_silos), function(i) {
    site_name <- if (!is.na(all_silos$SiteName[i])) all_silos$SiteName[i] else "Unknown Site"
    area_part <- if (!is.na(all_silos$AreaName[i])) paste0(" / ", all_silos$AreaName[i]) else ""
    silo_part <- paste0(" / ", all_silos$SiloCode[i], " - ", all_silos$SiloName[i])

    base_label <- paste0(site_name, area_part, silo_part)

    # Mark items from other sites OR without placement in current layout with brackets
    from_different_site <- !is.null(current_site_id) && !is.na(all_silos$SiteID[i]) &&
                           all_silos$SiteID[i] != current_site_id
    no_placement <- is.na(all_silos$PlacementID[i])

    if (from_different_site || no_placement) {
      base_label <- paste0("[", base_label, "]")
    }

    base_label
  })

  # Use PlacementID only if from current site AND has placement
  # Otherwise use "silo_" prefix to prevent centering
  choice_values <- sapply(1:nrow(all_silos), function(i) {
    from_current_site <- !is.null(current_site_id) && !is.na(all_silos$SiteID[i]) &&
                         all_silos$SiteID[i] == current_site_id
    has_placement <- !is.na(all_silos$PlacementID[i])

    if (from_current_site && has_placement) {
      as.character(all_silos$PlacementID[i])
    } else {
      paste0("silo_", all_silos$SiloID[i])
    }
  })

  choices <- setNames(choice_values, choice_labels)

  list(choices = choices, all_silos = all_silos)
}

#' Build shape data for cursor preview
#'
#' @param template Shape template record
#'
#' @return List with shape data for cursor preview
build_shape_cursor_data <- function(template) {
  shape_type <- template$ShapeType[1]

  shape_data <- list(
    shapeType = shape_type,
    templateId = as.integer(template$ShapeTemplateID[1])
  )

  if (shape_type == "CIRCLE") {
    shape_data$radius <- as.numeric(f_or(template$Radius[1], 20))
  } else if (shape_type == "RECTANGLE") {
    shape_data$width <- as.numeric(f_or(template$Width[1], 40))
    shape_data$height <- as.numeric(f_or(template$Height[1], 40))
  } else if (shape_type == "TRIANGLE") {
    shape_data$radius <- as.numeric(f_or(template$Radius[1], 20))
  }

  shape_data
}

#' Build temp shape for new placement
#'
#' @param template_id Shape template ID
#' @param templates Data frame of templates
#' @param center_x X coordinate
#' @param center_y Y coordinate
#' @param silo_code Optional silo code for label
#'
#' @return List with temp shape data
build_temp_shape <- function(template_id, templates, center_x, center_y, silo_code = "NEW") {
  template <- templates[templates$ShapeTemplateID == template_id, ]

  if (nrow(template) == 0) {
    return(NULL)
  }

  shape_type <- template$ShapeType[1]

  if (shape_type == "CIRCLE") {
    radius <- as.numeric(f_or(template$Radius[1], 20))
    list(
      id = "temp",
      type = "circle",
      x = as.numeric(center_x),
      y = as.numeric(center_y),
      r = radius,
      label = silo_code,
      fill = "rgba(255, 165, 0, 0.2)",
      stroke = "rgba(255, 165, 0, 0.8)",
      strokeWidth = 2
    )
  } else if (shape_type == "RECTANGLE") {
    width <- as.numeric(f_or(template$Width[1], 40))
    height <- as.numeric(f_or(template$Height[1], 40))
    list(
      id = "temp",
      type = "rect",
      x = as.numeric(center_x) - width / 2,
      y = as.numeric(center_y) - height / 2,
      w = width,
      h = height,
      label = silo_code,
      fill = "rgba(255, 165, 0, 0.2)",
      stroke = "rgba(255, 165, 0, 0.8)",
      strokeWidth = 2
    )
  } else if (shape_type == "TRIANGLE") {
    radius <- as.numeric(f_or(template$Radius[1], 20))
    list(
      id = "temp",
      type = "triangle",
      x = as.numeric(center_x),
      y = as.numeric(center_y),
      r = radius,
      label = silo_code,
      fill = "rgba(255, 165, 0, 0.2)",
      stroke = "rgba(255, 165, 0, 0.8)",
      strokeWidth = 2
    )
  } else {
    NULL
  }
}
