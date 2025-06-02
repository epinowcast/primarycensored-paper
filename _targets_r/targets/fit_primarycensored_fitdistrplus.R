tar_target(
  primarycensored_fitdistrplus_fits,
  {
    sampled_data <- extract_sampled_data(monte_carlo_samples, fitting_grid)
    if (is.null(sampled_data)) return(create_empty_results(fitting_grid, "primarycensored_mle"))
    
    tictoc::tic("fit_primarycensored_mle")
    dist_info <- extract_distribution_info(sampled_data)
    
    # Prepare data and primary distribution
    delays_data <- data.frame(
      delay_lwr = sampled_data$sec_cens_lower,
      delay_upr = sampled_data$sec_cens_upper,
      ptime_lwr = sampled_data$prim_cens_lower,
      ptime_upr = sampled_data$prim_cens_upper
    )
    
    obs_time <- sampled_data$relative_obs_time[1]
    if (is.finite(obs_time)) delays_data$obs_time <- obs_time
    
    primary_dist <- if (dist_info$growth_rate == 0) {
      function(x) dunif(x, min = 0, max = sampled_data$prim_cens_upper[1])
    } else {
      primarycensored::dexpgrowth
    }
    
    # Fit using appropriate distribution
    fit_args <- list(
      delays_data, pdist = primary_dist,
      start = if (dist_info$distribution == "gamma") {
        list(shape = 2, scale = 2)
      } else {
        list(meanlog = 1.5, sdlog = 0.5)
      },
      distr = if (dist_info$distribution == "gamma") "gamma" else "lnorm"
    )
    
    fit_result <- do.call(primarycensored::fitdistdoublecens, fit_args)
    
    # Extract parameters based on distribution
    param_names <- if (dist_info$distribution == "gamma") {
      c("shape", "scale")
    } else {
      c("meanlog", "sdlog")
    }
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    data.frame(
      scenario_id = fitting_grid$scenario_id,
      sample_size = fitting_grid$sample_size,
      method = "primarycensored_mle",
      param1_est = fit_result$estimate[param_names[1]],
      param1_se = fit_result$sd[param_names[1]] %||% NA_real_,
      param1_q025 = NA_real_,
      param1_q975 = NA_real_,
      param2_est = fit_result$estimate[param_names[2]],
      param2_se = fit_result$sd[param_names[2]] %||% NA_real_,
      param2_q025 = NA_real_,
      param2_q975 = NA_real_,
      convergence = fit_result$convergence %||% 0,
      ess_bulk_min = NA_real_,
      ess_tail_min = NA_real_,
      num_divergent = NA_integer_,
      max_treedepth = NA_integer_,
      loglik = fit_result$loglik %||% NA_real_,
      runtime_seconds = runtime$toc - runtime$tic
    )
  },
  pattern = map(fitting_grid)
)
