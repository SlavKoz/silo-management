# Build grouped choices + icons/images from a data.frame (order-safe, array-safe)
rs_choices_from_df <- function(df, value, label = value, group = NULL,
                               icon = NULL, image = NULL, sort = TRUE) {
  stopifnot(is.data.frame(df), value %in% names(df))
  
  # base columns, character, and keep only rows with a value
  val <- as.character(df[[value]])
  keep <- !is.na(val)
  val <- val[keep]
  
  lab <- if (is.null(label)) val else as.character(df[[label]][keep])
  grp <- if (!is.null(group)) as.character(df[[group]][keep]) else NULL
  ico <- if (!is.null(icon))  as.character(df[[icon]][keep])  else NULL
  img <- if (!is.null(image)) as.character(df[[image]][keep]) else NULL
  
  # ordered working frame (so ALL vectors stay in sync)
  d <- data.frame(
    val = val,
    lab = ifelse(is.na(lab), val, lab),
    grp = if (!is.null(grp)) grp else NA_character_,
    ico = if (!is.null(ico)) ico else NA_character_,
    img = if (!is.null(img)) img else NA_character_,
    stringsAsFactors = FALSE
  )
  
  # optional sorting
  if (isTRUE(sort)) {
    if (!is.null(group)) d <- d[order(d$grp, d$lab), , drop = FALSE] else d <- d[order(d$lab), , drop = FALSE]
  }
  
  # helper: leaves [{value,label}, ...]
  mk_leaves <- function(rows) {
    unname(Map(function(v, l) list(value = v, label = l), rows$val, rows$lab))
  }
  
  # CHOICES: grouped or flat (always arrays via unname())
  if (!is.null(group)) {
    sp <- split(seq_len(nrow(d)), d$grp, drop = TRUE)
    choices <- unname(lapply(names(sp), function(g) {
      rows <- d[sp[[g]], , drop = FALSE]
      list(label = as.character(g), options = mk_leaves(rows))
    }))
  } else {
    choices <- mk_leaves(d)
  }
  
  # ICONS / IMAGES: maps {value -> icon/url}, keep only non-NA
  icons  <- if (!is.null(icon))  { idx <- !is.na(d$ico); stats::setNames(as.list(d$ico[idx]),  d$val[idx]) } else NULL
  images <- if (!is.null(image)) { idx <- !is.na(d$img); stats::setNames(as.list(d$img[idx]),  d$val[idx]) } else NULL
  
  list(choices = choices, icons = icons, images = images)
}

# DBI variant (unchanged usage)
rs_choices_from_sql <- function(con, sql, value, label = value, group = NULL,
                                icon = NULL, image = NULL, sort = TRUE) {
  df <- DBI::dbGetQuery(con, sql)
  rs_choices_from_df(df, value, label, group, icon, image, sort)
}

# R/react_table/react_table_helpers.R  (append)

# Convert the DSL 'compile_rjsf' result (object schema) into an array-of-objects schema.
dsl_to_array_schema <- function(dsl, title = NULL) {
  stopifnot(is.list(dsl), !is.null(dsl$schema))
  list(
    type  = "array",
    title = title,
    items = dsl$schema
  )
}

# NA-safe row conversion for formData (array or single object)
df_rows_as_list <- function(df) {
  if (!NROW(df)) return(list())
  df[] <- lapply(df, function(x) if (is.factor(x)) as.character(x) else x)
  df[] <- lapply(df, function(x) {
    if (inherits(x, "POSIXct") || inherits(x, "POSIXt"))
      return(strftime(x, "%Y-%m-%d %H:%M:%S"))
    x
  })
  jsonlite::fromJSON(jsonlite::toJSON(df, dataframe = "rows", na = "null", auto_unbox = TRUE))
}

