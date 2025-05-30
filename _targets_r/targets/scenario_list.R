tar_target(scenario_list, {
  # Join all scenario details
  scenario_grid |>
    dplyr::left_join(distributions, by = c("distribution" = "dist_name")) |>
    dplyr::left_join(truncation_scenarios, by = c("truncation" = "trunc_name")) |>
    dplyr::left_join(censoring_scenarios, by = c("censoring" = "cens_name"))
})
