#' Fit primarycensored Bayesian model
#'
#' @param fitting_grid Single row from fitting grid
#' @param stan_settings List of Stan sampling settings
#' @param model Optional pre-compiled Stan model (will compile if NULL)
#' @return Data frame with parameter estimates and diagnostics
#' @export
fit_primarycensored <- function(fitting_grid, stan_settings, model = NULL) {
  # Extract data directly from fitting_grid
  sampled_data <- fitting_grid$data[[1]]
  if (is.null(sampled_data) || nrow(sampled_data) == 0) {
    return(create_empty_results(fitting_grid, "primarycensored"))
  }

  tictoc::tic("fit_primarycensored")
  dist_info <- extract_distribution_info(fitting_grid)

  # Compile model if not provided
  if (is.null(model)) {
    model <- primarycensored::pcd_cmdstan_model()
  }

  # Prepare shared data and configuration
  shared_inputs <- prepare_shared_model_inputs(
    sampled_data, fitting_grid, dist_info
  )
  delay_data <- shared_inputs$delay_data
  config <- shared_inputs$config

  # Set bounds and priors using shared settings
  bounds_priors <- get_shared_prior_settings(dist_info$distribution)

  # Primary distribution parameters using shared settings
  primary_bounds_priors <- get_shared_primary_priors(dist_info$growth_rate)

  tryCatch(
    {
      # Prepare Stan data and fit
      stan_data <- do.call(primarycensored::pcd_as_stan_data, c(
        list(delay_data, compute_log_lik = TRUE),
        config, bounds_priors, primary_bounds_priors
      ))

      fit <- do.call(model$sample, c(
        list(data = stan_data), stan_settings
      ))

      runtime <- tictoc::toc(quiet = TRUE)
      extract_posterior_estimates(fit, "primarycensored", fitting_grid, runtime)
    },
    error = function(e) {
      runtime <- tictoc::toc(quiet = TRUE)
      result <- create_empty_results(fitting_grid, "primarycensored")
      result$error_msg <- as.character(e)
      result$runtime_seconds <- if (!is.null(runtime)) {
        runtime$toc - runtime$tic
      } else {
        NA_real_
      }
      result
    }
  )
}

#' Fit naive Bayesian model
#'
#' Baseline comparison method that ignores primary event censoring and
#' truncation.
#' Uses the same priors as primarycensored for fair comparison - only the
#' likelihood differs (treats censored delays as true delays).
#'
#' @param fitting_grid Single row from fitting grid
#' @param stan_settings List of Stan sampling settings
#' @param model Optional pre-compiled Stan model (will compile if NULL)
#' @return Data frame with parameter estimates and diagnostics
#' @export
fit_naive <- function(fitting_grid, stan_settings, model = NULL) {
  # Extract data directly from fitting_grid
  sampled_data <- fitting_grid$data[[1]]
  if (is.null(sampled_data) || nrow(sampled_data) == 0) {
    return(create_empty_results(fitting_grid, "naive"))
  }

  tictoc::tic("fit_naive")
  dist_info <- extract_distribution_info(fitting_grid)

  # Compile model if not provided
  if (is.null(model)) {
    model <- cmdstanr::cmdstan_model(
      here::here("stan", "naive_delay_model.stan")
    )
  }

  tryCatch(
    {
      # Use shared data preparation for consistency
      shared_inputs <- prepare_shared_model_inputs(
        sampled_data, fitting_grid, dist_info
      )
      delay_data <- shared_inputs$delay_data
      config <- shared_inputs$config

      # Use shared prior settings
      bounds_priors <- get_shared_prior_settings(dist_info$distribution)

      # Apply small padding to zero delays for naive model
      padded_delays <- delay_data$delay
      zero_mask <- padded_delays == 0
      if (any(zero_mask)) {
        padded_delays[zero_mask] <- 1e-6  # Small padding for zero delays
      }

      # Use primarycensored-style bounds and priors system
      naive_stan_data <- list(
        N = nrow(delay_data),
        delay_observed = padded_delays,
        dist_id = config$dist_id,
        n_params = 2,
        param_lower_bounds = bounds_priors$param_bounds$lower,
        param_upper_bounds = bounds_priors$param_bounds$upper,
        prior_location = bounds_priors$priors$location,
        prior_scale = bounds_priors$priors$scale
      )

      # Fit the model using shared Stan settings
      fit <- do.call(model$sample, c(
        list(data = naive_stan_data), stan_settings
      ))

      runtime <- tictoc::toc(quiet = TRUE)
      extract_posterior_estimates(fit, "naive", fitting_grid, runtime)
    },
    error = function(e) {
      runtime <- tictoc::toc(quiet = TRUE)
      result <- create_empty_results(fitting_grid, "naive")
      result$error_msg <- as.character(e)
      result$runtime_seconds <- if (!is.null(runtime)) {
        runtime$toc - runtime$tic
      } else {
        NA_real_
      }
      result
    }
  )
}

