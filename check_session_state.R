# Diagnostic script to check R session state
# Run this after closing the app to see what persists

cat("=== ATTACHED PACKAGES ===\n")
print(search())

cat("\n=== SHINY OPTIONS ===\n")
shiny_opts <- options()[grep("^shiny", names(options()))]
if (length(shiny_opts) > 0) {
  print(shiny_opts)
}

cat("\n=== SHINY RESOURCE PATHS ===\n")
if (requireNamespace("shiny", quietly = TRUE)) {
  # Try to access internal resource paths
  tryCatch({
    paths <- shiny:::shinyOptions$resourcePaths
    if (!is.null(paths)) {
      print(paths)
    } else {
      cat("No custom resource paths registered\n")
    }
  }, error = function(e) {
    cat("Could not access resource paths\n")
  })
}

cat("\n=== GLOBAL ENVIRONMENT OBJECTS ===\n")
cat("Large objects (>100KB):\n")
obj_sizes <- sapply(ls(globalenv()), function(x) {
  object.size(get(x, envir = globalenv()))
})
large_objs <- obj_sizes[obj_sizes > 100000]
if (length(large_objs) > 0) {
  print(sort(large_objs, decreasing = TRUE))
} else {
  cat("None\n")
}

cat("\n=== SHINY.SEMANTIC LOADED? ===\n")
cat("shiny.semantic attached:", "package:shiny.semantic" %in% search(), "\n")

cat("\n=== RECOMMENDED CLEANUP ===\n")
cat("To clean session state, run:\n")
cat("  detach('package:shiny.semantic', unload = TRUE)\n")
cat("  rm(list = ls(globalenv()))\n")
cat("  gc()\n")
