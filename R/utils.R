#' Save a plot to the figures directory
#'
#' @param plot The plot object to save
#' @param filename The filename (without path)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution in dots per inch
#' @export
.save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
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
.save_data <- function(data, filename) {
  write.csv(
    data,
    file = here::here("data/results", filename),
    row.names = FALSE
  )
}

#' Estimate delay distribution using naive model
#'
#' @param data Data frame with delay observations
#' @param distribution Character string naming the distribution ("gamma" or "lognormal")
#' @param scenario_id Scenario identifier
#' @param sample_size Sample size
#' @param seed Random seed for Stan
#' @param chains Number of chains
#' @param iter_warmup Number of warmup iterations
#' @param iter_sampling Number of sampling iterations
#' @return Data frame with estimates
#' @export
.estimate_naive_delay_model <- function(data, distribution, scenario_id, sample_size,
                                        seed = 123, chains = 2, iter_warmup = 500, 
                                        iter_sampling = 1000) {
  library(cmdstanr)
  
  # Map distribution names to IDs
  dist_map <- c("gamma" = 1, "lognormal" = 2)
  dist_id <- dist_map[distribution]
  
  # Skip unsupported distributions
  if (is.na(dist_id)) {
    return(data.frame(
      scenario_id = scenario_id,
      sample_size = sample_size,
      method = "naive",
      param1_est = NA,
      param1_se = NA,
      param2_est = NA,
      param2_se = NA,
      convergence = NA,
      loglik = NA,
      runtime_seconds = NA
    ))
  }
  
  # Prepare data for Stan
  stan_data <- list(
    N = nrow(data),
    delay_lower = data$sec_cens_lower - data$prim_cens_lower,
    delay_upper = data$sec_cens_upper - data$prim_cens_upper,
    dist_id = dist_id
  )
  
  # Compile model (not timed)
  mod <- cmdstan_model(here::here("stan/naive_delay_model.stan"))
  
  # Start timing after compilation
  tictoc::tic("naive_fit")
  
  fit <- mod$sample(
    data = stan_data,
    seed = seed,
    chains = chains,
    parallel_chains = chains,
    iter_warmup = iter_warmup,
    iter_sampling = iter_sampling,
    refresh = 0
  )
  
  runtime <- tictoc::toc(quiet = TRUE)
  
  # Extract estimates
  draws <- fit$draws(variables = c("param1", "param2"), format = "df")
  
  data.frame(
    scenario_id = scenario_id,
    sample_size = sample_size,
    method = "naive",
    param1_est = mean(draws$param1),
    param1_se = sd(draws$param1),
    param2_est = mean(draws$param2),
    param2_se = sd(draws$param2),
    convergence = max(fit$summary()$rhat, na.rm = TRUE) < 1.01,
    loglik = NA,
    runtime_seconds = runtime$toc - runtime$tic
  )
}