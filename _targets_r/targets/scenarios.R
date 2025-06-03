tar_target(scenarios, {
  # Create all combinations
  grid <- expand.grid(
    distribution = distributions$dist_name[distributions$dist_name != "burr"],  # Exclude burr distribution
    truncation = truncation_scenarios$trunc_name,
    censoring = censoring_scenarios$cens_name,
    growth_rate = growth_rates,
    stringsAsFactors = FALSE
  )

  # Add scenario metadata
  grid$scenario_id <- paste(grid$distribution, grid$truncation, grid$censoring,
                           paste0("r", grid$growth_rate), sep = "_")
  grid$n <- simulation_n
  grid$seed <- seq_len(nrow(grid)) + base_seed

  grid |>
    dplyr::left_join(distributions, by = c("distribution" = "dist_name")) |>
    dplyr::left_join(truncation_scenarios, by = c("truncation" = "trunc_name")) |>
    dplyr::left_join(censoring_scenarios, by = c("censoring" = "cens_name"))
})