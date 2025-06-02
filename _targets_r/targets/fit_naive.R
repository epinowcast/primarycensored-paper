tar_target(
  naive_fits,
  {
    library(dplyr)
    
    # Use pre-sampled data
    sample_key <- paste(fitting_grid$scenario_id, fitting_grid$sample_size, sep = "_")
    sampled_data <- dplyr::bind_rows(monte_carlo_samples) |>
      dplyr::filter(sample_size_scenario == sample_key)
    
    # Check if we have data
    if (nrow(sampled_data) == 0 || !"delay_observed" %in% names(sampled_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = fitting_grid$sample_size,
        method = "naive",
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
    tictoc::tic("fit_naive")
    
    # Prepare Stan data
    distribution <- sampled_data$distribution[1]
    dist_id <- if (distribution == "gamma") 1L else 2L
    
    stan_data <- list(
      N = nrow(sampled_data),
      delay_observed = sampled_data$delay_observed,
      dist_id = dist_id
    )
    
    # Configure Stan settings based on test mode
    chains <- if (test_mode) test_chains else 2
    iter_warmup <- if (test_mode) test_iterations else 1000
    iter_sampling <- if (test_mode) test_iterations else 1000
    
    # Fit the model
    fit <- compile_stan_models$naive_model$sample(
      data = stan_data,
      chains = chains,
      parallel_chains = 1,  # Run sequentially to avoid resource contention
      iter_warmup = iter_warmup,
      iter_sampling = iter_sampling,
      adapt_delta = 0.95,
      show_messages = FALSE,
      show_exceptions = FALSE,
      refresh = 0
    )
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    # Extract estimates
    draws <- fit$draws(c("param1", "param2"))
    param1_est <- mean(posterior::as_draws_matrix(draws[,,1]))
    param1_se <- sd(posterior::as_draws_matrix(draws[,,1]))
    param2_est <- mean(posterior::as_draws_matrix(draws[,,2]))
    param2_se <- sd(posterior::as_draws_matrix(draws[,,2]))
    
    # Calculate log-likelihood
    log_lik_draws <- fit$draws("log_lik")
    total_log_lik <- sum(apply(posterior::as_draws_matrix(log_lik_draws), 2, mean))
    
    # Check convergence
    diagnostics <- fit$diagnostic_summary()
    max_rhat <- max(fit$summary("param1", "param2")$rhat, na.rm = TRUE)
    
    data.frame(
      scenario_id = fitting_grid$scenario_id,
      sample_size = fitting_grid$sample_size,
      method = "naive",
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
