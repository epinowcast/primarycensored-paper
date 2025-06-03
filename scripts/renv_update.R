#!/usr/bin/env Rscript

# Update renv lockfile with current package versions
library(renv)

cat("📸 Updating renv lockfile...\n")

# Snapshot current state, including all development packages
cat("Snapshotting current package state...\n")
snapshot(prompt = FALSE)

cat("✅ renv.lock updated\n") 