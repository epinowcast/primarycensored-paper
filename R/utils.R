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

#' Estimate delay distribution using naive model
#'
#' @param data Data frame with delay observations
#' @param distribution Character string naming the distribution ("gamma" or
#' "lognormal")
#' @param scenario_id Scenario identifier
#' @param sample_size Sample size
#' @param seed Random seed for Stan
#' @param chains Number of chains
#' @param iter_warmup Number of warmup iterations
#' @param iter_sampling Number of sampling iterations
#' @return Data frame with estimates
#' @export
estimate_naive_delay_model <- function(data, distribution, scenario_id,
                                       sample_size, seed = 123, chains = 2,
                                       iter_warmup = 500,
                                       iter_sampling = 1000) {
  # Validate distribution parameter
  distribution <- match.arg(distribution, choices = c("gamma", "lognormal"))

  # Use method of moments for quick parameter estimates
  if (distribution == "gamma") {
    # Method of moments for gamma distribution
    mean_est <- mean(data$delay_observed)
    var_est <- var(data$delay_observed)
    scale_est <- var_est / mean_est
    shape_est <- mean_est / scale_est
    param1_est <- shape_est
    param2_est <- scale_est
  } else {
    # Method of moments for lognormal distribution
    log_data <- log(data$delay_observed)
    param1_est <- mean(log_data)  # meanlog
    param2_est <- sd(log_data)    # sdlog
  }

  data.frame(
    scenario_id = scenario_id,
    sample_size = sample_size,
    model = "naive",
    distribution = distribution,
    mean_est = mean(data$delay_observed),
    sd_est = sd(data$delay_observed),
    param1_est = param1_est,
    param2_est = param2_est,
    runtime_seconds = 0.01
  )
}

#' Extract sampled data for a given scenario and sample size
#'
#' @param monte_carlo_samples List of monte carlo sample data frames
#' @param fitting_grid Single row from fitting grid with scenario_id and
#'   sample_size
#' @return Filtered data frame with sampled data for the scenario
#' @export
extract_sampled_data <- function(monte_carlo_samples, fitting_grid) {
  sample_key <- paste(fitting_grid$scenario_id, 
                      fitting_grid$sample_size, sep = "_")
  sampled_data <- dplyr::bind_rows(monte_carlo_samples) |>
    dplyr::filter(.data$sample_size_scenario == sample_key)

  # Check if we have valid data
  if (nrow(sampled_data) == 0 || !"delay_observed" %in% names(sampled_data)) {
    return(NULL)
  }

  sampled_data
}

#' Extract data for unified fitting grid
#'
#' Works with the new tar_group_by fitting_grid structure to extract
#' data from either monte_carlo_samples or ebola_case_study_data
#'
#' @param fitting_grid_group Single group from grouped fitting grid
#' @param monte_carlo_samples Monte Carlo samples for simulations 
#' @param ebola_case_study_data Ebola case study data
#' @return Data frame ready for model fitting
#' @export
extract_fitting_data <- function(fitting_grid_group, monte_carlo_samples, 
                                ebola_case_study_data) {
  # Get the first row to check data type
  data_type <- fitting_grid_group$data_type[1]
  
  if (data_type == "simulation") {
    # Extract from monte_carlo_samples
    extract_sampled_data(monte_carlo_samples, fitting_grid_group)
  } else if (data_type == "ebola") {
    # Extract from ebola_case_study_data
    dataset_id <- fitting_grid_group$dataset_id[1]
    
    # Find matching Ebola data
    ebola_data <- ebola_case_study_data |>
      dplyr::mutate(
        full_dataset_id = paste0("ebola_", window_id, "_", analysis_type)
      ) |>
      dplyr::filter(full_dataset_id == dataset_id)
    
    if (nrow(ebola_data) == 0) {
      return(NULL)
    }
    
    # Extract the nested data
    case_data <- ebola_data$data[[1]]
    
    # Format to match expected structure
    case_data |>
      dplyr::mutate(
        delay_observed = as.numeric(sample_date - symptom_onset_date),
        # Add censoring window information
        prim_cens_lower = 0,
        prim_cens_upper = 1,  # Daily censoring
        sec_cens_lower = delay_observed,
        sec_cens_upper = delay_observed + 1,
        # Add metadata
        relative_obs_time = ebola_data$end_day[1] - ebola_data$start_day[1],
        distribution = fitting_grid_group$distribution[1],
        growth_rate = fitting_grid_group$growth_rate[1]
      )
  } else {
    stop("Unknown data_type: ", data_type)
  }
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
  params <- setNames(split(param_summary, param_summary$variable),
                     param_summary$variable)

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
    runtime_seconds = runtime$toc - runtime$tic
  )
}

#' Create empty results data frame for failed fits
#'
#' @param fitting_grid Single row from fitting grid
#' @param method Character string identifying the method
#' @return Data frame with NA values in standard format
#' @export  
create_empty_results <- function(fitting_grid, method) {
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
    runtime_seconds = NA_real_
  )
}

#' Get distribution ID for Stan models
#'
#' @param distribution Character string: "gamma" or "lognormal"
#' @return Integer distribution ID for Stan
#' @export
get_distribution_id <- function(distribution) {
  if (distribution == "gamma") 1L else 2L
}

#' Extract distribution and growth rate from sampled data
#'
#' @param sampled_data Data frame with distribution and growth_rate columns
#' @return List with distribution and growth_rate
#' @export  
extract_distribution_info <- function(sampled_data) {
  list(
    distribution = sampled_data$distribution[1],
    growth_rate = sampled_data$growth_rate[1]
  )
}

#' Prepare Stan data list for naive and Ward models
#'
#' @param sampled_data Data frame with delay observations
#' @param distribution Character string: "gamma" or "lognormal"
#' @param growth_rate Numeric growth rate value
#' @param model_type Character: "naive" or "ward"
#' @return List of Stan data
#' @export
prepare_stan_data <- function(sampled_data, distribution, growth_rate, model_type = "naive") {
  dist_id <- get_distribution_id(distribution)
  
  if (model_type == "naive") {
    list(
      N = nrow(sampled_data),
      delay_observed = sampled_data$delay_observed,
      dist_id = dist_id
    )
  } else if (model_type == "ward") {
    # Get censoring windows and observation times
    pwindow_widths <- sampled_data$prim_cens_upper - sampled_data$prim_cens_lower
    swindow_widths <- sampled_data$sec_cens_upper - sampled_data$sec_cens_lower
    obs_times <- rep(sampled_data$relative_obs_time[1], nrow(sampled_data))
    
    list(
      N = nrow(sampled_data),
      Y = sampled_data$delay_observed,
      obs_times = obs_times,           
      pwindow_widths = pwindow_widths, 
      swindow_widths = swindow_widths, 
      dist_id = dist_id,
      prior_only = 0
    )
  } else {
    stop("Unknown model_type: ", model_type)
  }
}
