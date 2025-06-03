#!/usr/bin/env Rscript

# Run the targets pipeline
library(targets)

cat("Running targets pipeline...\n")

# Run the pipeline
tar_make()

cat("✅ Targets pipeline completed\n") 