who_defined <- function(name) {
  stopifnot(is.character(name), length(name) == 1)
  where <- find(name)
  cat("Found in:", paste(where, collapse = " | "), "\n")
  obj <- getAnywhere(name)
  if (length(obj$objs) >= 1) {
    f <- obj$objs[[1]]
    env <- environment(f)
    cat("Environment:", environmentName(env), "\n")
    fn <- try(utils::getSrcFilename(f, full.names = TRUE), silent = TRUE)
    ln <- try(utils::getSrcLocation(f), silent = TRUE)
    if (!inherits(fn, "try-error") && !is.na(fn)) cat("File:", fn, "\n")
    if (!inherits(ln, "try-error")) cat("Line:", paste(ln, collapse = ","), "\n")
  }
  invisible(where)
}
