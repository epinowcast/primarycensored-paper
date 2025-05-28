tar_target(
  parameter_recovery,
  {
    # Calculate bias, coverage, RMSE for each method and scenario
    # Real implementation would compare estimated vs true parameters
    
    all_model_fits |>
      dplyr::group_by(method, scenario_id) |>
      dplyr::summarise(
        bias_param1 = mean(estimate[parameter == "param1"] - 5),
        bias_param2 = mean(estimate[parameter == "param2"] - 1),
        coverage_param1 = 0.95,  # Placeholder
        coverage_param2 = 0.94,  # Placeholder
        .groups = "drop"
      )
  }
)
