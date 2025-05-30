tar_target(
  numerical_pmf,
  {
    tictoc::tic("numerical_pmf")
    
    # Get distribution info with parameter names
    dist_info <- distributions[distributions$dist_name == scenarios$distribution, ]
    
    # Define delay values to evaluate (ensure x + swindow <= D)
    delay_upper_bound <- if(is.finite(scenarios$relative_obs_time)) {
      pmax(0, scenarios$relative_obs_time - scenarios$secondary_width)
    } else {
      20
    }
    
    # Use minimum of 20 and the truncation-adjusted bound
    max_delay_to_evaluate <- min(20, delay_upper_bound)
    
    # For scenarios with severe constraints, still evaluate at least delay 0
    delays <- 0:max(0, max_delay_to_evaluate)
    
    # Set a dummy attribute to the distribution function to trigger numerical integration
    pdistnumerical <- add_name_attribute(get(paste0("p", dist_info$dist_family)), "pdistnumerical")

    # Calculate numerical PMF using dprimarycensored with use_numerical = TRUE
    args <- list(
      x = delays,
      pdist = pdistnumerical,
      pwindow = scenarios$primary_width,
      swindow = scenarios$secondary_width,
      D = scenarios$relative_obs_time,
      dprimary = dexpgrowth,
      dprimary_args = list(r = growth_rate)
    )
    # Add distribution parameters using named arguments
    args[[dist_info$param1_name]] <- dist_info$param1
    args[[dist_info$param2_name]] <- dist_info$param2
    
    numerical_pmf <- do.call(dprimarycensored, args)
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    result <- data.frame(
      scenario_id = scenarios$scenario_id,
      distribution = scenarios$distribution,
      truncation = scenarios$truncation,
      censoring = scenarios$censoring,
      method = "numerical",
      delay = delays,
      probability = numerical_pmf,
      runtime_seconds = runtime$toc - runtime$tic
    )
    
    result
  },
  pattern = map(scenarios)
)
