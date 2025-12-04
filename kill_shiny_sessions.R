# Helper script to kill any zombie Shiny/R sessions
# Run this if you get port conflicts or "R session disconnected" errors

cat("=== Killing R/Shiny processes ===\n")

# Windows: Kill R processes
system("taskkill /F /IM rsession.exe 2>nul", ignore.stderr = TRUE, ignore.stdout = TRUE)
system("taskkill /F /IM Rterm.exe 2>nul", ignore.stderr = TRUE, ignore.stdout = TRUE)
system("taskkill /F /IM Rgui.exe 2>nul", ignore.stderr = TRUE, ignore.stdout = TRUE)

Sys.sleep(1)

cat("Done. All R/Shiny sessions terminated.\n")
cat("You can now restart R cleanly.\n")
