#' Extract posterior estimates and diagnostics from Stan fit
#'
#' @param fit Stan fit object from cmdstanr
#' @param method Character string identifying the method (for output)
#' @param fitting_grid Single row from fitting grid
#' @param runtime Runtime object from tictoc
#' @return Data frame with parameter estimates and diagnostics
#' @export
extract_posterior_estimates <- function(fit, method, fitting_grid, runtime) {
  # All models use params vector format: params[1], params[2]
  draws_vars <- c("params[1]", "params[2]")
  
  # Get posterior summaries with all needed quantiles
  param_summary <- posterior::summarise_draws(
    fit$draws(draws_vars),
    ~quantile(.x, probs = c(0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975), na.rm = TRUE),
    mean,
    sd
  )
  
  # Rename variables for consistency
  param_summary$variable <- c("param1", "param2")
  
  params <- setNames(
    split(param_summary, param_summary$variable),
    param_summary$variable
  )

  # Calculate log-likelihood
  log_lik <- fit$draws("log_lik")
  total_log_lik <- sum(apply(posterior::as_draws_matrix(log_lik), 2, mean))

  # Get convergence diagnostics
  diagnostics <- fit$summary(draws_vars)
  divergent_info <- fit$diagnostic_summary()

  data.frame(
    scenario_id = fitting_grid$scenario_id,
    sample_size = fitting_grid$sample_size,
    method = method,
    param1_est = params$param1$mean,
    param1_median = params$param1$`50%`,
    param1_se = params$param1$sd,
    param1_q025 = params$param1$`2.5%`,
    param1_q05 = params$param1$`5%`,
    param1_q25 = params$param1$`25%`,
    param1_q75 = params$param1$`75%`,
    param1_q95 = params$param1$`95%`,
    param1_q975 = params$param1$`97.5%`,
    param2_est = params$param2$mean,
    param2_median = params$param2$`50%`,
    param2_se = params$param2$sd,
    param2_q025 = params$param2$`2.5%`,
    param2_q05 = params$param2$`5%`,
    param2_q25 = params$param2$`25%`,
    param2_q75 = params$param2$`75%`,
    param2_q95 = params$param2$`95%`,
    param2_q975 = params$param2$`97.5%`,
    convergence = max(diagnostics$rhat, na.rm = TRUE),
    ess_bulk_min = min(diagnostics$ess_bulk, na.rm = TRUE),
    ess_tail_min = min(diagnostics$ess_tail, na.rm = TRUE),
    num_divergent = sum(divergent_info$num_divergent %||% 0),
    max_treedepth = sum(divergent_info$num_max_treedepth %||% 0),
    loglik = total_log_lik,
    runtime_seconds = runtime$toc - runtime$tic,
    error_msg = NA_character_
  )
}

#' Create empty results data frame for failed fits
#'
#' @param fitting_grid Single row from fitting grid
#' @param method Character string identifying the method
#' @param error_msg Optional error message
#' @return Data frame with NA values in standard format
#' @export
create_empty_results <- function(fitting_grid, method,
                                 error_msg = NA_character_) {
  data.frame(
    scenario_id = fitting_grid$scenario_id,
    sample_size = fitting_grid$sample_size,
    method = method,
    param1_est = NA_real_,
    param1_median = NA_real_,
    param1_se = NA_real_,
    param1_q025 = NA_real_,
    param1_q05 = NA_real_,
    param1_q25 = NA_real_,
    param1_q75 = NA_real_,
    param1_q95 = NA_real_,
    param1_q975 = NA_real_,
    param2_est = NA_real_,
    param2_median = NA_real_,
    param2_se = NA_real_,
    param2_q025 = NA_real_,
    param2_q05 = NA_real_,
    param2_q25 = NA_real_,
    param2_q75 = NA_real_,
    param2_q95 = NA_real_,
    param2_q975 = NA_real_,
    convergence = NA_real_,
    ess_bulk_min = NA_real_,
    ess_tail_min = NA_real_,
    num_divergent = NA_integer_,
    max_treedepth = NA_integer_,
    loglik = NA_real_,
    runtime_seconds = NA_real_,
    error_msg = error_msg
  )
}

