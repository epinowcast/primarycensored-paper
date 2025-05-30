tar_target(
  naive_fits,
  {
    # Get the full dataset for this scenario
    scenario_idx <- which(scenarios$scenario_id == fitting_grid$scenario_id)
    full_data <- simulated_data[[scenario_idx]]
    
    # Sample the requested number of observations
    n <- fitting_grid$sample_size
    if (n > nrow(full_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = n,
        method = "naive",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = NA,
        loglik = NA,
        runtime_seconds = NA
      ))
    }
    
    sampled_data <- full_data[1:n, ]
    
    # Use the new function for cleaner code
    .estimate_naive_delay_model(
      data = sampled_data,
      distribution = sampled_data$distribution[1],
      scenario_id = fitting_grid$scenario_id,
      sample_size = n
    )
  },
  pattern = map(fitting_grid)
)
