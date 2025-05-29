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
    
    # Generate delays using rprimarycensored
    if (params$distribution == "gamma") {
      delays <- rprimarycensored(
        n = n_obs,
        rdist = rgamma,
        rprimary = runif,  # Uniform primary distribution
        pwindow = params$primary_width,
        swindow = params$secondary_width,
        D = params$max_delay,
        shape = params$param1,
        scale = params$param2
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
    } else {
      # For Burr, use a simple approximation for now
      delays <- rgamma(n_obs, shape = 2, scale = 2.5)  # Approximate mean of 5
      delays <- pmin(delays, params$max_delay)
    }
    
    # Create censored observations
    data.frame(
      obs_id = seq_len(n_obs),
      scenario_id = params$scenario_id,
      prim_cens_lower = floor(prim_times),
      prim_cens_upper = floor(prim_times) + params$primary_width,
      delay_observed = delays,
      sec_cens_lower = floor(prim_times + delays),
      sec_cens_upper = floor(prim_times + delays) + params$secondary_width,
      distribution = params$distribution,
      truncation = params$truncation,
      censoring = params$censoring,
      true_params = list(param1 = params$param1, param2 = params$param2)
    )
  },
  pattern = map(scenario_list)
)
