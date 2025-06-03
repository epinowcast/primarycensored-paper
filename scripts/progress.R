#!/usr/bin/env Rscript

# Show pipeline progress
library(targets)

cat("Checking pipeline progress...\n")

# Show progress
progress_data <- tar_progress()
print(progress_data)

# Show summary
cat("\nPipeline summary:\n")
tar_progress_summary()

cat("✅ Progress check completed\n")
