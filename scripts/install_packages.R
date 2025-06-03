#!/usr/bin/env Rscript

# Install new R packages and add them to the project
# This script is for adding new dependencies, not restoring existing ones

library(renv)

cat("📦 Installing new packages...\n")

# Get command line arguments for packages to install
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cat("Usage: Rscript scripts/install_packages.R <package1> [package2] ...\n")
  cat("Example: Rscript scripts/install_packages.R dplyr ggplot2\n")
  quit(status = 1)
}

# Install the specified packages
for (pkg in args) {
  cat("Installing package:", pkg, "\n")
  renv::install(pkg)
}

cat("✅ New packages installed\n")