#' Fit Ward et al. latent variable model
#'
#' @param fitting_grid Single row from fitting grid
#' @param stan_settings List of Stan sampling settings
#' @param model Optional pre-compiled Stan model (will compile if NULL)
#' @return Data frame with parameter estimates and diagnostics
#' @export
fit_ward <- function(fitting_grid, stan_settings, model = NULL) {
  # Extract data directly from fitting_grid
  sampled_data <- fitting_grid$data[[1]]
  if (is.null(sampled_data) || nrow(sampled_data) == 0) {
    return(create_empty_results(fitting_grid, "ward"))
  }

  # Ward method cannot handle large sample sizes
  if (nrow(sampled_data) > 1000) {
    return(create_empty_results(fitting_grid, "ward"))
  }


  tictoc::tic("fit_ward")

  # Compile model if not provided
  if (is.null(model)) {
    model <- cmdstanr::cmdstan_model(
      here::here("stan", "ward_latent_model.stan")
    )
  }

  tryCatch(
    {
      # Extract distribution info and get shared prior settings
      dist_info <- extract_distribution_info(fitting_grid)
      bounds_priors <- get_shared_prior_settings(dist_info$distribution)

      # Use shared data preparation for consistency
      shared_inputs <- prepare_shared_model_inputs(
        sampled_data, fitting_grid, dist_info
      )

      # Prepare Ward-specific Stan data using shared inputs
      stan_data <- prepare_ward_stan_data(
        sampled_data, shared_inputs, bounds_priors
      )

      # Fit the Ward model using shared Stan settings
      fit <- do.call(model$sample, c(
        list(data = stan_data), stan_settings
      ))

      runtime <- tictoc::toc(quiet = TRUE)
      extract_posterior_estimates(fit, "ward", fitting_grid, runtime)
    },
    error = function(e) {
      runtime <- tictoc::toc(quiet = TRUE)
      result <- create_empty_results(fitting_grid, "ward")
      result$error_msg <- as.character(e)
      result$runtime_seconds <- if (!is.null(runtime)) {
        runtime$toc - runtime$tic
      } else {
        NA_real_
      }
      result
    }
  )
}

#' Fit primarycensored MLE model using fitdistrplus
#'
#' @param fitting_grid Single row from fitting grid
#' @return Data frame with parameter estimates and diagnostics
#' @export
fit_primarycensored_mle <- function(fitting_grid) {
  # Extract data directly from fitting_grid
  sampled_data <- fitting_grid$data[[1]]
  if (is.null(sampled_data) || nrow(sampled_data) == 0) {
    return(create_empty_results(fitting_grid, "primarycensored_mle"))
  }

  tictoc::tic("fit_primarycensored_mle")
  dist_info <- extract_distribution_info(fitting_grid)

  tryCatch(
    {
      # Prepare data in correct format for fitdistdoublecens
      delay_data <- data.frame(
        left = sampled_data$delay_observed,
        right = sampled_data$delay_observed +
          (sampled_data$sec_cens_upper[1] - sampled_data$sec_cens_lower[1])
      )

      pwindow <- sampled_data$prim_cens_upper[1] -
        sampled_data$prim_cens_lower[1]
      obs_time <- get_relative_obs_time(fitting_grid$truncation[1])

      # Fit using appropriate distribution with proper primary distribution functions
      fit_result <- primarycensored::fitdistdoublecens(
        censdata = delay_data,
        distr = get_r_distribution_name(dist_info$distribution),
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
    error = function(e) {
      runtime <- tictoc::toc(quiet = TRUE)
      result <- create_empty_results(fitting_grid, "primarycensored_mle")
      result$error_msg <- as.character(e)
      result$runtime_seconds <- if (!is.null(runtime)) {
        runtime$toc - runtime$tic
      } else {
        NA_real_
      }
      result
    }
  )
}
