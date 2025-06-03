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
    # primarycensored: lnorm=1, gamma=2
    dist_id = if (dist_info$distribution == "gamma") 2L else 1L,
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
      result$runtime_seconds <- runtime$toc - runtime$tic
      result
    }
  )
}

#' Fit naive Bayesian model
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

  # Compile model if not provided
  if (is.null(model)) {
    model <- cmdstanr::cmdstan_model(
      here::here("stan", "naive_delay_model.stan")
    )
  }

  tryCatch(
    {
      # Extract distribution info and prepare Stan data using shared functions
      dist_info <- extract_distribution_info(fitting_grid)
      stan_data <- prepare_stan_data(
        sampled_data, dist_info$distribution,
        dist_info$growth_rate, "naive"
      )

      # Fit the model using shared Stan settings
      fit <- do.call(model$sample, c(
        list(data = stan_data), stan_settings
      ))

      runtime <- tictoc::toc(quiet = TRUE)
      extract_posterior_estimates(fit, "naive", fitting_grid, runtime)
    },
    error = function(e) {
      runtime <- tictoc::toc(quiet = TRUE)
      result <- create_empty_results(fitting_grid, "naive")
      result$error_msg <- as.character(e)
      result$runtime_seconds <- runtime$toc - runtime$tic
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
      result$runtime_seconds <- runtime$toc - runtime$tic
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

      pwindow <- sampled_data$prim_cens_upper[1] - sampled_data$prim_cens_lower[1]
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
      result$runtime_seconds <- runtime$toc - runtime$tic
      result
    }
  )
}

