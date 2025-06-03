tar_target(
  primarycensored_fitdistrplus_fits,
  {
    # Extract data directly from fitting_grid
    sampled_data <- fitting_grid$data[[1]]
    if (is.null(sampled_data) || nrow(sampled_data) == 0) {
      return(create_empty_results(fitting_grid, "primarycensored_mle"))
    }

    tictoc::tic("fit_primarycensored_mle")
    dist_info <- extract_distribution_info(fitting_grid)

    # Prepare data in correct format for fitdistdoublecens
    delay_data <- data.frame(
      left = sampled_data$delay_observed,
      right = sampled_data$delay_observed + (sampled_data$sec_cens_upper[1] - sampled_data$sec_cens_lower[1])
    )

    pwindow <- sampled_data$prim_cens_upper[1] - sampled_data$prim_cens_lower[1]
    obs_time <- get_relative_obs_time(fitting_grid$truncation[1])

    # Fit using appropriate distribution
    fit_result <- primarycensored::fitdistdoublecens(
      censdata = delay_data,
      distr = dist_info$distribution,
      pwindow = pwindow,
      D = if (is.finite(obs_time)) obs_time else Inf,
      dprimary = get_dprimary(dist_info$growth_rate),
      dprimary_args = get_dprimary_args(dist_info$growth_rate),
      start = get_start_values(dist_info$distribution)
    )

    # Extract parameters based on distribution
    param_names <- get_param_names(dist_info$distribution)

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
