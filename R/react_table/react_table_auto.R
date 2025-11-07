# R/react_table/rjsf_auto.R
suppressPackageStartupMessages({ library(jsonlite) })

# ---- 1) Compile DSL and return (schema, uiSchema) with sane defaults ----------
rjsf_auto_compile <- function(fields, groups = list(),
                              title = NULL, columns = 1,
                              root_order = NULL,
                              numeric_as = c(),          # e.g. c("DefaultBorderPx")
                              widgets = list(),          # named list of ui widgets by path
                              static_fields = c(),       # e.g. c("ContainerTypeID","Meta.CreatedAt")
                              hidden_fields = c()        # e.g. c("RowVer","Meta.InternalNote")
) {
  dsl <- compile_rjsf(
    title   = title,
    columns = columns,
    props   = fields,
    groups  = groups
  )
  
  # Enforce integer/number types in schema if requested
  for (nm in numeric_as) {
    # path can be "Graphics.DefaultBorderPx" or "DefaultBorderPx"
    parts <- strsplit(nm, "\\.")[[1]]
    cursor <- dsl$schema$properties
    if (length(parts) == 1) {
      if (!is.null(cursor[[parts[1]]])) cursor[[parts[1]]]$type <- "integer"
    } else {
      # descend into object properties
      for (i in seq_len(length(parts) - 1)) {
        obj <- parts[i]
        if (is.null(cursor[[obj]]$properties)) break
        cursor <- cursor[[obj]]$properties
      }
      leaf <- tail(parts, 1)
      if (!is.null(cursor[[leaf]])) cursor[[leaf]]$type <- "integer"
    }
  }
  
  # Attach widgets (uiSchema) by path
  ui <- f_or(dsl$uiSchema, list())

  # Helper to build nested list from path
  build_nested <- function(path_parts, value) {
    if (length(path_parts) == 1) {
      result <- list()
      result[[path_parts]] <- value
      return(result)
    } else {
      result <- list()
      result[[path_parts[1]]] <- build_nested(path_parts[-1], value)
      return(result)
    }
  }

  # Helper to get existing value at path
  get_ui_at <- function(path_parts) {
    current <- ui
    for (p in path_parts) {
      if (is.null(current[[p]])) return(list())
      current <- current[[p]]
    }
    current
  }

  set_ui_at <- function(path, val) {
    parts <- strsplit(path, "\\.")[[1]]

    # Get existing value at this path
    existing <- get_ui_at(parts)

    # Merge with new value
    merged <- modifyList(existing, val, keep.null = TRUE)

    # Build nested structure
    nested <- build_nested(parts, merged)

    # Merge into ui
    ui <<- modifyList(ui, nested, keep.null = TRUE)
  }
  
  # Static/plaintext fields
  for (p in static_fields) {
    set_ui_at(p, list("ui:field" = "plaintext"))
  }
  # Hidden fields
  for (p in hidden_fields) set_ui_at(p, list("ui:widget" = "hidden"))
  # Custom widgets
  for (nm in names(widgets)) set_ui_at(nm, widgets[[nm]])
  
  # Root layout hints
  ui[["ui:options"]] <- modifyList(f_or(ui[["ui:options"]], list()), list(columns = columns), keep.null = TRUE)
  
  # ui:order (explicit control; groups usually last)
  if (!is.null(root_order)) {
    ui[["ui:order"]] <- c(root_order, "*")
  }

  list(schema = dsl$schema, uiSchema = ui)
}

# ---- 2) Prepare formData: coerce, format, and nest by group paths ------------
rjsf_auto_formdata <- function(df_row,
                               nest = list(),         # named list path -> character vector of field names
                               formatters = list(),   # path -> function(val) returning string
                               integers = c(),        # vector of field paths that must be integer
                               drop_root = TRUE       # remove root copies after nesting
) {
  if (is.null(df_row) || !nrow(df_row)) return(list())
  x <- as.list(df_row[1, , drop = TRUE])
  
  # Apply formatters (e.g., "Meta.CreatedAt" = function(v) format(v, "%F %T"))
  for (p in names(formatters)) {
    fn <- formatters[[p]]
    val <- rjsf_get(x, p)
    if (!is.null(val)) x <- rjsf_set(x, p, fn(val))
  }
  
  # Coerce integers
  for (p in integers) {
    val <- rjsf_get(x, p)
    if (!is.null(val)) {
      val <- suppressWarnings(as.integer(trimws(as.character(val))))
      x <- rjsf_set(x, p, val)
    }
  }
  
  # Nest fields
  for (path in names(nest)) {
    keys <- nest[[path]]
    obj  <- list()
    for (k in keys) {
      if (!is.null(x[[k]])) obj[[k]] <- x[[k]]
    }
    if (length(obj)) x <- rjsf_set(x, path, obj)
    if (drop_root) for (k in keys) x[[k]] <- NULL
  }
  
  # NA -> null
  fromJSON(toJSON(x, na = "null", auto_unbox = TRUE))
}

# helpers to get/set deep paths like "Meta.CreatedAt" / "Graphics.DefaultBorderPx"
rjsf_get <- function(obj, path) {
  parts <- strsplit(path, "\\.")[[1]]
  cur <- obj
  for (p in parts) {
    if (is.null(cur) || is.null(cur[[p]])) return(NULL)
    cur <- cur[[p]]
  }
  cur
}
rjsf_set <- function(obj, path, value) {
  parts <- strsplit(path, "\\.")[[1]]
  if (length(parts) == 1) { obj[[parts]] <- value; return(obj) }
  headp <- head(parts, -1); leaf <- tail(parts, 1)
  cur <- obj
  for (p in headp) {
    cur[[p]] <- f_or(cur[[p]], list())
    cur <- cur[[p]]
  }
  cur[[leaf]] <- value
  # write back down the chain
  for (i in rev(seq_along(headp))) {
    parent <- if (i == 1) obj else rjsf_get(obj, paste(headp[seq_len(i - 1)], collapse = "."))
    parent[[headp[i]]] <- if (i == length(headp)) cur else rjsf_get(obj, paste(headp[seq_len(i)], collapse = "."))
    obj <- if (i == 1) parent else rjsf_set(obj, paste(headp[seq_len(i - 1)], collapse = "."), parent[[headp[i]]])
  }
  obj
}
