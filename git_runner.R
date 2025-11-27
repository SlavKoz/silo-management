

# commit_all.R
message("Committing current project to git...")

# Basic sanity check
if (!dir.exists(".git")) {
  stop("This folder is not a Git repository.")
}

# Helper to run a system command and capture errors
run <- function(cmd) {
  status <- system(cmd)
  if (status != 0) stop("Command failed: ", cmd, call. = FALSE)
}

# Detect current branch
branch <- system("git rev-parse --abbrev-ref HEAD", intern = TRUE)

# Stage everything
run("git add -A")

# If nothing staged, exit quietly
nothing_to_commit <- system("git diff --cached --quiet", ignore.stdout = TRUE, ignore.stderr = TRUE)
if (nothing_to_commit == 0) {
  message("No changes to commit.")
  quit(save = "no", status = 0)
}

# Build commit message (from args or timestamp)
args <- commandArgs(trailingOnly = TRUE)
msg <- if (length(args)) paste(args, collapse = " ") else paste0("Auto-commit ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))

run(paste("git commit -m", shQuote(msg)))
run(paste("git push -u origin", shQuote(branch)))

message("Done.")

