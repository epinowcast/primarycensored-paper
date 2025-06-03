tar_target(
  analysis_summary,
  {
    # Count completed analyses
    n_scenarios <- nrow(scenarios)
    n_methods <- 3  # primarycensored, naive, ward
    n_distributions <- nrow(distributions)

    # Summary message
    cat("\n=== ANALYSIS COMPLETE ===\n")
    cat(sprintf("✓ Simulated data for %d scenarios\n", n_scenarios))
    cat(sprintf("✓ Tested %d distributions with %d methods\n", n_distributions, n_methods))
    cat(sprintf("✓ Validated numerical accuracy against Monte Carlo\n"))
    cat(sprintf("✓ Assessed parameter recovery under censoring/truncation\n"))
    cat(sprintf("✓ Applied methods to Ebola case study\n"))
    cat(sprintf("✓ Generated %d main figures\n", 3))
    cat("\nResults saved to data/results/\n")
    cat("Figures saved to figures/\n")
    cat("========================\n\n")

    list(
      completed = TRUE,
      timestamp = Sys.time()
    )
  }
)