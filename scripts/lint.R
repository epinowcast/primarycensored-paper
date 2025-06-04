#!/usr/bin/env Rscript

# Run R code linting
library(lintr)

cat("🔍 Running R code linting...\n")

# Lint entire package
cat("Linting package...\n")
lint_results <- lint_package()
print(lint_results)

# Count total issues
total_issues <- length(lint_results)

if (total_issues == 0) {
  cat("✅ No linting issues found\n")
} else {
  cat("⚠️ Found", total_issues, "linting issues\n")
  quit(status = 1)
}
