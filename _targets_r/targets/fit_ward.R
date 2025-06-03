tar_target(
  ward_fits,
  {
    # Extract data directly from fitting_grid
    sampled_data <- fitting_grid$data[[1]]
    if (is.null(sampled_data) || nrow(sampled_data) == 0) {
      return(create_empty_results(fitting_grid, "ward"))
    }

    if (nrow(sampled_data) > 1000) {
      return(create_empty_results(fitting_grid, "ward"))
    }

    # Start timing after data preparation
    tictoc::tic("fit_ward")

    # Extract distribution info and prepare Stan data using shared functions
    dist_info <- extract_distribution_info(fitting_grid)
    stan_data <- prepare_stan_data(sampled_data, dist_info$distribution, dist_info$growth_rate, "ward", fitting_grid$truncation[1])

    # Fit the Ward model using shared Stan settings
    fit <- do.call(compile_ward_model$sample, c(
      list(data = stan_data), stan_settings
    ))

    runtime <- tictoc::toc(quiet = TRUE)

    # Extract posterior estimates using shared function
    extract_posterior_estimates(fit, "ward", fitting_grid, runtime)
  },
  pattern = map(fitting_grid)
)
