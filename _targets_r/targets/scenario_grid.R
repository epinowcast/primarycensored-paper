tar_target(scenario_grid, {
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
  
  # Subset for test mode if enabled
  if (test_mode) {
    # Take first N scenarios (includes one gamma and one lognormal with different truncations)
    grid <- grid[1:min(test_scenarios, nrow(grid)), ]
    # Ensure we have different distributions
    if (test_scenarios >= 2 && length(unique(grid$distribution)) < 2) {
      # If first two are same distribution, replace second with different one
      different_dist <- setdiff(c("gamma", "lognormal"), grid$distribution[1])[1]
      second_row <- which(grid$distribution == different_dist)[1]
      if (!is.na(second_row)) {
        grid[2, ] <- grid[second_row, ]
      }
    }
  }
  
  grid
})
