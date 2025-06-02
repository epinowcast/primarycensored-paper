tar_target(sample_size_grid, {
  # Determine which sample sizes to use
  sizes_to_use <- if (test_mode) c(test_samples) else sample_sizes
  
  expand.grid(
    scenario_id = scenarios$scenario_id,
    sample_size = sizes_to_use,
    stringsAsFactors = FALSE
  )
})
