# R/utils/icons.R
# Centralized icon registry and helpers (emoji/Unicode for now)

container_type_icons <- function() {
  c(
    # Shape-bottom semantics (more intuitive)
    HOPPER   = "🔻",  # down-pointing funnel/triangle
    FLAT     = "▭",  # flat rectangle/plate
    
    # Common/legacy (kept)
    BIN      = "🧱",
    TANK     = "⭕",
    MIXER    = "🌀",
    
    # Your requested types
    SILO     = "🏗️", # storage silo
    HOLDING  = "📦",  # holding/bin
    DRYING   = "🔥",  # drying bin
    BULKTANK = "🛢️", # external bulk tank
    NEWCODE  = "🧩"   # placeholder/new
  )
}

bottom_type_icons <- function() {
  c(
    HOPPER = "🔻",
    FLAT   = "▭"
  )
}

icon_for_container <- function(type_code = NULL, bottom_type = NULL, type_name = NULL) {
  ct <- container_type_icons()
  bt <- bottom_type_icons()
  
  if (!is.null(type_code) && nzchar(type_code)) {
    key <- toupper(type_code)
    if (!is.na(ct[[key]])) return(ct[[key]])
  }
  
  nm <- if (!is.null(type_name) && nzchar(type_name)) toupper(type_name) else ""
  if (nzchar(nm)) {
    if (grepl("SILO", nm, fixed = TRUE))        return(ct[["SILO"]])
    if (grepl("HOLD", nm, fixed = TRUE))        return(ct[["HOLDING"]])
    if (grepl("DRY", nm,  fixed = TRUE))        return(ct[["DRYING"]])
    if (grepl("BULK", nm, fixed = TRUE) ||
        grepl("TANK", nm, fixed = TRUE))        return(ct[["BULKTANK"]])
  }
  
  if (!is.null(bottom_type) && nzchar(bottom_type)) {
    key <- toupper(bottom_type)
    if (!is.na(bt[[key]])) return(bt[[key]])
    if (!is.na(ct[[key]])) return(ct[[key]])
  }
  
  "◻️"
}

icon_enum_options_for <- function(values, labels = NULL) {
  if (is.null(labels)) labels <- as.character(values)
  stopifnot(length(values) == length(labels))
  mapply(function(v, lab) {
    list(
      value = v,
      label = sprintf("%s  %s", icon_for_container(type_code = v, type_name = lab), lab)
    )
  }, values, labels, SIMPLIFY = FALSE, USE.NAMES = FALSE)
}
