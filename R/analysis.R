# Analysis functions for primarycensored paper

#' Apply censoring to event data
#' @param data Data frame with event times
#' @param censoring_interval Numeric censoring interval (days)
#' @return Data frame with censored times
apply_censoring <- function(data, censoring_interval = 1) {
  data$primary_censored <- floor(data$primary_time / censoring_interval) * censoring_interval
  data$secondary_censored <- floor(data$secondary_time / censoring_interval) * censoring_interval
  return(data)
}

#' Calculate performance metrics
#' @param estimates Data frame with parameter estimates
#' @param true_values Data frame with true parameter values
#' @return Data frame with performance metrics
calculate_metrics <- function(estimates, true_values) {
  # Placeholder for performance metrics
  metrics <- merge(estimates, true_values, by = "parameter")
  
  metrics$bias <- metrics$estimate - metrics$true_value
  metrics$relative_bias <- metrics$bias / metrics$true_value
  metrics$coverage <- with(metrics, 
                           (true_value >= estimate - 1.96 * se) & 
                           (true_value <= estimate + 1.96 * se))
  
  return(metrics)
}

#' Run complete analysis for a scenario
#' @param scenario List with scenario parameters
#' @return List with results
run_scenario_analysis <- function(scenario) {
  # Simulate data
  primary_data <- simulate_primary_events(
    n = scenario$n,
    rate = scenario$rate,
    seed = scenario$seed
  )
  
  secondary_data <- simulate_secondary_events(
    primary_data,
    delay_params = scenario$delay_params,
    distribution = scenario$distribution
  )
  
  # Apply censoring
  censored_data <- apply_censoring(secondary_data, scenario$censoring_interval)
  
  # Fit models
  models <- list(
    primarycensored = fit_primarycensored(censored_data, ~ 1),
    naive = fit_naive_model(censored_data)
  )
  
  # Return results
  list(
    data = censored_data,
    models = models,
    scenario = scenario
  )
}