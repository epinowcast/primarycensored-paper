tar_target(
  results_summary,
  {
    # Compile all results into summary tables
    list(
      scenarios = scenarios,
      metrics = performance_metrics,
      diagnostics = model_diagnostics
    )
  }
)
