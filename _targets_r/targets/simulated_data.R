tar_target(
  simulated_data,
  {
    set.seed(scenario_list$seed)
    
    # Create distribution arguments for the delay distribution
    n_obs <- scenario_list$n
    dist_args <- list(n = n_obs)
    if (!is.na(scenario_list$param1)) {
      param_names <- names(formals(get(paste0("r", scenario_list$dist_family))))
      dist_args[[param_names[2]]] <- scenario_list$param1
      if (!is.na(scenario_list$param2)) {
        dist_args[[param_names[3]]] <- scenario_list$param2
      }
    }
    
    # Generate delays using rprimarycensored with exponential growth primary distribution
    delays <- rprimarycensored(
      n = n_obs,
      rdist = function(n) do.call(get(paste0("r", scenario_list$dist_family)), dist_args),
      rprimary = rexpgrowth,  # Exponential growth distribution for primary events
      rprimary_args = list(r = growth_rate),  # Pass growth rate to rexpgrowth
      pwindow = scenario_list$primary_width,
      swindow = scenario_list$secondary_width,
      D = scenario_list$relative_obs_time
    )
    
    # Create censored observations
    data.frame(
      obs_id = seq_len(n_obs),
      scenario_id = scenario_list$scenario_id,
      delay_observed = delays,
      distribution = scenario_list$distribution,
      truncation = scenario_list$truncation,
      censoring = scenario_list$censoring,
      true_param1 = scenario_list$param1,
      true_param2 = scenario_list$param2
    )
  },
  pattern = map(scenario_list)
)
