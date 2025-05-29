tar_target(
  simulated_data,
  {
    library(primarycensored)
    params <- scenario_list[[1]]
    set.seed(params$seed)
    
    # Generate primary event times with exponential growth
    n_obs <- params$n
    growth_rate <- 0.2  # As per manuscript
    prim_times <- cumsum(rexp(n_obs, rate = growth_rate))
    
    # Generate delays using rprimarycensored with correct parameterization
    if (params$distribution == "gamma") {
      delays <- rprimarycensored(
        n = n_obs,
        rdist = rgamma,
        rprimary = runif,  # Uniform primary distribution
        pwindow = params$primary_width,
        swindow = params$secondary_width,
        D = params$max_delay,
        shape = params$param1,
        rate = 1/params$param2  # Convert scale to rate
      )
    } else if (params$distribution == "lognormal") {
      delays <- rprimarycensored(
        n = n_obs,
        rdist = rlnorm,
        rprimary = runif,  # Uniform primary distribution
        pwindow = params$primary_width,
        swindow = params$secondary_width,
        D = params$max_delay,
        meanlog = params$param1,
        sdlog = params$param2
      )
    } else if (params$distribution == "burr") {
      # Skip Burr for now - return placeholder data
      delays <- rep(5, n_obs)  # Placeholder
    } else {
      stop("Unknown distribution: ", params$distribution)
    }
    
    # Create data structure for primarycensored fitting
    data.frame(
      obs_id = seq_len(n_obs),
      scenario_id = params$scenario_id,
      # Primary event censoring intervals
      prim_cens_lower = floor(prim_times),
      prim_cens_upper = floor(prim_times) + params$primary_width,
      # Observed censored delays (key for fitting)
      delay_observed = delays,
      # Secondary event censoring intervals  
      sec_cens_lower = floor(prim_times + delays),
      sec_cens_upper = floor(prim_times + delays) + params$secondary_width,
      # Scenario metadata
      distribution = params$distribution,
      truncation = params$truncation,
      censoring = params$censoring,
      # Parameters needed for primarycensored fitting
      pwindow = params$primary_width,
      swindow = params$secondary_width,
      max_delay = ifelse(is.infinite(params$max_delay), 20, params$max_delay),
      # True parameters for validation
      true_param1 = params$param1,
      true_param2 = params$param2,
      true_param3 = ifelse(is.na(params$param3), NA, params$param3)
    )
  },
  pattern = map(scenario_list)
)
