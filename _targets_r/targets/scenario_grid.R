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
    
    # Add details from component data frames
    grid$scenario_id <- paste(grid$distribution, grid$truncation, grid$censoring, sep = "_")
    grid$n <- 10000  # 10,000 observations per scenario
    grid$seed <- seq_len(nrow(grid)) + 100  # Unique seed per scenario
    
    grid
  }
)
