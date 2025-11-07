field <- function(name, type,
                  title = NULL, enum = NULL, source = NULL,
                  min = NULL, max = NULL, default = NULL,
                  group = NULL, column = NULL, fullWidth = FALSE,
                  format = NULL, widget = NULL) {
  # ---- normalize "friendly" types to JSON Schema types ----
  base_type <- type
  fmt <- format
  wid <- widget
  
  if (type %in% c("select", "color", "text", "textarea", "password",
                  "email", "url", "date", "date-time")) {
    base_type <- "string"
    if (type == "color")     fmt <- "color"
    if (type == "date")      fmt <- "date"
    if (type == "date-time") fmt <- "date-time"
    if (type == "textarea")  wid <- "textarea"
    if (type == "password")  wid <- "password"
  }
  if (type %in% c("checkbox","bool","boolean")) {
    base_type <- "boolean"
  }
  if (type %in% c("switch","toggle")) {        # ⬅️ NEW alias for switch
    base_type <- "boolean"
    wid <- f_or(wid, "toggle")                 # use our ToggleWidget
  }
  
  # Fill enum from source for selects
  if (type == "select" && is.null(enum) && !is.null(source)) {
    enum <- if (is.function(source)) source() else source
  }
  
  list(
    kind      = "field",
    name      = name,
    type      = base_type,
    format    = fmt,
    widget    = wid,
    title     = title,
    enum      = enum,
    min       = min,
    max       = max,
    default   = default,
    group     = group,
    column    = column,
    fullWidth = isTRUE(fullWidth)
  )
}

group <- function(name, title = NULL, collapsible = FALSE, collapsed = FALSE, column = NULL) {
  list(
    kind        = "group",
    name        = name,
    title       = f_or(title, name),
    collapsible = isTRUE(collapsible),
    collapsed   = isTRUE(collapsed),
    column      = column
  )
}

.set_nested <- function(obj, path, value) {
  if (length(path) == 1) { obj[[path]] <- value; return(obj) }
  head <- path[1]; tail <- path[-1]
  obj[[head]] <- .set_nested(f_or(obj[[head]], list()), tail, value)
  obj
}

compile_rjsf <- function(title, props, groups = list(), columns = 1, hide_submit = TRUE) {
  gmap <- setNames(groups, vapply(groups, `[[`, "", "name"))
  
  schema   <- list(title = title, type = "object", properties = list())
  uiSchema <- list()
  formData <- list()
  
  uiSchema[["ui:options"]] <- list(columns = columns)
  if (hide_submit) uiSchema[["ui:submitButtonOptions"]] <- list(norender = TRUE)
  
  ensure_group <- function(gname) {
    if (is.null(schema$properties[[gname]])) {
      ginfo <- gmap[[gname]]
      schema$properties[[gname]] <<- list(
        type = "object",
        title = f_or(ginfo$title, gname),
        properties = list()
      )
      uiSchema[[gname]] <<- f_or(uiSchema[[gname]], list())
      uiSchema[[gname]][["ui:options"]] <<- modifyList(
        f_or(uiSchema[[gname]][["ui:options"]], list()),
        list(
          collapsible = isTRUE(ginfo$collapsible),
          collapsed   = isTRUE(ginfo$collapsed),
          column      = ginfo$column
        )
      )
    }
  }
  
  for (g in groups) ensure_group(g$name)
  
  for (f in props) {
    stopifnot(identical(f$kind, "field"))
    fs <- list(type = f$type)
    if (!is.null(f$format))   fs$format   <- f$format
    if (!is.null(f$title))    fs$title    <- f$title
    if (!is.null(f$enum))     fs$enum     <- f$enum
    if (!is.null(f$min))      fs$minimum  <- f$min
    if (!is.null(f$max))      fs$maximum  <- f$max
    if (!is.null(f$default))  fs$default  <- f$default

    set_field_ui <- function(root, name) {
      # Initialize field ui if needed
      if (is.null(root[[name]])) root[[name]] <- list()

      # ui:options (column/fullWidth)
      if (!is.null(f$column) || isTRUE(f$fullWidth)) {
        opts <- list()
        if (!is.null(f$column))   opts$column    <- f$column
        if (isTRUE(f$fullWidth))  opts$fullWidth <- TRUE
        root[[name]][["ui:options"]] <- modifyList(
          f_or(root[[name]][["ui:options"]], list()),
          opts
        )
      }
      # ui:widget (e.g., textarea/password)
      if (!is.null(f$widget)) {
        root[[name]][["ui:widget"]] <- f$widget
      }
      root
    }
    
    if (!is.null(f$group)) {
      ensure_group(f$group)
      schema$properties[[f$group]]$properties[[f$name]] <- fs
      uiSchema[[f$group]] <- set_field_ui(uiSchema[[f$group]], f$name)
      if (!is.null(f$default)) {
        formData[[f$group]] <- f_or(formData[[f$group]], list())
        formData[[f$group]][[f$name]] <- f$default
      }
    } else {
      schema$properties[[f$name]] <- fs
      uiSchema <- set_field_ui(uiSchema, f$name)
      if (!is.null(f$default)) formData[[f$name]] <- f$default
    }
  }
  
  list(schema = schema, uiSchema = uiSchema, formData = formData)
}
