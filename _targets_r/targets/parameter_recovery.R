tar_target(
  parameter_recovery,
  {
    # Calculate bias, coverage, RMSE for each method and scenario
    # Get true parameter values from scenario information
    
    all_model_fits |>
      dplyr::left_join(
        scenario_list |> 
          dplyr::bind_rows() |> 
          dplyr::select(scenario_id, distribution, param1, param2),
        by = "scenario_id"
      ) |>
      dplyr::group_by(method, scenario_id) |>
      dplyr::summarise(
        bias_param1 = mean(param1_est - param1, na.rm = TRUE),
        bias_param2 = mean(param2_est - param2, na.rm = TRUE),
        rmse_param1 = sqrt(mean((param1_est - param1)^2, na.rm = TRUE)),
        rmse_param2 = sqrt(mean((param2_est - param2)^2, na.rm = TRUE)),
        # Simple coverage check (would need confidence intervals for proper coverage)
        coverage_param1 = mean(abs(param1_est - param1) < 2 * param1_se, na.rm = TRUE),
        coverage_param2 = mean(abs(param2_est - param2) < 2 * param2_se, na.rm = TRUE),
        .groups = "drop"
      )
  }
)
