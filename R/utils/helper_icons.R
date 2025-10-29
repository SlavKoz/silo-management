# R/utils/helper_icons.R

# Lightweight constant for Iconify API base
ICONIFY_BASE <- "https://api.iconify.design"

# --- Iconify search (exactly like iconstest; returns "prefix:name") ---
# --- Iconify search (iconstest-compatible) ---
# returns a character vector of "prefix:name"
iconify_search_page <- function(query, start = 0, limit = 200) {
  resp <- try(httr::GET(
    sprintf("%s/search", ICONIFY_BASE),
    query = list(query = query, start = start, limit = limit)
  ), silent = TRUE)
  if (inherits(resp, "try-error") || httr::http_error(resp)) return(character(0))
  txt <- httr::content(resp, "text", encoding = "UTF-8")
  if (!is.character(txt) || !nzchar(txt)) return(character(0))
  j <- try(jsonlite::fromJSON(txt), silent = TRUE)
  if (inherits(j, "try-error") || is.null(j$icons)) return(character(0))
  
  # j$icons can be a character vector or a list; coerce both safely
  if (is.character(j$icons)) return(j$icons)
  as.character(unlist(j$icons, use.names = FALSE))
}

# Accepts 'limit' (as your server expects), pages if needed, returns unique ids
iconify_search_all <- function(query, limit = 24, page_size = 200, max_results = 5000) {
  if (is.null(query) || !nzchar(query)) return(character(0))
  limit <- as.integer(limit)
  page_size <- as.integer(page_size)
  max_results <- as.integer(max_results)
  
  out <- character(0)
  start <- 0
  want <- min(limit, max_results)
  
  repeat {
    chunk_limit <- min(page_size, want - length(out))
    if (chunk_limit <= 0) break
    ids <- iconify_search_page(query = query, start = start, limit = chunk_limit)
    if (!length(ids)) break
    out <- unique(c(out, ids))
    start <- start + length(ids)
    if (length(ids) < chunk_limit || length(out) >= want) break
  }
  
  utils::head(out, want)
}



# ---- Fetch SVG by "prefix:name" or separate args ----
fetch_iconify_svg <- function(id_or_prefix, name = NULL) {
  if (!is.null(name)) {
    prefix <- id_or_prefix
    icon   <- name
  } else {
    parts <- strsplit(id_or_prefix, ":", fixed = TRUE)[[1]]
    if (length(parts) != 2) return("")
    prefix <- parts[1]; icon <- parts[2]
  }
  url <- sprintf("%s/%s/%s.svg", ICONIFY_BASE, prefix, icon)
  txt <- try(paste(readLines(url, warn = FALSE), collapse = "\n"), silent = TRUE)
  if (inherits(txt, "try-error")) "" else txt
}

# ---- Sanitize SVG (xml2-based) ----
sanitize_svg <- function(svg_txt) {
  if (is.null(svg_txt) || !nzchar(svg_txt)) return("")
  # Parse leniently; avoid HTML entity issues
  doc <- try(xml2::read_xml(svg_txt, options = c("NOBLANKS", "RECOVER")), silent = TRUE)
  if (inherits(doc, "try-error")) return("")
  
  # Remove script nodes
  scripts <- xml2::xml_find_all(doc, ".//script")
  xml2::xml_remove(scripts)
  
  # Strip on* event attributes everywhere
  nodes <- xml2::xml_find_all(doc, "//*")
  for (n in nodes) {
    attrs <- xml2::xml_attrs(n)
    if (length(attrs)) {
      # remove width/height at root and any on* attributes
      drop <- names(attrs)[grepl("^on", names(attrs), ignore.case = TRUE) | names(attrs) %in% c("width", "height")]
      for (a in drop) xml2::xml_attr(n, a) <- NULL
    }
  }
  # Ensure svg root has viewBox (if missing, try to infer)
  root <- xml2::xml_find_first(doc, ".")
  if (xml2::xml_name(root) == "svg") {
    vb <- xml2::xml_attr(root, "viewBox")
    if (is.na(vb) || !nzchar(vb)) {
      # Best effort: if width/height were present in original, they’re already removed.
      # We keep as-is; many Iconify SVGs already include viewBox.
      # (Optional: parse path bbox to compute viewBox – omitted for speed.)
    }
  }
  
  as.character(doc)
}

# ---- Recolor SVG (preserve fill='none'; change currentColor/fill/stroke) ----
recolor_svg <- function(svg_txt, color_hex) {
  if (is.null(svg_txt) || !nzchar(svg_txt)) return("")
  if (is.null(color_hex) || !nzchar(color_hex)) return(svg_txt)
  x <- svg_txt
  # Normalize currentColor
  x <- gsub("currentColor", color_hex, x, fixed = TRUE)
  # Replace strokes
  x <- gsub('stroke="#?[0-9a-fA-F]{3,8}"', paste0('stroke="', color_hex, '"'), x)
  # Replace fills (not none)
  x <- gsub('fill="(?!none)#[^"]+"', paste0('fill="', color_hex, '"'), x, perl = TRUE)
  x
}

# ---- Rasterize SVG to raw PNG (24/32/48/64...) ----
svg_to_png_raw <- function(svg_txt, size = 64) {
  if (is.null(svg_txt) || !nzchar(svg_txt)) stop("Empty SVG")
  if (!requireNamespace("magick", quietly = TRUE) && !requireNamespace("rsvg", quietly = TRUE)) {
    stop("Need magick or rsvg installed to rasterize SVG")
  }
  if (requireNamespace("magick", quietly = TRUE)) {
    img <- magick::image_read_svg(svg_txt, width = size, height = size)
    return(magick::image_write(img, format = "PNG"))
  } else {
    tmp <- tempfile(fileext = ".svg")
    on.exit(unlink(tmp), add = TRUE)
    writeLines(svg_txt, tmp, useBytes = TRUE)
    return(rsvg::rsvg_png(tmp, width = size, height = size))
  }
}

# ---- Encode raw -> base64 (no data: URI prefix) ----
raw_to_b64 <- function(xraw) {
  if (is.null(xraw)) return("")
  base64enc::base64encode(xraw)
}

# ---- Build a DB-ready payload (icons table contract) ----
# Returns a named list you can pass to insert_icon(conn, payload)
# Fields: icon_name, svg, png_24_b64, png_32_b64, png_48_b64
build_payload <- function(icon_name, svg_txt, color_hex = NULL) {
  if (!nzchar(svg_txt)) stop("Empty SVG")
  
  # Only generate one PNG size for thumbnails
  png32 <- raw_to_b64(svg_to_png_raw(svg_txt, size = 32))
  
  list(
    icon_name = icon_name,
    svg = svg_txt,
    png_32_b64 = png32,
    primary_color = color_hex  
  )
}