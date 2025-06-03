#!/usr/bin/env Rscript

# Profile the targets pipeline to identify performance bottlenecks
# This script runs the pipeline with profiling enabled

message("🔍 Profiling targets pipeline...")

if (!requireNamespace("profvis", quietly = TRUE)) {
  stop("The profvis package is required. Run: task install")
}

message("Running pipeline with profiling enabled...")
message("This may take longer than normal execution.")

# Run profiling
results <- profvis::profvis(
  targets::tar_make(
    callr_function = NULL,  # Run in current session
    use_crew = FALSE,       # Disable parallel for accurate profiling
    as_job = FALSE          # Run in foreground
  )
)

# Save results
saveRDS(results, "profile_results.rds")

# Save HTML report
htmlwidgets::saveWidget(results, "profile_report.html", selfcontained = TRUE)

message("\n✅ Profiling complete!")
message("   - Interactive viewer opened in browser")
message("   - Results saved to: profile_results.rds")
message("   - HTML report saved to: profile_report.html")
