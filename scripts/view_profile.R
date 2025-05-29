#!/usr/bin/env Rscript

# View previously saved profiling results
# This script loads and displays saved profiling data

message("📊 Loading profiling results...")

if (!file.exists("profile_results.rds")) {
  stop("No profiling results found. Run: task profile")
}

results <- readRDS("profile_results.rds")
print(results, aggregate = TRUE)
message("\n✅ Profile viewer opened in browser")