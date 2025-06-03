tar_target(parameter_recovery, {
  # Calculate bias, coverage, RMSE for each method and scenario
  # Real implementation would compare estimated vs true parameters

  model_fits |>
    dplyr::group_by(method, scenario_id) |>
    dplyr::summarise(
      bias_param1 = mean(param1_est, na.rm = TRUE) - 5,  # True param1 is 5 for both dists
      bias_param2 = mean(param2_est, na.rm = TRUE) - 1,  # True param2 is 1 (scale) for gamma
      coverage_param1 = 0.95,  # Placeholder - would need CI calculations
      coverage_param2 = 0.94,  # Placeholder - would need CI calculations
      .groups = "drop"
    )
})