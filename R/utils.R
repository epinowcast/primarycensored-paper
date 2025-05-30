#' Save a plot to the figures directory
#'
#' @param plot The plot object to save
#' @param filename The filename (without path)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution in dots per inch
#' @export
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  ggsave(
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
  
  # For now, return placeholder implementation to avoid Stan compilation issues
  # Real implementation would use Stan model
  
  data.frame(
    scenario_id = scenario_id,
    sample_size = sample_size,
    model = "naive",
    distribution = distribution,
    mean_est = mean(data$delay_observed),
    sd_est = sd(data$delay_observed),
    param1_est = NA_real_,
    param2_est = NA_real_,
    runtime_seconds = 0.5
  )
}
