# Create a list for dynamic branching over all scenario combinations
tar_target(
  scenario_list,
  {
    # Join all scenario details
    scenarios <- scenario_grid |>
      dplyr::left_join(distributions, by = c("distribution" = "dist_name")) |>
      dplyr::left_join(truncation_scenarios, by = c("truncation" = "trunc_name")) |>
      dplyr::left_join(censoring_scenarios, by = c("censoring" = "cens_name"))
    
    # Split for branching
    split(scenarios, scenarios$scenario_id)
  }
)
