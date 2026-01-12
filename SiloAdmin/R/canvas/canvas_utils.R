# R/canvas/canvas_utils.R
# Helpers for converting DB rows to canvas shapes and computing bounds.

suppressPackageStartupMessages({
  library(jsonlite)
})

# Convert a data.frame/list of placements to the shape payload expected by the front-end
# Expected DB columns (if available): PlacementID, SiloID, ShapeTemplateID, CenterX, CenterY, Width, Height, Radius, RotationDeg
canvas_utils_coerce <- function(x) {
  if (is.null(x)) return(list())
  if (is.list(x) && !is.data.frame(x)) {
    # assume already shape-like
    return(x)
  }
  if (!nrow(as.data.frame(x))) return(list())
  
  df <- as.data.frame(x, stringsAsFactors = FALSE)
  
  # Fallback defaults
  has <- function(nm) nm %in% names(df)
  
  # Build minimal shapes; prefer circles if Radius present, else rects with Width/Height, else small dots
  shapes <- lapply(seq_len(nrow(df)), function(i) {
    row <- df[i, , drop = FALSE]
    id   <- row[[if (has("PlacementID")) "PlacementID" else if (has("SiloID")) "SiloID" else 1]]
    code <- as.character(row[[if (has("SiloName")) "SiloName" else if (has("TemplateCode")) "TemplateCode" else NA]])
    
    cx <- as.numeric(row[[if (has("CenterX")) "CenterX" else if (has("x")) "x" else NA]] %||% 0)
    cy <- as.numeric(row[[if (has("CenterY")) "CenterY" else if (has("y")) "y" else NA]] %||% 0)
    
    if (has("Radius") && !is.na(row$Radius)) {
      list(
        id = as.character(id),
        type = "circle",
        x = cx, y = cy,
        r = as.numeric(row$Radius %||% 20),
        code = code %||% as.character(id),
        fill = "rgba(13,110,253,0.10)",
        stroke = "rgba(13,110,253,0.9)"
      )
    } else {
      w <- as.numeric(row[[if (has("Width")) "Width" else if (has("w")) "w" else NA]] %||% 40)
      h <- as.numeric(row[[if (has("Height")) "Height" else if (has("h")) "h" else NA]] %||% 40)
      # Interpret CenterX/Y as center; convert to top-left for rect
      list(
        id = as.character(id),
        type = "rect",
        x = cx - w / 2,
        y = cy - h / 2,
        w = w, h = h,
        code = code %||% as.character(id),
        fill = "rgba(25,135,84,0.10)",
        stroke = "rgba(25,135,84,0.9)"
      )
    }
  })
  
  shapes
}

# Compute bounding box {x,y,w,h} of all shapes (in world units)
canvas_utils_bounds <- function(shapes) {
  if (is.null(shapes) || length(shapes) == 0) return(NULL)
  xs <- c(); ys <- c()
  for (s in shapes) {
    if (is.null(s$type)) next
    if (s$type == "circle") {
      xs <- c(xs, s$x - s$r, s$x + s$r)
      ys <- c(ys, s$y - s$r, s$y + s$r)
    } else if (s$type == "rect") {
      xs <- c(xs, s$x, s$x + s$w)
      ys <- c(ys, s$y, s$y + s$h)
    }
  }
  if (!length(xs) || !length(ys)) return(NULL)
  list(x = min(xs), y = min(ys), w = diff(range(xs)), h = diff(range(ys)))
}

# (Optional) Persist staged positions back to DB using parameterized updates
# `pending` is a named list: list("PlacementID" = list(x=..., y=...), ...)
canvas_utils_commit_pending <- function(pool, pending, table = "SiloOps.dbo.SiloPlacements",
                                        id_col = "PlacementID", x_col = "CenterX", y_col = "CenterY") {
  if (is.null(pool) || is.null(pending) || !length(pending)) return(invisible(0L))
  if (!exists("db_execute_params")) stop("db_execute_params() not found. Source R/db/connect_wrappers.R.")
  n <- 0L
  for (k in names(pending)) {
    pos <- pending[[k]]
    if (is.null(pos$x) || is.null(pos$y)) next
    sql <- sprintf("UPDATE %s SET %s = ?, %s = ? WHERE %s = ?",
                   table, x_col, y_col, id_col)
    n <- n + db_execute_params(sql, list(as.numeric(pos$x), as.numeric(pos$y), as.integer(k)))
  }
  invisible(n)
}


