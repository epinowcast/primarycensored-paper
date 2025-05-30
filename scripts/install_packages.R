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
  message("No renv.lock found. Installing required packages...")
  
  # Regular CRAN packages
  cran_pkgs <- c("targets", "tarchetypes", "data.table", "ggplot2", "patchwork", 
                 "purrr", "here", "dplyr", "tidyr", "qs2", "crew", 
                 "primarycensored", "fitdistrplus", "profvis", 
                 "rmarkdown", "knitr", "visNetwork", "htmlwidgets", "tictoc",
                 "shiny")
  
  # Install CRAN packages
  renv::install(cran_pkgs)
  
  # Install cmdstanr from GitHub (pinned to v0.9.0)
  message("Installing cmdstanr from GitHub (v0.9.0)...")
  renv::install("stan-dev/cmdstanr@v0.9.0")
  
  # Create initial lockfile
  message("Creating renv.lock...")
  renv::snapshot(prompt = FALSE)
}

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