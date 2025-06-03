#!/usr/bin/env Rscript

# Show test coverage in console
library(covr)

cat("📊 Checking test coverage...\n")

# Generate and display coverage
coverage_result <- package_coverage()
print(coverage_result)

# Show percentage
percent_coverage <- percent_coverage(coverage_result)
cat("Overall coverage:", round(percent_coverage, 2), "%\n")

if (percent_coverage < 80) {
  cat("⚠️ Coverage below 80%\n")
} else {
  cat("✅ Good coverage level\n")
}
