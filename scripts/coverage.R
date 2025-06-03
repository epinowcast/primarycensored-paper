#!/usr/bin/env Rscript

# Generate test coverage report
library(covr)

cat("📊 Generating coverage report...\n")

# Generate coverage report
coverage_result <- package_coverage()

# Generate HTML report
report(coverage_result)

cat("✅ Coverage report generated\n") 