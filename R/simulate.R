# Simulation functions for primarycensored analysis

#' Simulate primary event times
#' @param n Number of events to simulate
#' @param rate Rate parameter for exponential growth
#' @param seed Random seed
#' @return Data frame with primary event times
simulate_primary_events <- function(n, rate = 0.1, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  # Placeholder: simulate exponential growth process
  times <- cumsum(rexp(n, rate = rate * seq_len(n)))
  
  data.frame(
    id = seq_len(n),
    primary_time = times
  )
}

#' Simulate secondary events given primary events
#' @param primary_data Data frame with primary event times
#' @param delay_params List with distribution parameters
#' @param distribution Character string naming the delay distribution
#' @return Data frame with primary and secondary event times
simulate_secondary_events <- function(primary_data, 
                                      delay_params = list(meanlog = 1.5, sdlog = 0.5),
                                      distribution = "lognormal") {
  n <- nrow(primary_data)
  
  # Placeholder: generate delays
  if (distribution == "lognormal") {
    delays <- rlnorm(n, meanlog = delay_params$meanlog, sdlog = delay_params$sdlog)
  } else {
    stop("Distribution not implemented: ", distribution)
  }
  
  primary_data$delay <- delays
  primary_data$secondary_time <- primary_data$primary_time + delays
  
  return(primary_data)
}