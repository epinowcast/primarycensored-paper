#!/usr/bin/env Rscript

# Restore R packages from renv lockfile
# This script handles package restoration and cmdstan setup

cat("📦 Restoring R packages from lockfile...\n")

# Install pak first for faster package operations
if (!requireNamespace("pak", quietly = TRUE)) {
  message("Installing pak for faster package operations...")
  install.packages("pak", repos = "https://cloud.r-project.org")
}

# Ensure renv is available
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Restore packages from lockfile
renv::restore(prompt = FALSE)

# Special handling for cmdstanr - install CmdStan v2.36.0
# Check after dependencies are restored to ensure cmdstanr is available
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

cat("✅ Dependencies restored\n")
