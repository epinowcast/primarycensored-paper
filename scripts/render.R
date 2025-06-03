#!/usr/bin/env Rscript

# Render the targets Rmarkdown document
library(rmarkdown)

cat("Rendering _targets.Rmd...\n")

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if custom parameters were provided
if (length(args) > 0) {
  params_str <- args[1]
  cat("Using custom parameters:", params_str, "\n")
  
  if (params_str == "test_mode=true") {
    custom_params <- list(test_mode = TRUE)
  } else {
    # Parse other parameter formats if needed
    custom_params <- list()
  }
  
  render("_targets.Rmd", params = custom_params)
} else {
  cat("Using default parameters\n")
  render("_targets.Rmd")
}

cat("✅ _targets.Rmd rendered successfully\n") 