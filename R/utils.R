#' Save a plot to the figures directory
#'
#' @param plot The plot object to save
#' @param filename The filename (without path)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution in dots per inch
#' @export
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  ggplot2::ggsave(
    filename = here::here("figures", filename),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
}

#' Save data to the results directory
#'
#' @param data The data object to save
#' @param filename The filename (without path)
#' @export
save_data <- function(data, filename) {
  write.csv(
    data,
    file = here::here("data/results", filename),
    row.names = FALSE
  )
}




#' Extract posterior estimates and diagnostics from Stan fit
#'
#' @param fit Stan fit object from cmdstanr
#' @param method Character string identifying the method (for output)
#' @param fitting_grid Single row from fitting grid
#' @param runtime Runtime object from tictoc
#' @return Data frame with parameter estimates and diagnostics
#' @export
extract_posterior_estimates <- function(fit, method, fitting_grid, runtime) {
  # Get posterior summaries using summarise_draws
  param_summary <- posterior::summarise_draws(
    fit$draws(c("param1", "param2"))
  )
  params <- setNames(
    split(param_summary, param_summary$variable),
    param_summary$variable
  )

  # Calculate log-likelihood
  log_lik <- fit$draws("log_lik")
  total_log_lik <- sum(apply(posterior::as_draws_matrix(log_lik), 2, mean))

  # Get convergence diagnostics
  diagnostics <- fit$summary(c("param1", "param2"))
  divergent_info <- fit$diagnostic_summary()

  data.frame(
    scenario_id = fitting_grid$scenario_id,
    sample_size = fitting_grid$sample_size,
    method = method,
    param1_est = params$param1$mean,
    param1_se = params$param1$sd,
    param1_q025 = params$param1$q5,
    param1_q975 = params$param1$q95,
    param2_est = params$param2$mean,
    param2_se = params$param2$sd,
    param2_q025 = params$param2$q5,
    param2_q975 = params$param2$q95,
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
    param1_se = NA_real_,
    param1_q025 = NA_real_,
    param1_q975 = NA_real_,
    param2_est = NA_real_,
    param2_se = NA_real_,
    param2_q025 = NA_real_,
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

#' Get distribution ID for Stan models
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return Integer distribution ID for Stan (1=lognormal, 2=gamma,
#'   matches primarycensored)
#' @export
get_distribution_id <- function(distribution) {
  if (distribution == "gamma") 2L else 1L
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

#' Get relative observation time from truncation scenario
#'
#' @param truncation Character string: truncation scenario name
#' @return Numeric value for relative observation time
#' @export
get_relative_obs_time <- function(truncation) {
  truncation_map <- c(
    "none" = Inf,
    "moderate" = 10,
    "severe" = 5
  )
  truncation_map[truncation]
}

#' Get starting values for distribution fitting
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return List of starting parameter values
#' @export
get_start_values <- function(distribution) {
  if (distribution == "gamma") {
    list(shape = 2, scale = 2)
  } else if (distribution == "lognormal") {
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

#' Prepare Stan data list for naive and Ward models
#'
#' @param sampled_data Data frame with delay observations
#' @param distribution Character string: "gamma" or "lognormal"
#' @param growth_rate Numeric growth rate value
#' @param model_type Character: "naive" or "ward"
#' @param truncation Character: truncation scenario for Ward model
#' @return List of Stan data
#' @export
prepare_stan_data <- function(sampled_data, distribution, growth_rate,
                              model_type = "naive", truncation = NULL) {
  dist_id <- get_distribution_id(distribution)

  if (model_type == "naive") {
    list(
      N = nrow(sampled_data),
      delay_observed = sampled_data$delay_observed,
      dist_id = dist_id
    )
  } else if (model_type == "ward") {
    # Get censoring windows and observation times
    pwindow_widths <- sampled_data$prim_cens_upper -
      sampled_data$prim_cens_lower
    swindow_widths <- sampled_data$sec_cens_upper - sampled_data$sec_cens_lower
    obs_times <- rep(get_relative_obs_time(truncation), nrow(sampled_data))

    # Replace infinite values with large finite number for Stan
    obs_times[is.infinite(obs_times)] <- 1e6

    list(
      N = nrow(sampled_data),
      Y = sampled_data$delay_observed,
      obs_times = obs_times, # Stan arrays are just vectors in R
      pwindow_widths = pwindow_widths, # Stan arrays are just vectors in R
      swindow_widths = swindow_widths, # Stan arrays are just vectors in R
      dist_id = dist_id,
      prior_only = 0
    )
  } else {
    stop("Unknown model_type: ", model_type)
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
      param_bounds = list(lower = c(0.01, 0.01), upper = c(50, 50)),
      priors = list(location = c(2, 2), scale = c(1, 1))
    )
  } else if (distribution == "lognormal") {
    list(
      param_bounds = list(lower = c(-10, 0.01), upper = c(10, 10)),
      priors = list(location = c(1.5, 2), scale = c(1, 1))
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
      primary_param_bounds = list(lower = c(0.01), upper = c(10)),
      primary_priors = list(location = c(0.2), scale = c(1))
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
  # Prepare delay data for primarycensored framework
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

  list(
    delay_data = delay_data,
    config = config
  )
}
