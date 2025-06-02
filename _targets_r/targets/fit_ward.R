tar_target(
  ward_fits,
  {
    # Extract sampled data using shared function
    sampled_data <- extract_sampled_data(monte_carlo_samples, fitting_grid)
    
    # Return empty results if no data
    if (is.null(sampled_data)) {
      return(create_empty_results(fitting_grid, "ward"))
    }
    
    # Start timing after data preparation
    tictoc::tic("fit_ward")
    
    # Extract distribution info and prepare Stan data using shared functions
    dist_info <- extract_distribution_info(sampled_data)
    stan_data <- prepare_stan_data(sampled_data, dist_info$distribution, dist_info$growth_rate, "ward")
    
    # Fit the Ward model using shared Stan settings
    fit <- do.call(compile_stan_models$ward_model$sample, c(
      list(data = stan_data), stan_settings
    ))
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    # Extract posterior estimates using shared function
    extract_posterior_estimates(fit, "ward", fitting_grid, runtime)
  },
  pattern = map(fitting_grid)
)
