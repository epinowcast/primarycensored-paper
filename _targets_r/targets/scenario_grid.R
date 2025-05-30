tar_target(
  scenario_grid,
  {
    # Create all combinations
    grid <- expand.grid(
      distribution = distributions$dist_name,
      truncation = truncation_scenarios$trunc_name,
      censoring = censoring_scenarios$cens_name,
      stringsAsFactors = FALSE
    )
    
    # Add scenario metadata
    grid$scenario_id <- paste(grid$distribution, grid$truncation, grid$censoring, sep = "_")
    grid$n <- simulation_n
    grid$seed <- seq_len(nrow(grid)) + base_seed
    
    grid
  }
)
