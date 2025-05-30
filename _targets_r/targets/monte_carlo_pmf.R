tar_target(
  monte_carlo_pmf,
  {
    tictoc::tic("monte_carlo_pmf")
    
    # Get scenario data for this scenario_id
    scenario_idx <- which(scenarios$scenario_id == sample_size_grid$scenario_id)
    scenario_data <- simulated_data[[scenario_idx]]
    n <- sample_size_grid$sample_size
    
    # Create base data frame structure
    delays <- 0:20
    
    # Calculate empirical PMF if we have enough data
    if (nrow(scenario_data) >= n) {
      sampled <- scenario_data[1:n, ]
      empirical_pmf <- sapply(delays, function(d) {
        mean(floor(sampled$delay_observed) == d)
      })
      distribution <- unique(sampled$distribution)[1]
      truncation <- unique(sampled$truncation)[1]
      censoring <- unique(sampled$censoring)[1]
    } else {
      empirical_pmf <- NA_real_
      distribution <- NA_character_
      truncation <- NA_character_
      censoring <- NA_character_
    }
    
    # Create result data frame with consistent structure
    result <- data.frame(
      scenario_id = sample_size_grid$scenario_id,
      distribution = distribution,
      truncation = truncation,
      censoring = censoring,
      sample_size = n,
      delay = delays,
      probability = empirical_pmf
    )
    
    runtime <- tictoc::toc(quiet = TRUE)
    result$runtime_seconds <- runtime$toc - runtime$tic
    
    result
  },
  pattern = map(sample_size_grid)
)
