#' Generate a Dataset of Censored Delays
#'
#' This function generates a simulated dataset of censored delays using the
#' specified random distribution and parameters.
#'
#' @param rdist A random number generating function that will be used to
#' generate delays
#' @param obs_time A single value or vector of observation times. If a vector is
#' provided, it will be sampled randomly for each observation.
#' @param pw_range Range of possible values for primary window, sampled randomly
#'  (default: 1:4)
#' @param sw_range Range of possible values for secondary window, sampled
#' randomly (default: 1:4)
#' @param n Number of samples to generate (default: 10000)
#' @param ... Additional parameters passed to the rdist function
#'
#' @return A data frame containing:
#'   \item{pwindow}{Primary window size for each observation}
#'   \item{obs_time}{Observation time for each sample}
#'   \item{observed_delay}{The observed (censored) delay}
#'   \item{observed_delay_upper}{Upper bound of the delay, minimum of obs_time
#' and observed_delay + swindow}
#' @export
#'
#' @details
#' The function generates censored delay data using the primarycensored
#' package's rpcens function. For each observation, it randomly samples primary
#' window sizes, secondary window sizes, and observation times from the provided
#' ranges.
#'
#' @examples
#' # Generate dataset with exponential delays
#' library(primarycensoredpaper)
#' data <- generate_dataset(rexp, obs_time = 1:10, rate = 0.1)
#'
#' @importFrom primarycensored rpcens
#' @importFrom dplyr mutate
generate_dataset <- function(
    rdist, obs_time, pw_range = 1:4, sw_range = 1:4,
    n = 10000, ...) {
  # Generate varying pwindow, swindow, and obs_time lengths
  pwindows <- sample(pw_range, n, replace = TRUE)
  swindows <- sample(sw_range, n, replace = TRUE)
  obs_times <- sample(obs_time, n, replace = TRUE)

  # Function to generate a single sample
  generate_sample <- function(pwindow, swindow, obs_time) {
    primarycensored::rpcens(
      1, rdist,
      pwindow = pwindow, swindow = swindow, D = obs_time,
      ...
    )
  }

  # Generate samples
  samples <- mapply(generate_sample, pwindows, swindows, obs_times)

  # Create initial data frame
  delay_data <- data.frame(
    pwindow = pwindows,
    obs_time = obs_times,
    observed_delay = samples, # this is the observed i.e. censored delay
    observed_delay_upper = samples + swindows # The upper bound of the delay
    # (i.e. the true delay is between the observed and the upper bound)
  ) |>
    dplyr::mutate(
      observed_delay_upper = pmin(obs_time, observed_delay_upper)
    )
  return(delay_data)
}
