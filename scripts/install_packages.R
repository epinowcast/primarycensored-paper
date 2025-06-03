#!/usr/bin/env Rscript

# Install/restore R packages using renv
# This script handles all package installation and cmdstan setup

message("📦 Managing R packages with renv...")

# Install pak first for faster package operations
if (!requireNamespace("pak", quietly = TRUE)) {
  message("Installing pak for faster package operations...")
  install.packages("pak", repos = "https://cloud.r-project.org")
}

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

if (file.exists("renv.lock")) {
  # Restore from lockfile
  message("Restoring packages from renv.lock...")
  renv::restore(prompt = FALSE)
} else {
  # No lockfile, install required packages
  message("No renv.lock found. Installing dependencies from DESCRIPTION...")

  # Install DESCRIPTION dependencies (including remotes)
  message("Installing dependencies from DESCRIPTION...")
  renv::install(".", dependencies = TRUE)

  # Create initial lockfile
  message("Creating renv.lock...")
  renv::snapshot(prompt = FALSE)
}

# Ensure all packages are properly loaded before proceeding
message("Ensuring all dependencies are available...")

# Special handling for cmdstanr - install CmdStan v2.36.0
# Check again after dependencies are installed to ensure cmdstanr is available
if (requireNamespace("cmdstanr", quietly = TRUE)) {
  message("Checking CmdStan installation...")
  tryCatch({
    version <- cmdstanr::cmdstan_version()
    message("CmdStan version: ", version)
  }, error = function(e) {
    message("Installing CmdStan v2.36.0...")
    cmdstanr::install_cmdstan(
      version = "2.36.0"
    )
    message("CmdStan v2.36.0 installed successfully")
  })
} else {
  message("cmdstanr not available - skipping CmdStan installation")
}

message("✅ Package management complete")