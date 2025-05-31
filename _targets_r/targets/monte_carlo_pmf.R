tar_target(
  monte_carlo_pmf,
  {
    tictoc::tic("monte_carlo_pmf")

    # Use the pre-sampled data
    sampled <- monte_carlo_samples

    # Create base data frame structure
    delays <- 0:20

    # Calculate empirical PMF if we have data
    if (nrow(sampled) > 0 && "delay_observed" %in% names(sampled)) {
      empirical_pmf <- sapply(delays, function(d) {
        mean(floor(sampled$delay_observed) == d)
      })
      distribution <- unique(sampled$distribution)[1]
      truncation <- unique(sampled$truncation)[1]
      censoring <- unique(sampled$censoring)[1]
      growth_rate <- unique(sampled$growth_rate)[1]
      scenario_id <- unique(sampled$scenario_id)[1]
      sample_size <- unique(sampled$sample_size)[1]
    } else {
      empirical_pmf <- NA_real_
      distribution <- NA_character_
      truncation <- NA_character_
      censoring <- NA_character_
      growth_rate <- NA_real_
      scenario_id <- unique(sampled$scenario_id)[1]
      sample_size <- unique(sampled$sample_size)[1]
    }

    # Create result data frame with consistent structure
    result <- data.frame(
      scenario_id = scenario_id,
      distribution = distribution,
      truncation = truncation,
      censoring = censoring,
      growth_rate = growth_rate,
      sample_size = sample_size,
      delay = delays,
      probability = empirical_pmf
    )

    runtime <- tictoc::toc(quiet = TRUE)
    result$runtime_seconds <- runtime$toc - runtime$tic

    result
  },
  pattern = map(monte_carlo_samples)
)