#' Extract distribution and growth rate from fitting grid
#'
#' @param fitting_grid Single row from fitting grid with distribution and
#'   growth_rate columns
#' @return List with distribution and growth_rate
#' @export
extract_distribution_info <- function(fitting_grid) {
  list(
    distribution = fitting_grid$distribution[1],
    growth_rate = fitting_grid$growth_rate[1]
  )
}

#' Get starting values for distribution fitting
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @param data Optional data to compute method-of-moments starting values
#' @return List of starting parameter values
#' @export
get_start_values <- function(distribution, data = NULL) {
  if (distribution == "gamma") {
    if (!is.null(data) && length(data) > 1) {
      # Use method of moments for better starting values
      raw_mean <- mean(data, na.rm = TRUE)
      raw_var <- var(data, na.rm = TRUE)
      if (raw_var > 0 && raw_mean > 0) {
        mom_shape <- raw_mean^2 / raw_var
        mom_scale <- raw_var / raw_mean
        # Ensure reasonable bounds
        mom_shape <- pmax(0.1, pmin(mom_shape, 10))
        mom_scale <- pmax(0.1, pmin(mom_scale, 10))
        return(list(shape = mom_shape, scale = mom_scale))
      }
    }
    # Fallback to default values
    list(shape = 1.5, scale = 2)
  } else if (distribution == "lognormal") {
    if (!is.null(data) && length(data) > 1) {
      # Use method of moments for lognormal
      data_pos <- data[data > 0]
      if (length(data_pos) > 1) {
        log_data <- log(data_pos)
        mom_meanlog <- mean(log_data, na.rm = TRUE)
        mom_sdlog <- sd(log_data, na.rm = TRUE)
        # Ensure reasonable bounds
        mom_meanlog <- pmax(-5, pmin(mom_meanlog, 5))
        mom_sdlog <- pmax(0.1, pmin(mom_sdlog, 3))
        return(list(meanlog = mom_meanlog, sdlog = mom_sdlog))
      }
    }
    # Fallback to default values
    list(meanlog = 1.5, sdlog = 0.5)
  } else {
    stop("Unknown distribution: ", distribution)
  }
}

#' Get parameter names for distribution
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return Character vector of parameter names
#' @export
get_param_names <- function(distribution) {
  if (distribution == "gamma") {
    c("shape", "scale")
  } else if (distribution == "lognormal") {
    c("meanlog", "sdlog")
  } else {
    stop("Unknown distribution: ", distribution)
  }
}

#' Map distribution names to R distribution function names
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return Character string of R distribution name
#' @export
get_r_distribution_name <- function(distribution) {
  if (distribution == "gamma") {
    "gamma"
  } else if (distribution == "lognormal") {
    "lnorm"
  } else {
    stop("Unknown distribution: ", distribution)
  }
}


#' Get shared prior settings for delay distribution parameters
#'
#' Returns the prior bounds and hyperparameters used across all methods
#' to ensure fair comparison. These match the primarycensored defaults.
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return List with bounds_priors containing param_bounds and priors
#' @export
get_shared_prior_settings <- function(distribution) {
  if (distribution == "gamma") {
    list(
      param_bounds = list(lower = c(0.001, 0.001), upper = c(50, 50)),
      priors = list(location = c(2, 2), scale = c(2, 2))
    )
  } else if (distribution == "lognormal") {
    list(
      param_bounds = list(lower = c(-10, 0.001), upper = c(10, 10)),
      priors = list(location = c(1, 0.5), scale = c(1, 0.5))
    )
  } else {
    stop("Unknown distribution: ", distribution)
  }
}

#' Get shared primary distribution prior settings
#'
#' Returns the primary distribution prior bounds and hyperparameters used
#' across all methods to ensure fair comparison. These match the
#' primarycensored defaults.
#'
#' @param growth_rate Numeric growth rate value
#' @return List with primary_param_bounds and primary_priors
#' @export
get_shared_primary_priors <- function(growth_rate) {
  if (growth_rate == 0) {
    list(
      primary_param_bounds = list(lower = numeric(0), upper = numeric(0)),
      primary_priors = list(location = numeric(0), scale = numeric(0))
    )
  } else {
    list(
      primary_param_bounds = list(lower = c(-10), upper = c(10)),
      primary_priors = list(location = c(growth_rate), scale = c(0.05))
    )
  }
}

