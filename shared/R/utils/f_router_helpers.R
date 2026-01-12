# f_router_helpers.R - Hash routing and deep-linking helpers

# Parse "#/section/sub?key=val&item=123" into list(parts=..., qs=list(...))
f_hash_parse <- function(h, default = "#/sites") {
  h <- f_or(h, default)
  h <- sub("^#/", "", h)
  parts_q <- strsplit(h, "?", fixed = TRUE)[[1]]
  path <- parts_q[1]
  qs   <- if (length(parts_q) >= 2) parts_q[2] else NA_character_
  parts <- Filter(nzchar, strsplit(path, "/", fixed = TRUE)[[1]])
  qs_list <- list()
  if (!is.na(qs) && nzchar(qs)) {
    kv <- strsplit(qs, "&", fixed = TRUE)[[1]]
    for (p in kv) {
      y <- strsplit(p, "=", fixed = TRUE)[[1]]
      if (length(y) >= 1) {
        k <- utils::URLdecode(y[1])
        v <- utils::URLdecode(ifelse(length(y) >= 2, y[2], ""))
        qs_list[[k]] <- v
      }
    }
  }
  list(parts = parts, qs = qs_list)
}

# Build a hash from parts and optional query list
f_hash_build <- function(parts, qs = NULL) {
  p <- paste(c("", parts), collapse = "/")
  if (!is.null(qs) && length(qs)) {
    q <- paste(paste0(names(qs), "=", utils::URLencode(as.character(qs), reserved = TRUE)), collapse = "&")
    paste0("#", p, "?", q)
  } else paste0("#", p)
}

# Enable deep-linking for a module.
# route_root: e.g. "siloes" or c("sites","areas")
# get_id(): returns current selected ID
# set_id(id): selects an item by ID
# id_param = FALSE → use path (#/siloes/ID)
# id_param = TRUE  → use query (#/siloes?item=ID)
enable_deeplink <- function(session, route_root, get_id, set_id, id_param = FALSE) {
  root <- as.character(route_root)

  # 1) URL → select item
  observeEvent(session$input$f_route, ignoreInit = TRUE, {
    h  <- session$input$f_route
    ph <- f_hash_parse(h)
    parts <- ph$parts
    if (length(parts) >= length(root) && identical(parts[seq_along(root)], root)) {
      id <- NULL
      if (isTRUE(id_param)) {
        id <- ph$qs$item
        if (!is.null(id) && length(id) == 0) id <- NULL
      } else if (length(parts) >= length(root) + 1) {
        id <- parts[length(root) + 1]
      }
      if (!is.null(id) && !identical(get_id(), id)) {
        set_id(id)
      }
    }
  })

  # 2) Selection → URL
  observe({
    id <- get_id()
    if (is.null(id) || is.na(id) || identical(id, "")) return()
    h <- if (isTRUE(id_param)) {
      f_hash_build(root, qs = list(item = id))
    } else {
      f_hash_build(c(root, id))
    }
    session$sendCustomMessage("set-hash", list(h = h))
  })
}
