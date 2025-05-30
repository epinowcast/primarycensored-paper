tar_target(
  analytical_pmf,
  {
    tictoc::tic("analytical_pmf")
    
    # Get distribution info with parameter names
    dist_info <- distributions[distributions$dist_name == scenarios$distribution, ]
    
    # Always evaluate delays 0:20 for consistency
    delays <- 0:20
    
    # Define which delays are valid (ensure x + swindow <= D)
    if(is.finite(scenarios$relative_obs_time)) {
      # For finite truncation, only evaluate delays where delay + swindow <= D
      valid_delays <- delays[delays + scenarios$secondary_width <= scenarios$relative_obs_time]
    } else {
      # For infinite truncation, all delays are valid
      valid_delays <- delays
    }
    
    # Initialize probability vector with NAs
    analytical_pmf <- rep(NA_real_, length(delays))
    
    # Calculate PMF only for valid delays
    if (length(valid_delays) > 0) {
      args <- list(
        x = valid_delays,
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
      
      pmf_values <- do.call(dprimarycensored, args)
      # Fill in the valid delays with calculated values
      analytical_pmf[delays %in% valid_delays] <- pmf_values
    }
    
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
