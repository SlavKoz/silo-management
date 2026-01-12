# R/utils/f_generate_shape_icon.R
# Generate SVG icons for shapes based on their actual properties

#' Generate inline SVG icon for a shape
#'
#' @param shape_type Character: "CIRCLE", "RECTANGLE", or "TRIANGLE"
#' @param size_factor Numeric 0.3-1.0: relative size within shape type (0.3=smallest, 1.0=largest)
#' @param fill Character: hex color for fill (e.g., "#D9EFFF")
#' @param border Character: hex color for border (e.g., "#6290FF")
#' @param rotation_deg Numeric: rotation in degrees (for triangle orientation)
#'
#' @return HTML string containing inline SVG
generate_shape_icon_svg <- function(shape_type, size_factor = 0.65, fill = "#D9EFFF",
                                    border = "#6290FF", rotation_deg = 0) {
  # Clamp size factor to 0.3-1.0 range
  size_factor <- max(0.3, min(1.0, size_factor))

  # Ensure colors have defaults
  fill <- f_or(fill, "#D9EFFF")
  border <- f_or(border, "#6290FF")
  rotation_deg <- f_or(rotation_deg, 0)

  # Canvas is 24x24, center at 12,12
  shape_type <- toupper(as.character(shape_type))

  if (shape_type == "CIRCLE") {
    # Radius from 5px (smallest) to 10px (largest)
    r <- 5 + (size_factor * 5)
    svg <- sprintf(
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" style="vertical-align: middle;">
        <circle cx="12" cy="12" r="%.1f" fill="%s" stroke="%s" stroke-width="1.5"/>
      </svg>',
      r, fill, border
    )

  } else if (shape_type == "RECTANGLE") {
    # Square from 8x8px (smallest) to 18x18px (largest)
    side <- 8 + (size_factor * 10)
    x <- 12 - (side / 2)
    y <- 12 - (side / 2)

    # Apply rotation around center
    transform <- if (rotation_deg != 0) {
      sprintf(' transform="rotate(%.1f 12 12)"', rotation_deg)
    } else {
      ""
    }

    svg <- sprintf(
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" style="vertical-align: middle;">
        <rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="%s" stroke-width="1.5"%s/>
      </svg>',
      x, y, side, side, fill, border, transform
    )

  } else if (shape_type == "TRIANGLE") {
    # Equilateral triangle inscribed in circle
    # Radius from 6px (smallest) to 10px (largest)
    r <- 6 + (size_factor * 4)

    # Calculate three points of equilateral triangle
    # Start with point at top (rotation = 0 means base is horizontal at bottom)
    angle1 <- -90 + rotation_deg  # Top vertex
    angle2 <- 30 + rotation_deg   # Bottom right
    angle3 <- 150 + rotation_deg  # Bottom left

    x1 <- 12 + r * cos(angle1 * pi / 180)
    y1 <- 12 + r * sin(angle1 * pi / 180)
    x2 <- 12 + r * cos(angle2 * pi / 180)
    y2 <- 12 + r * sin(angle2 * pi / 180)
    x3 <- 12 + r * cos(angle3 * pi / 180)
    y3 <- 12 + r * sin(angle3 * pi / 180)

    svg <- sprintf(
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" style="vertical-align: middle;">
        <polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s" stroke="%s" stroke-width="1.5"/>
      </svg>',
      x1, y1, x2, y2, x3, y3, fill, border
    )

  } else {
    # Unknown shape type - return placeholder
    svg <- '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" style="vertical-align: middle;">
      <rect x="4" y="4" width="16" height="16" fill="#f0f0f0" stroke="#999" stroke-width="1"/>
    </svg>'
  }

  HTML(svg)
}


#' Calculate relative size factors for a list of shapes
#'
#' Normalizes sizes within each shape type to 0.3-1.0 range
#'
#' @param df Data frame with columns: ShapeType, Radius, Width, Height
#' @return Numeric vector of size factors (0.3-1.0) matching df row order
calculate_relative_sizes <- function(df) {
  if (!nrow(df)) return(numeric(0))

  # Initialize with default mid-size
  size_factors <- rep(0.65, nrow(df))

  # Process each shape type separately
  for (stype in c("CIRCLE", "RECTANGLE", "TRIANGLE")) {
    idx <- which(toupper(df$ShapeType) == stype)
    if (length(idx) == 0) next

    if (stype == "CIRCLE") {
      # Use radius
      values <- df$Radius[idx]
      values <- values[!is.na(values) & values > 0]

      if (length(values) > 0) {
        min_val <- min(values)
        max_val <- max(values)

        for (i in idx) {
          r <- df$Radius[i]
          if (!is.na(r) && r > 0) {
            if (max_val > min_val) {
              size_factors[i] <- 0.3 + 0.7 * (r - min_val) / (max_val - min_val)
            } else {
              size_factors[i] <- 0.65  # All same size
            }
          }
        }
      }

    } else if (stype == "RECTANGLE") {
      # Use area (Width × Height)
      areas <- df$Width[idx] * df$Height[idx]
      areas <- areas[!is.na(areas) & areas > 0]

      if (length(areas) > 0) {
        min_area <- min(areas)
        max_area <- max(areas)

        for (i in idx) {
          w <- df$Width[i]
          h <- df$Height[i]
          if (!is.na(w) && !is.na(h) && w > 0 && h > 0) {
            area <- w * h
            if (max_area > min_area) {
              size_factors[i] <- 0.3 + 0.7 * (area - min_area) / (max_area - min_area)
            } else {
              size_factors[i] <- 0.65
            }
          }
        }
      }

    } else if (stype == "TRIANGLE") {
      # Use radius (bounding circle)
      values <- df$Radius[idx]
      values <- values[!is.na(values) & values > 0]

      if (length(values) > 0) {
        min_val <- min(values)
        max_val <- max(values)

        for (i in idx) {
          r <- df$Radius[i]
          if (!is.na(r) && r > 0) {
            if (max_val > min_val) {
              size_factors[i] <- 0.3 + 0.7 * (r - min_val) / (max_val - min_val)
            } else {
              size_factors[i] <- 0.65
            }
          }
        }
      }
    }
  }

  size_factors
}
