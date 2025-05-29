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
          dprimary = dunif,
          shape = 5, scale = 1
        )
      })["elapsed"]
      
      # Numerical (burr)
      time_numerical <- system.time({
        dprimarycensored(
          x = 0:20,
          pdist = function(q, ...) pburr(q, ...),
          pwindow = 1,
          swindow = 1,
          D = Inf,
          dprimary = dunif,
          shape1 = 3, shape2 = 1.5, scale = 4,
          use_numerical = TRUE
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
          shape = 5, scale = 1
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
