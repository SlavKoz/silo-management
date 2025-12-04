# Check shiny.semantic exported functions
library(shiny.semantic)

cat("=== All update* functions in shiny.semantic ===\n")
funcs <- ls("package:shiny.semantic")
update_funcs <- funcs[grepl("^update", funcs, ignore.case = TRUE)]
print(update_funcs)

cat("\n=== All dropdown* functions ===\n")
dropdown_funcs <- funcs[grepl("dropdown", funcs, ignore.case = TRUE)]
print(dropdown_funcs)
