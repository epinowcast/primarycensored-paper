tar_target(
  runtime_comparison,
  {
    # library(primarycensored) # Removed - should be in globals
    sample_sizes <- c(10, 100, 1000, 10000)
    
    # Use gamma distribution parameters from distributions data frame
    gamma_dist <- distributions[distributions$dist_name == "gamma", ]
    gamma_params <- list()
    gamma_params[[gamma_dist$param1_name]] <- gamma_dist$param1
    gamma_params[[gamma_dist$param2_name]] <- gamma_dist$param2
    
    # Measure runtime for different methods
    purrr::map_dfr(sample_sizes, function(n) {
      # Analytical (gamma)
      time_analytical <- system.time({
        do.call(dprimarycensored, c(
          list(x = 0:20, pdist = pgamma, pwindow = 1, swindow = 1, D = Inf, dprimary = dunif),
          gamma_params
        ))
      })["elapsed"]
      
      # Numerical (using different gamma parameters for comparison)
      numerical_params <- list(shape = 3, scale = 1.5)
      time_numerical <- system.time({
        do.call(dprimarycensored, c(
          list(x = 0:20, pdist = pgamma, pwindow = 1, swindow = 1, D = Inf, dprimary = dunif),
          numerical_params
        ))
      })["elapsed"]
      
      # Monte Carlo baseline
      time_mc <- system.time({
        rprimarycensored(
          n = n,
          rdist = function(n) do.call(rgamma, c(list(n = n), gamma_params)),
          rprimary = runif,
          pwindow = 1,
          swindow = 1,
          D = Inf
        )
      })["elapsed"]
      
      data.frame(
        method = c("analytical", "numerical", "monte_carlo"),
        sample_size = n,
        runtime_seconds = c(time_analytical, time_numerical, time_mc)
      )
    })
  }
)
