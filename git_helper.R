# git_helper.R
# Lightweight git operations for R console to save tokens
# Usage: source("git_helper.R")

#' Show git status (short format)
git_status <- function() {
  cat("\n=== Git Status ===\n")
  system("git status --short")
  cat("\n")

  # Show branch info
  branch <- system("git branch --show-current", intern = TRUE)
  cat("Branch:", branch, "\n")

  # Show commits ahead/behind
  ahead <- system("git rev-list --count @{u}..HEAD 2>nul", intern = TRUE)
  if (length(ahead) && nzchar(ahead)) {
    cat("Commits ahead:", ahead, "\n")
  }

  invisible(NULL)
}

#' Show recent commits
git_log <- function(n = 10) {
  cat("\n=== Recent Commits ===\n")
  cmd <- sprintf("git log --oneline -%d", n)
  system(cmd)
  cat("\n")
  invisible(NULL)
}

#' Stage files
#' @param files Character vector of file paths, or "." for all, or "-A" for all including deletions
git_add <- function(files = ".") {
  if (length(files) == 1 && files == "-A") {
    cmd <- "git add -A"
  } else {
    files_quoted <- paste0('"', files, '"', collapse = " ")
    cmd <- paste("git add", files_quoted)
  }

  cat("Staging files...\n")
  result <- system(cmd)

  if (result == 0) {
    cat("✓ Files staged successfully\n\n")
    git_status()
  } else {
    cat("✗ Error staging files\n")
  }

  invisible(result == 0)
}

#' Commit staged changes
#' @param message Commit message (will be properly escaped)
#' @param coauthor Add Claude co-author tag (default: TRUE)
git_commit <- function(message, coauthor = TRUE) {
  if (missing(message) || !nzchar(message)) {
    stop("Commit message is required")
  }

  # Add co-author if requested
  if (coauthor) {
    message <- paste0(
      message,
      "\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)",
      "\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
    )
  }

  # Write message to temp file to avoid escaping issues
  tmp_file <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp_file), add = TRUE)
  writeLines(message, tmp_file)

  cat("Committing changes...\n")
  cmd <- sprintf('git commit -F "%s"', tmp_file)
  result <- system(cmd)

  if (result == 0) {
    cat("\n✓ Commit successful\n\n")
    git_log(3)
  } else {
    cat("\n✗ Commit failed\n")
  }

  invisible(result == 0)
}

#' Show file change summary (not full diff)
git_diff_summary <- function() {
  cat("\n=== Changed Files Summary ===\n")
  system("git diff --stat")
  cat("\n")
  invisible(NULL)
}

#' Quick commit workflow: add all + commit
#' @param message Commit message
#' @param coauthor Add Claude co-author tag (default: TRUE)
git_quick_commit <- function(message, coauthor = TRUE) {
  cat("\n=== Quick Commit Workflow ===\n\n")

  # Show what will be committed
  cat("Changes to be committed:\n")
  system("git status --short")
  cat("\n")

  # Confirm
  response <- readline("Proceed with commit? (y/n): ")
  if (!tolower(trimws(response)) %in% c("y", "yes")) {
    cat("Commit cancelled.\n")
    return(invisible(FALSE))
  }

  # Stage and commit
  if (git_add("-A")) {
    git_commit(message, coauthor = coauthor)
  }
}

#' Show help
git_help <- function() {
  cat("\n=== Git Helper Functions ===\n\n")
  cat("git_status()              - Show status (short format)\n")
  cat("git_log(n=10)             - Show recent commits\n")
  cat("git_add(files)            - Stage files ('.' or '-A' for all)\n")
  cat("git_commit(message)       - Commit with message\n")
  cat("git_diff_summary()        - Show changed files summary\n")
  cat("git_quick_commit(message) - Stage all + commit\n")
  cat("git_help()                - Show this help\n\n")

  cat("Examples:\n")
  cat('  git_status()\n')
  cat('  git_add(".")\n')
  cat('  git_commit("Fix bug in auth module")\n')
  cat('  git_quick_commit("Add new feature")\n\n')

  invisible(NULL)
}

# Show help on load
cat("\n✓ Git helper loaded. Type git_help() for available commands.\n\n")
