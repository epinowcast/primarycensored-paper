tar_target(
  monte_carlo_pmf,
  {
    tictoc::tic("monte_carlo_pmf")
    
    # Extract empirical PMFs at different sample sizes for this scenario
    result <- purrr::map_dfr(sample_sizes, function(n) {
      if (nrow(simulated_data) >= n) {
        sampled <- simulated_data[1:n, ]
        
        # Create empirical PMF for delays 0:20
        delays <- 0:20
        empirical_pmf <- sapply(delays, function(d) {
          mean(floor(sampled$delay_observed) == d)
        })
        
        data.frame(
          scenario_id = unique(sampled$scenario_id)[1],
          distribution = unique(sampled$distribution)[1],
          truncation = unique(sampled$truncation)[1],
          censoring = unique(sampled$censoring)[1],
          sample_size = n,
          delay = delays,
          probability = empirical_pmf
        )
      } else {
        NULL
      }
    })
    
    runtime <- tictoc::toc(quiet = TRUE)
    result$runtime_seconds <- runtime$toc - runtime$tic
    
    result
  },
  pattern = map(scenarios, simulated_data)
)
