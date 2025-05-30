tar_target(
  simulated_data,
  {
    tictoc::tic("simulated_data")
    set.seed(scenarios$seed)
    
    # Create distribution arguments for the delay distribution
    n_obs <- scenarios$n
    dist_args <- list(n = n_obs)
    if (!is.na(scenarios$param1)) {
      param_names <- names(formals(get(paste0("r", scenarios$dist_family))))
      dist_args[[param_names[2]]] <- scenarios$param1
      if (!is.na(scenarios$param2)) {
        dist_args[[param_names[3]]] <- scenarios$param2
      }
    }
    
    # Generate delays using rprimarycensored with exponential growth primary distribution
    delays <- rprimarycensored(
      n = n_obs,
      rdist = function(n) do.call(get(paste0("r", scenarios$dist_family)), dist_args),
      rprimary = rexpgrowth,  # Exponential growth distribution for primary events
      rprimary_args = list(r = growth_rate),  # Pass growth rate to rexpgrowth
      pwindow = scenarios$primary_width,
      swindow = scenarios$secondary_width,
      D = scenarios$relative_obs_time
    )
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    # Create censored observations with runtime info
    result <- data.frame(
      obs_id = seq_len(n_obs),
      scenario_id = scenarios$scenario_id,
      delay_observed = delays,
      distribution = scenarios$distribution,
      truncation = scenarios$truncation,
      censoring = scenarios$censoring,
      true_param1 = scenarios$param1,
      true_param2 = scenarios$param2
    )
    
    attr(result, "runtime_seconds") <- runtime$toc - runtime$tic
    result
  },
  pattern = map(scenarios)
)
