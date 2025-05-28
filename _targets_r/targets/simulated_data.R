tar_target(
  simulated_data,
  {
    # Extract scenario parameters
    params <- scenario_list[[1]]
    
    # Placeholder for full simulation following manuscript Methods
    # Real implementation would:
    # 1. Generate primary event times with appropriate growth rate
    # 2. Generate delays from specified distribution
    # 3. Apply interval censoring to both events
    # 4. Apply right truncation based on scenario
    
    message(paste("Simulating data for scenario:", params$scenario_id))
    
    # Simplified simulation
    n_obs <- params$n
    data.frame(
      obs_id = seq_len(n_obs),
      scenario_id = params$scenario_id,
      prim_cens_start = floor(runif(n_obs, 0, 100)),
      prim_cens_end = floor(runif(n_obs, 0, 100)) + params$primary_width,
      sec_cens_start = floor(runif(n_obs, 5, 105)),  
      sec_cens_end = floor(runif(n_obs, 5, 105)) + params$secondary_width,
      true_delay = 5,  # Placeholder - would sample from distribution
      distribution = params$distribution,
      truncation = params$truncation,
      censoring = params$censoring
    )
  },
  pattern = map(scenario_list)
)
