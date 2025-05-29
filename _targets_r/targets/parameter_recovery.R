tar_target(
  parameter_recovery,
  {
    # Get true parameter values from scenario_grid
    true_params <- scenario_grid |>
      dplyr::left_join(distributions, by = c("distribution" = "dist_name")) |>
      dplyr::select(scenario_id, true_param1 = param1, true_param2 = param2)
    
    # Calculate bias and coverage for each method and scenario
    all_model_fits |>
      dplyr::left_join(true_params, by = "scenario_id") |>
      dplyr::filter(!is.na(param1_est)) |>  # Remove failed fits
      dplyr::group_by(method, scenario_id) |>
      dplyr::summarise(
        bias_param1 = param1_est - true_param1,
        bias_param2 = param2_est - true_param2,
        # Simple coverage calculation assuming normal approximation
        coverage_param1 = ifelse(
          !is.na(param1_se),
          abs(param1_est - true_param1) < 1.96 * param1_se,
          NA
        ),
        coverage_param2 = ifelse(
          !is.na(param2_se),
          abs(param2_est - true_param2) < 1.96 * param2_se,
          NA
        ),
        .groups = "drop"
      ) |>
      dplyr::group_by(method) |>
      dplyr::summarise(
        mean_bias_param1 = mean(bias_param1, na.rm = TRUE),
        mean_bias_param2 = mean(bias_param2, na.rm = TRUE),
        coverage_param1 = mean(coverage_param1, na.rm = TRUE),
        coverage_param2 = mean(coverage_param2, na.rm = TRUE),
        n_successful = n(),
        .groups = "drop"
      )
  }
)
