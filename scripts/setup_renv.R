#!/usr/bin/env Rscript

# Initialize renv for dependency management
# This script sets up renv if not already initialized

message("🔧 Initializing renv...")

# Install pak first for faster package operations
if (!requireNamespace("pak", quietly = TRUE)) {
  message("Installing pak for faster package operations...")
  install.packages("pak", repos = "https://cloud.r-project.org")
}

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