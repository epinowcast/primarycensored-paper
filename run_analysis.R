#!/usr/bin/env Rscript

# Script to run the primarycensored targets analysis

cat("primarycensored Targets Analysis\n")
cat("================================\n\n")

# Check if running interactively or from command line
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  action <- "run"
} else {
  action <- args[1]
}

# Load targets
if (!requireNamespace("targets", quietly = TRUE)) {
  stop("The 'targets' package is required. Install it with: install.packages('targets')")
}

library(targets)

# Define actions
if (action == "render") {
  cat("Rendering _targets.Rmd...\n")
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("The 'rmarkdown' package is required. Install it with: install.packages('rmarkdown')")
  }
  rmarkdown::render("_targets.Rmd")
  
} else if (action == "run") {
  cat("Running targets pipeline...\n")
  # First render if _targets.R doesn't exist
  if (!file.exists("_targets.R")) {
    cat("_targets.R not found. Rendering _targets.Rmd first...\n")
    rmarkdown::render("_targets.Rmd")
  }
  tar_make()
  
} else if (action == "visualize") {
  cat("Creating pipeline visualization...\n")
  tar_visnetwork()
  
} else if (action == "progress") {
  cat("Pipeline progress:\n")
  print(tar_progress())
  
} else if (action == "clean") {
  cat("This will delete all computed results. Are you sure? (yes/no): ")
  response <- readline()
  if (tolower(response) == "yes") {
    cat("Cleaning targets cache...\n")
    tar_destroy()
  } else {
    cat("Clean cancelled.\n")
  }
  
} else {
  cat("Unknown action:", action, "\n")
  cat("Available actions: render, run, visualize, progress, clean\n")
}

cat("\nDone!\n")