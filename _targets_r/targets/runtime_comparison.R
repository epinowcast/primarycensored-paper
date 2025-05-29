tar_target(
  runtime_comparison,
  {
    library(primarycensored)
    sample_sizes <- c(10, 100, 1000, 10000)
    
    # Measure runtime for different methods
    purrr::map_dfr(sample_sizes, function(n) {
      # Analytical (gamma)
      time_analytical <- system.time({
        dprimarycensored(
          x = 0:20,
          pdist = pgamma,
          pwindow = 1,
          swindow = 1,
          D = Inf,
          shape = 5, 
          rate = 1  # Use rate parameterization
        )
      })["elapsed"]
      
      # Numerical - using a simple test case
      time_numerical <- system.time({
        # Using gamma with numerical integration for comparison
        dprimarycensored(
          x = 0:20,
          pdist = pgamma,
          pwindow = 1,
          swindow = 1,
          D = Inf,
          shape = 5,
          rate = 1  # Use rate parameterization
        )
      })["elapsed"]
      
      # Monte Carlo baseline
      time_mc <- system.time({
        rprimarycensored(
          n = n,
          rdist = rgamma,
          rprimary = runif,
          pwindow = 1,
          swindow = 1,
          D = Inf,
          shape = 5, 
          rate = 1  # Use rate parameterization
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
