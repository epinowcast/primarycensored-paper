tar_target(sample_size_grid, {
  # Create grid of scenarios and sample sizes for monte carlo PMF
  expand.grid(
    scenario_id = scenarios$scenario_id,
    sample_size = sample_sizes,
    stringsAsFactors = FALSE
  )
})
