tar_target(
  primarycensored_fits,
  {  
    # Extract data directly from fitting_grid
    sampled_data <- fitting_grid$data[[1]]
    if (is.null(sampled_data) || nrow(sampled_data) == 0) {
      return(create_empty_results(fitting_grid, "primarycensored"))
    }
    
    tictoc::tic("fit_primarycensored")
    dist_info <- extract_distribution_info(fitting_grid)
    
    # Prepare delay data for primarycensored
    delay_data <- data.frame(
      delay = sampled_data$delay_observed,
      delay_upper = sampled_data$sec_cens_upper, 
      n = 1,
      pwindow = sampled_data$prim_cens_upper[1] - sampled_data$prim_cens_lower[1],
      relative_obs_time = get_relative_obs_time(fitting_grid$truncation[1])
    )
    
    # Configuration based on distribution and growth rate
    config <- list(
      dist_id = if (dist_info$distribution == "gamma") 2L else 1L,  # primarycensored: lnorm=1, gamma=2
      primary_id = if (dist_info$growth_rate == 0) 1L else 2L
    )
    
    # Set bounds and priors
    if (dist_info$distribution == "gamma") {
      bounds_priors <- list(
        param_bounds = list(lower = c(0.01, 0.01), upper = c(50, 50)),
        priors = list(location = c(2, 2), scale = c(1, 1))
      )
    } else {
      bounds_priors <- list(
        param_bounds = list(lower = c(-10, 0.01), upper = c(10, 10)),
        priors = list(location = c(1.5, 2), scale = c(1, 1))
      )
    }
    
    # Primary distribution parameters
    if (dist_info$growth_rate == 0) {
      primary_bounds_priors <- list(
        primary_param_bounds = list(lower = numeric(0), upper = numeric(0)),
        primary_priors = list(location = numeric(0), scale = numeric(0))
      )
    } else {
      primary_bounds_priors <- list(
        primary_param_bounds = list(lower = c(0.01), upper = c(10)),
        primary_priors = list(location = c(0.2), scale = c(1))
      )
    }
    
    # Prepare Stan data and fit
    stan_data <- do.call(primarycensored::pcd_as_stan_data, c(
      list(delay_data, compute_log_lik = TRUE),
      config, bounds_priors, primary_bounds_priors
    ))
    
    fit <- do.call(compile_primarycensored_model$sample, c(
      list(data = stan_data), stan_settings
    ))
    
    runtime <- tictoc::toc(quiet = TRUE)
    extract_posterior_estimates(fit, "primarycensored", fitting_grid, runtime)
  },
  pattern = map(fitting_grid)
)
