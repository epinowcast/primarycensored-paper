#' Setup PMF calculation inputs
#'
#' @param scenarios Scenario data frame row
#' @param distributions Distribution data frame
#' @param growth_rate Growth rate parameter
#' @param is_numerical Logical indicating if numerical integration should be
#' used
#' @return List with calculation inputs
#' @export
setup_pmf_inputs <- function(scenarios, distributions, growth_rate,
                             is_numerical = FALSE) {
  # Get distribution info with parameter names
  dist_info <- distributions[
    distributions$dist_name == scenarios$distribution,
  ]

  # Always evaluate delays 0:20 for consistency
  delays <- 0:20

  # Define which delays are valid (ensure x + swindow <= D)
  if (is.finite(scenarios$relative_obs_time)) {
    # For finite truncation, only evaluate delays where delay + swindow <= D
    valid_delays <- delays[
      delays + scenarios$secondary_width <= scenarios$relative_obs_time
    ]
  } else {
    # For infinite truncation, all delays are valid
    valid_delays <- delays
  }

  # Get the distribution function
  pdist <- get(paste0("p", dist_info$dist_family))

  # For numerical integration, add name attribute to trigger it
  if (is_numerical) {
    pdist <- primarycensored::add_name_attribute(pdist, "pdistnumerical")
  }

  # Build arguments list
  args <- list(
    x = valid_delays,
    pdist = pdist,
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    dprimary = get_primary_dist(growth_rate),
    dprimary_args = get_primary_args(growth_rate)
  )

  # Add distribution parameters using named arguments
  args[[dist_info$param1_name]] <- dist_info$param1
  args[[dist_info$param2_name]] <- dist_info$param2

  list(
    delays = delays,
    valid_delays = valid_delays,
    args = args
  )
}

#' Format PMF results consistently
#'
#' @param scenarios Scenario data frame row
#' @param delays Vector of all delays
#' @param pmf_values Vector of PMF values
#' @param method Character string for method name
#' @param runtime_seconds Runtime in seconds
#' @return Data frame with formatted results
#' @export
format_pmf_results <- function(scenarios, delays, pmf_values, method,
                               runtime_seconds) {
  # Extract scalar values to avoid row name warnings
  scenario_id <- scenarios$scenario_id[1]
  distribution <- scenarios$distribution[1]
  truncation <- scenarios$truncation[1]
  censoring <- scenarios$censoring[1]
  growth_rate <- scenarios$growth_rate[1]

  data.frame(
    scenario_id = rep(scenario_id, length(delays)),
    distribution = rep(distribution, length(delays)),
    truncation = rep(truncation, length(delays)),
    censoring = rep(censoring, length(delays)),
    growth_rate = rep(growth_rate, length(delays)),
    method = rep(method, length(delays)),
    delay = delays,
    probability = pmf_values,
    runtime_seconds = rep(runtime_seconds, length(delays)),
    stringsAsFactors = FALSE
  )
}

#' Calculate PMF using primarycensored
#'
#' @param scenarios Scenario data frame row
#' @param distributions Distribution data frame
#' @param growth_rate Growth rate parameter
#' @param method Character string for method name ("analytical" or "numerical")
#' @return Data frame with PMF results
#' @export
calculate_pmf <- function(scenarios, distributions, growth_rate,
                          method = c("analytical", "numerical")) {
  method <- match.arg(method)

  # Start timing
  tictoc::tic(paste0(method, "_pmf"))

  # Setup inputs
  inputs <- setup_pmf_inputs(
    scenarios,
    distributions,
    growth_rate,
    is_numerical = (method == "numerical")
  )

  # Initialize probability vector with NAs
  pmf_values <- rep(NA_real_, length(inputs$delays))

  # Calculate PMF only for valid delays
  if (length(inputs$valid_delays) > 0) {
    calculated_values <- do.call(primarycensored::dprimarycensored, inputs$args)
    # Fill in the valid delays with calculated values
    pmf_values[inputs$delays %in% inputs$valid_delays] <- calculated_values
  }

  # Get runtime
  runtime <- tictoc::toc(quiet = TRUE)
  runtime_seconds <- runtime$toc - runtime$tic

  # Format and return results
  format_pmf_results(
    scenarios = scenarios,
    delays = inputs$delays,
    pmf_values = pmf_values,
    method = method,
    runtime_seconds = runtime_seconds
  )
}

#' Get primary distribution function based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return Function for primary distribution (uniform if growth_rate is 0,
#' exponential growth otherwise)
#' @export
get_primary_dist <- function(growth_rate) {
  if (growth_rate == 0) {
    dunif
  } else {
    primarycensored::dexpgrowth
  }
}

#' Get primary distribution arguments based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return List of arguments for the primary distribution
#' @export
get_primary_args <- function(growth_rate) {
  if (growth_rate == 0) {
    list() # dunif uses default args from pwindow
  } else {
    list(r = growth_rate)
  }
}

#' Get primary random generation function based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return Function for primary distribution random generation (runif if
#' growth_rate is 0, rexpgrowth otherwise)
#' @export
get_rprimary <- function(growth_rate) {
  if (growth_rate == 0) {
    stats::runif
  } else {
    primarycensored::rexpgrowth
  }
}

#' Get primary random generation arguments based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return List of arguments for the primary distribution random generation
#' @export
get_rprimary_args <- function(growth_rate) {
  if (growth_rate == 0) {
    list() # runif uses pwindow for min/max
  } else {
    list(r = growth_rate)
  }
}

#' Get primary density function based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return Function for primary distribution density (dunif if
#' growth_rate is 0, dexpgrowth otherwise)
#' @export
get_dprimary <- function(growth_rate) {
  if (growth_rate == 0) {
    stats::dunif
  } else {
    primarycensored::dexpgrowth
  }
}

#' Get primary density arguments based on growth rate
#'
#' @param growth_rate Growth rate parameter
#' @return List of arguments for the primary distribution density
#' @export
get_dprimary_args <- function(growth_rate) {
  if (growth_rate == 0) {
    list() # dunif uses min/max from pwindow
  } else {
    list(r = growth_rate)
  }
}