#' Prepare shared data and configuration for primarycensored-framework models
#'
#' Prepares delay data and configuration settings used by both primarycensored
#' and naive models to ensure consistency.
#'
#' @param sampled_data Data frame with delay observations and censoring windows
#' @param fitting_grid Single row from fitting grid with truncation info
#' @param dist_info List with distribution and growth_rate from
#'   extract_distribution_info()
#' @return List containing delay_data and config
#' @export
prepare_shared_model_inputs <- function(sampled_data, fitting_grid, dist_info) {
  # Get truncation limit from the data - this should always be present
  if ("relative_obs_time" %in% names(sampled_data) && !all(is.na(sampled_data$relative_obs_time))) {
    relative_obs_time <- sampled_data$relative_obs_time
  } else {
    stop("relative_obs_time column is missing from sampled_data.")
  }
  

  if (any(sampled_data$sec_cens_upper > relative_obs_time)) {
    stop("Data inconsistency: some delay_upper values are not strictly less than relative_obs_time. This suggests an issue with the data generation.")
  }
  
  # Prepare delay data for primarycensored framework - aggregate to unique combinations
  # for better performance following vignette approach
  delay_data_raw <- data.frame(
    delay = as.numeric(sampled_data$delay_observed),
    delay_upper = as.numeric(sampled_data$sec_cens_upper),
    pwindow = sampled_data$prim_cens_upper - sampled_data$prim_cens_lower,
    relative_obs_time = relative_obs_time,
    row.names = NULL
  )
  
  # Aggregate to unique combinations and count occurrences (like vignette)
  # This provides significant speed improvements for Stan
  delay_data <- delay_data_raw |>
    dplyr::summarise(
      n = dplyr::n(),
      .by = c(delay, delay_upper, pwindow, relative_obs_time)
    )

  # Configuration based on distribution and growth rate using proper pcd_stan_dist_id calls
  config <- list(
    # Use proper delay distribution IDs
    dist_id = primarycensored::pcd_stan_dist_id(dist_info$distribution, "delay"),
    # Use proper primary distribution IDs
    primary_id = if (dist_info$growth_rate == 0) {
      primarycensored::pcd_stan_dist_id("uniform", "primary")
    } else {
      primarycensored::pcd_stan_dist_id("expgrowth", "primary")
    }
  )

  list(
    delay_data = delay_data,
    config = config
  )
}

#' Prepare Ward-specific Stan data from shared model inputs
#'
#' Takes the output from prepare_shared_model_inputs and adds Ward-specific
#' data requirements (censoring windows and observation times).
#'
#' @param sampled_data Data frame with delay observations and censoring windows
#' @param shared_inputs Output from prepare_shared_model_inputs
#' @param bounds_priors Output from get_shared_prior_settings
#' @return List of Stan data for Ward model
#' @export
prepare_ward_stan_data <- function(sampled_data, shared_inputs, bounds_priors) {
  config <- shared_inputs$config

  # Ward method needs individual observations, not aggregated data
  # So we use the original sampled_data directly
  delays <- as.numeric(sampled_data$delay_observed)
  pwindow_widths <- sampled_data$prim_cens_upper - sampled_data$prim_cens_lower
  swindow_widths <- sampled_data$sec_cens_upper - sampled_data$sec_cens_lower
  
  # Get observation times from sampled_data (should be consistent)
  if ("relative_obs_time" %in% names(sampled_data) && !all(is.na(sampled_data$relative_obs_time))) {
    obs_times <- sampled_data$relative_obs_time
  } else {
    stop("relative_obs_time column is missing from sampled_data.")
  }

  # Replace infinite values with large finite number for Stan
  obs_times[is.infinite(obs_times)] <- 1e6

  list(
    N = nrow(sampled_data),
    Y = delays,
    obs_times = obs_times,
    pwindow_widths = pwindow_widths,
    swindow_widths = swindow_widths,
    dist_id = config$dist_id,
    primary_id = config$primary_id,
    prior_only = 0,
    # Add shared bounds and priors
    n_params = 2L,
    n_primary_params = if (config$primary_id == 1) 0L else 1L, # 0 for uniform, 1 for exponential
    param_lower_bounds = bounds_priors$param_bounds$lower,
    param_upper_bounds = bounds_priors$param_bounds$upper,
    prior_location = bounds_priors$priors$location,
    prior_scale = bounds_priors$priors$scale
  )
}
