#' Fit primarycensored Bayesian model
#'
#' Fits delay distribution parameters using the primarycensored package's
#' Bayesian implementation. This method properly accounts for primary event
#' censoring, secondary censoring, and truncation in epidemiological delay data.
#' Uses shared priors for fair comparison with other methods.
#'
#' @param fitting_grid Single row from fitting grid containing scenario
#'   parameters and data
#' @param stan_settings List of Stan sampling settings (chains, iter, etc.)
#' @param model Optional pre-compiled Stan model (will compile if NULL)
#' @return Data frame with parameter estimates, credible intervals, and
#'   convergence diagnostics
#' @export
#'
#' @seealso [primarycensored::pcd_cmdstan_model()], [fit_naive()], [fit_ward()]
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
      # Prepare Stan data using vignette approach with proper IDs and aggregated data
      stan_data <- primarycensored::pcd_as_stan_data(
        delay_data,
        delay = "delay",
        delay_upper = "delay_upper",
        n = "n", # Specify count column for aggregated data
        pwindow = "pwindow",
        relative_obs_time = "relative_obs_time",
        dist_id = config$dist_id,
        primary_id = config$primary_id,
        param_bounds = bounds_priors$param_bounds,
        primary_param_bounds = primary_bounds_priors$primary_param_bounds,
        priors = bounds_priors$priors,
        primary_priors = primary_bounds_priors$primary_priors,
        compute_log_lik = TRUE
      )
      
      # Prepare Stan settings
      stan_settings <- c(
        stan_settings,
        list(
          data = stan_data
        )
      )
      
      fit <- do.call(model$sample, stan_settings)

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
      
      # Prepare full Stan settings with initialization
      stan_settings <- c(
        stan_settings,
        list(
          data = naive_stan_data
        )
      )
      
      # Fit the model using shared Stan settings
      fit <- do.call(model$sample, stan_settings)

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
      
      # Prepare full Stan settings with initialization
      stan_settings <- c(
        stan_settings,
        list(
          data = stan_data
        )
      )
      
      # Fit the Ward model using shared Stan settings
      fit <- do.call(model$sample, stan_settings)

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
#' Fits delay distribution parameters using the primarycensored package's MLE
#' implementation via fitdistrplus. This method properly accounts for primary event
#' censoring, secondary censoring, and truncation. The observation time (D parameter)
#' is extracted from the relative_obs_time column in the sampled data rather than
#' being hardcoded, ensuring consistency with other methods.
#'
#' @param fitting_grid Single row from fitting grid containing scenario parameters
#'   and data. The data must include a relative_obs_time column specifying the
#'   observation time limit for truncation.
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
          (sampled_data$sec_cens_upper - sampled_data$sec_cens_lower)
      )

      pwindow <- sampled_data$prim_cens_upper[1] -
        sampled_data$prim_cens_lower[1]
      
      # Extract relative observation time from data
      if ("relative_obs_time" %in% names(sampled_data) && !all(is.na(sampled_data$relative_obs_time))) {
        obs_time <- sampled_data$relative_obs_time[1]
      } else {
        stop("relative_obs_time column is missing from sampled_data.")
      }

      # Check that all relative observation times are the same
      # Development version of primarycensored supports varying observation times
      unique_obs_times <- unique(sampled_data$relative_obs_time)
      if (length(unique_obs_times) > 1) {
        stop("All relative_obs_time values must be the same. ",
             "Development version supports varying observation times.")
      }

      # Check that all primary censoring windows are the same
      unique_pwindows <- unique(sampled_data$prim_cens_upper - sampled_data$prim_cens_lower)
      if (length(unique_pwindows) > 1) {
        stop("All primary censoring windows must be the same. ",
             "Development version supports varying primary censoring windows.")
      }

      # Fit using appropriate distribution with proper primary distribution
      # functions
      fit_result <- primarycensored::fitdistdoublecens(
        censdata = delay_data,
        distr = get_r_distribution_name(dist_info$distribution),
        pwindow = pwindow,
        D = if (is.finite(obs_time)) obs_time else Inf,
        dprimary = get_dprimary(dist_info$growth_rate),
        dprimary_args = get_dprimary_args(dist_info$growth_rate),
        start = get_start_values(
          dist_info$distribution, sampled_data$delay_observed
        )
      )

      # Extract parameters based on distribution
      param_names <- get_param_names(dist_info$distribution)

      runtime <- tictoc::toc(quiet = TRUE)

      data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = fitting_grid$sample_size,
        method = "primarycensored_mle",
        param1_est = fit_result$estimate[param_names[1]],
        param1_median = fit_result$estimate[param_names[1]],  # MLE point estimate
        param1_se = fit_result$sd[param_names[1]] %||% NA_real_,
        param1_q025 = NA_real_,
        param1_q05 = NA_real_,
        param1_q25 = NA_real_,
        param1_q75 = NA_real_,
        param1_q95 = NA_real_,
        param1_q975 = NA_real_,
        param2_est = fit_result$estimate[param_names[2]],
        param2_median = fit_result$estimate[param_names[2]],  # MLE point estimate
        param2_se = fit_result$sd[param_names[2]] %||% NA_real_,
        param2_q025 = NA_real_,
        param2_q05 = NA_real_,
        param2_q25 = NA_real_,
        param2_q75 = NA_real_,
        param2_q95 = NA_real_,
        param2_q975 = NA_real_,
        convergence = fit_result$convergence %||% 0,
        ess_bulk_min = NA_real_,
        ess_tail_min = NA_real_,
        num_divergent = NA_integer_,
        max_treedepth = NA_integer_,
        loglik = fit_result$loglik %||% NA_real_,
        runtime_seconds = runtime$toc - runtime$tic,
        error_msg = NA_character_
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
