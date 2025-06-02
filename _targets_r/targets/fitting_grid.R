tar_target(fitting_grid, {
  expand.grid(
    scenario_id = scenarios$scenario_id,
    sample_size = sample_sizes,
    stringsAsFactors = FALSE
  )
})
