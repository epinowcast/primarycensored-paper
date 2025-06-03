tar_target(
  monte_carlo_samples,
  {
    # Get all simulated data and filter to the specific scenario
    all_sim_data <- dplyr::bind_rows(simulated_data)
    scenario_data <- all_sim_data |>
      dplyr::filter(scenario_id == sample_size_grid$scenario_id)
    n <- sample_size_grid$sample_size

    # Sample the requested number of observations
    if (nrow(scenario_data) >= n) {
      sampled <- scenario_data[1:n, ]
      data.frame(
        sample_size_scenario = paste(sample_size_grid$scenario_id, n, sep = "_"),
        scenario_id = sample_size_grid$scenario_id,
        sample_size = n,
        sampled
      )
    } else {
      # Return empty data frame if not enough data
      data.frame(
        sample_size_scenario = paste(sample_size_grid$scenario_id, n, sep = "_"),
        scenario_id = sample_size_grid$scenario_id,
        sample_size = n
      )
    }
  },
  pattern = map(sample_size_grid)
)