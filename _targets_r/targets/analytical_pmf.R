tar_target(
  analytical_pmf,
  {
    tictoc::tic("analytical_pmf")
    
    # Get distribution info with parameter names
    dist_info <- distributions[distributions$dist_name == scenarios$distribution, ]
    
    # Define delay values to evaluate (ensure x + swindow <= D)
    max_delay <- if(is.finite(scenarios$relative_obs_time)) {
      pmin(20, scenarios$relative_obs_time - scenarios$secondary_width)
    } else {
      20
    }
    
    # Skip scenarios where truncation is smaller than censoring window
    if(max_delay < 0) {
      result <- data.frame(
        scenario_id = scenarios$scenario_id,
        distribution = scenarios$distribution,
        truncation = scenarios$truncation,
        censoring = scenarios$censoring,
        method = "analytical",
        delay = 0,
        probability = NA,
        runtime_seconds = 0
      )
      return(result)
    }
    
    delays <- 0:max_delay
    
    # Calculate analytical PMF using dprimarycensored
    args <- list(
      x = delays,
      pdist = get(paste0("p", dist_info$dist_family)),
      pwindow = scenarios$primary_width,
      swindow = scenarios$secondary_width,
      D = scenarios$relative_obs_time,
      dprimary = dexpgrowth,
      dprimary_args = list(r = growth_rate)
    )
    # Add distribution parameters using named arguments
    args[[dist_info$param1_name]] <- dist_info$param1
    args[[dist_info$param2_name]] <- dist_info$param2
    
    analytical_pmf <- do.call(dprimarycensored, args)
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    result <- data.frame(
      scenario_id = scenarios$scenario_id,
      distribution = scenarios$distribution,
      truncation = scenarios$truncation,
      censoring = scenarios$censoring,
      method = "analytical",
      delay = delays,
      probability = analytical_pmf,
      runtime_seconds = runtime$toc - runtime$tic
    )
    
    result
  },
  pattern = map(scenarios)
)
