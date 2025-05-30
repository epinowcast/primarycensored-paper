tar_target(sample_size_grid, {
  expand.grid(
    scenario_id = scenarios$scenario_id,
    sample_size = sample_sizes,
    stringsAsFactors = FALSE
  )
})
