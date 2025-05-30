tar_target(
  analytical_pmf,
  {
    tictoc::tic("analytical_pmf")
    
    result <- purrr::map_dfr(seq_len(nrow(scenario_list)), function(i) {
      scenario <- scenario_list[i, ]
      
      # Get distribution info with parameter names
      dist_info <- distributions[distributions$dist_name == scenario$distribution, ]
      
      # Define delay values to evaluate (ensure x + swindow <= D)
      max_delay <- if(is.finite(scenario$relative_obs_time)) {
        pmin(20, scenario$relative_obs_time - scenario$secondary_width)
      } else {
        20
      }
      
      # Skip scenarios where truncation is smaller than censoring window
      if(max_delay < 0) {
        return(data.frame(
          scenario_id = scenario$scenario_id,
          distribution = scenario$distribution,
          truncation = scenario$truncation,
          censoring = scenario$censoring,
          method = "analytical",
          delay = 0,
          probability = NA
        ))
      }
      
      delays <- 0:max_delay
      
      # Calculate analytical PMF using dprimarycensored
      args <- list(
        x = delays,
        pdist = get(paste0("p", dist_info$dist_family)),
        pwindow = scenario$primary_width,
        swindow = scenario$secondary_width,
        D = scenario$relative_obs_time,
        dprimary = dexpgrowth,
        dprimary_args = list(r = growth_rate)
      )
      # Add distribution parameters using named arguments
      args[[dist_info$param1_name]] <- dist_info$param1
      args[[dist_info$param2_name]] <- dist_info$param2
      
      analytical_pmf <- do.call(dprimarycensored, args)
      
      data.frame(
        scenario_id = scenario$scenario_id,
        distribution = scenario$distribution,
        truncation = scenario$truncation,
        censoring = scenario$censoring,
        method = "analytical",
        delay = delays,
        probability = analytical_pmf
      )
    })
    
    runtime <- tictoc::toc(quiet = TRUE)
    attr(result, "runtime_seconds") <- runtime$toc - runtime$tic
    
    result
  }
)
