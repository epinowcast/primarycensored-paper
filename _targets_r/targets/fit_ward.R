tar_target(
  ward_fits,
  {
    # Use pre-sampled data
    sample_key <- paste(fitting_grid$scenario_id, fitting_grid$sample_size, sep = "_")
    sampled_data <- dplyr::bind_rows(monte_carlo_samples) |>
      dplyr::filter(sample_size_scenario == sample_key)
    
    # Check if we have data
    if (nrow(sampled_data) == 0 || !"delay_observed" %in% names(sampled_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = fitting_grid$sample_size,
        method = "ward",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = NA,
        loglik = NA,
        runtime_seconds = NA
      ))
    }
    
    # Start timing after data preparation
    tictoc::tic("fit_ward")
    
    # Prepare Stan data for Ward model
    distribution <- sampled_data$distribution[1]
    dist_id <- if (distribution == "gamma") 1L else 2L
    
    # Get censoring windows and observation times
    pwindow_widths <- sampled_data$prim_cens_upper - sampled_data$prim_cens_lower
    swindow_widths <- sampled_data$sec_cens_upper - sampled_data$sec_cens_lower
    obs_times <- rep(sampled_data$relative_obs_time[1], nrow(sampled_data))
    
    stan_data <- list(
      N = nrow(sampled_data),
      Y = sampled_data$delay_observed,
      vreal1 = obs_times,           # Observation times
      vreal2 = pwindow_widths,      # Primary window widths
      vreal3 = swindow_widths,      # Secondary window widths
      dist_id = dist_id,
      prior_only = 0
    )
    
    # Configure Stan settings based on test mode
    chains <- if (test_mode) test_chains else 2
    iter_warmup <- if (test_mode) test_iterations else 1000
    iter_sampling <- if (test_mode) test_iterations else 1000
    
    # Fit the Ward model
    fit <- compile_stan_models$ward_model$sample(
      data = stan_data,
      chains = chains,
      parallel_chains = 1,
      iter_warmup = iter_warmup,
      iter_sampling = iter_sampling,
      adapt_delta = 0.95,
      show_messages = FALSE,
      show_exceptions = FALSE,
      refresh = 0
    )
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    # Extract estimates
    param1_draws <- fit$draws("param1")
    param2_draws <- fit$draws("param2")
    param1_est <- mean(posterior::as_draws_matrix(param1_draws))
    param1_se <- sd(posterior::as_draws_matrix(param1_draws))
    param2_est <- mean(posterior::as_draws_matrix(param2_draws))
    param2_se <- sd(posterior::as_draws_matrix(param2_draws))
    
    # Calculate log-likelihood
    log_lik_draws <- fit$draws("log_lik")
    total_log_lik <- sum(apply(posterior::as_draws_matrix(log_lik_draws), 2, mean))
    
    # Check convergence
    max_rhat <- max(fit$summary(c("param1", "param2"))$rhat, na.rm = TRUE)
    
    data.frame(
      scenario_id = fitting_grid$scenario_id,
      sample_size = fitting_grid$sample_size,
      method = "ward",
      param1_est = param1_est,
      param1_se = param1_se,
      param2_est = param2_est,
      param2_se = param2_se,
      convergence = max_rhat,
      loglik = total_log_lik,
      runtime_seconds = runtime$toc - runtime$tic
    )
  },
  pattern = map(fitting_grid)
)
