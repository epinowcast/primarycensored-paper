#' Fit primarycensored Bayesian model
#'
#' @param fitting_grid Single row from fitting grid
#' @param stan_settings List of Stan sampling settings
#' @param model Optional pre-compiled Stan model (will compile if NULL)
#' @return Data frame with parameter estimates and diagnostics
#' @export
fit_primarycensored <- function(fitting_grid, stan_settings, model = NULL) {
  # Suppress object_usage_linter warnings for utils.R functions
  create_empty_results <- create_empty_results
  extract_distribution_info <- extract_distribution_info
  get_relative_obs_time <- get_relative_obs_time
  extract_posterior_estimates <- extract_posterior_estimates
  prepare_shared_model_inputs <- prepare_shared_model_inputs
  get_shared_prior_settings <- get_shared_prior_settings
  get_shared_primary_priors <- get_shared_primary_priors

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
  # Suppress object_usage_linter warnings for utils.R functions
  create_empty_results <- create_empty_results
  extract_distribution_info <- extract_distribution_info
  get_relative_obs_time <- get_relative_obs_time
  extract_posterior_estimates <- extract_posterior_estimates
  prepare_shared_model_inputs <- prepare_shared_model_inputs
  get_shared_prior_settings <- get_shared_prior_settings
  get_shared_primary_priors <- get_shared_primary_priors

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

      # Primary distribution parameters using shared settings
      primary_bounds_priors <- get_shared_primary_priors(dist_info$growth_rate)

      # Prepare Stan data using primarycensored framework
      stan_data <- do.call(primarycensored::pcd_as_stan_data, c(
        list(delay_data, compute_log_lik = TRUE),
        config, bounds_priors, primary_bounds_priors
      ))

      # Prepare naive Stan data with prior parameters
      naive_stan_data <- list(
        N = stan_data$N,
        delay_observed = delay_data$delay,
        dist_id = stan_data$dist_id,
        n_params = 2,
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
  # Suppress object_usage_linter warnings for utils.R functions
  create_empty_results <- create_empty_results
  extract_distribution_info <- extract_distribution_info
  prepare_stan_data <- prepare_stan_data
  extract_posterior_estimates <- extract_posterior_estimates

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
      # Extract distribution info and prepare Stan data using shared functions
      dist_info <- extract_distribution_info(fitting_grid)
      stan_data <- prepare_stan_data(
        sampled_data, dist_info$distribution,
        dist_info$growth_rate, "ward",
        fitting_grid$truncation[1]
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
  # Suppress object_usage_linter warnings for utils.R functions
  create_empty_results <- create_empty_results
  extract_distribution_info <- extract_distribution_info
  get_relative_obs_time <- get_relative_obs_time
  get_start_values <- get_start_values
  get_param_names <- get_param_names

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

      # Simple primary distribution functions for MLE fitting
      get_dprimary_simple <- function(growth_rate) {
        if (growth_rate == 0) {
          stats::dunif
        } else {
          # Simple exponential growth approximation
          function(x, min = 0, max = 1, r = growth_rate) {
            if (r == 0) {
              return(stats::dunif(x, min, max))
            }
            # Exponential growth density (simplified)
            exp_weights <- exp(r * x)
            exp_weights / sum(exp_weights)
          }
        }
      }

      get_dprimary_args_simple <- function(growth_rate) {
        if (growth_rate == 0) {
          list() # Default uniform
        } else {
          list(min = 0, max = pwindow, r = growth_rate)
        }
      }

      # Fit using appropriate distribution
      fit_result <- primarycensored::fitdistdoublecens(
        censdata = delay_data,
        distr = dist_info$distribution,
        pwindow = pwindow,
        D = if (is.finite(obs_time)) obs_time else Inf,
        dprimary = get_dprimary_simple(dist_info$growth_rate),
        dprimary_args = get_dprimary_args_simple(dist_info$growth_rate),
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
