tar_target(fitting_grid, {
  # Determine which sample sizes to use for fitting (same as monte carlo)
  sizes_to_use <- if (test_mode) c(test_samples) else sample_sizes
  
  expand.grid(
    scenario_id = scenarios$scenario_id,
    sample_size = sizes_to_use,
    stringsAsFactors = FALSE
  )
})
