tar_target(
  simulated_data,
  {
    # Extract scenario parameters
    params <- scenario_list[[1]]
    
    # Run simulation
    primary_data <- simulate_primary_events(
      n = params$n,
      rate = params$rate,
      seed = params$seed
    )
    
    secondary_data <- simulate_secondary_events(
      primary_data,
      delay_params = list(meanlog = params$meanlog, sdlog = params$sdlog),
      distribution = params$distribution
    )
    
    # Apply censoring
    censored_data <- apply_censoring(
      secondary_data, 
      censoring_interval = params$censoring_interval
    )
    
    # Add scenario ID
    censored_data$scenario_id <- params$scenario_id
    
    censored_data
  },
  pattern = map(scenario_list)
)
