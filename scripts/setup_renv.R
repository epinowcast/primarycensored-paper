#!/usr/bin/env Rscript

# Initialize renv for dependency management
# This script sets up renv if not already initialized

message("🔧 Initializing renv...")

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

# Initialize renv if not already done
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
  message("renv initialized. Use task install to add packages.")
} else {
  message("renv already initialized.")
}