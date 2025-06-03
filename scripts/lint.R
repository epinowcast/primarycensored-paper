#!/usr/bin/env Rscript

# Run R code linting
library(lintr)

cat("🔍 Running R code linting...\n")

# Lint R directory
cat("Linting R/ directory...\n")
lint_results_r <- lint_dir("R")
print(lint_results_r)

# Lint scripts directory
cat("Linting scripts/ directory...\n")
lint_results_scripts <- lint_dir("scripts")
print(lint_results_scripts)

# Lint tests directory
cat("Linting tests/ directory...\n")
lint_results_tests <- lint_dir("tests")
print(lint_results_tests)

# Lint _targets.Rmd
cat("Linting _targets.Rmd...\n")
lint_results_targets <- lint("_targets.Rmd")
print(lint_results_targets)

# Count total issues
total_issues <- length(lint_results_r) + length(lint_results_scripts) + 
                length(lint_results_tests) + length(lint_results_targets)

if (total_issues == 0) {
  cat("✅ No linting issues found\n")
} else {
  cat("⚠️ Found", total_issues, "linting issues\n")
  quit(status = 1)
} 