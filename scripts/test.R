#!/usr/bin/env Rscript

# Run all tests using testthat
library(devtools)
library(testthat)

cat("🧪 Running tests...\n")

# Run tests
test_results <- test()

cat("✅ Tests completed\n") 