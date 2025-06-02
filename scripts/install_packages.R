#!/usr/bin/env Rscript

# Install/restore R packages using renv
# This script handles all package installation and cmdstan setup

message("📦 Managing R packages with renv...")

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
  
  # Install DESCRIPTION dependencies
  message("Installing dependencies from DESCRIPTION...")
  renv::install(".", dependencies = TRUE)
  
  # Install cmdstanr from GitHub (pinned to v0.9.0)
  message("Installing cmdstanr from GitHub (v0.9.0)...")
  renv::install("stan-dev/cmdstanr@v0.9.0")
  
  # Create initial lockfile
  message("Creating renv.lock...")
  renv::snapshot(prompt = FALSE)
}

# Always ensure local package dependencies are installed
message("Ensuring DESCRIPTION dependencies are up to date...")
renv::install(".", dependencies = TRUE)

# Special handling for cmdstanr - install CmdStan v2.36.0
if (requireNamespace("cmdstanr", quietly = TRUE)) {
  tryCatch({
    version <- cmdstanr::cmdstan_version()
    message("CmdStan version: ", version)
  }, error = function(e) {
    message("Installing CmdStan v2.36.0...")
    cmdstanr::install_cmdstan(
      version = "2.36.0",
      overwrite = TRUE
    )
    message("CmdStan v2.36.0 installed successfully")
  })
}

message("✅ Package management complete")