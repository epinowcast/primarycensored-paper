tar_target(
  naive_fits,
  {
    library(cmdstanr)
    
    # Map distribution names to IDs
    dist_map <- c("gamma" = 1, "lognormal" = 2)
    dist_id <- dist_map[simulated_data$distribution[1]]
    
    # Skip Burr distribution (no analytical form in naive model)
    if (is.na(dist_id)) {
      return(data.frame(
        scenario_id = simulated_data$scenario_id[1],
        method = "naive",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = 1,
        loglik = NA
      ))
    }
    
    # Prepare data for Stan
    stan_data <- list(
      N = nrow(simulated_data),
      delay_lower = simulated_data$sec_cens_lower - simulated_data$prim_cens_lower,
      delay_upper = simulated_data$sec_cens_upper - simulated_data$prim_cens_upper,
      dist_id = dist_id
    )
    
    # Compile and fit model
    mod <- cmdstan_model(here("stan/naive_delay_model.stan"))
    
    fit <- mod$sample(
      data = stan_data,
      seed = 123,
      chains = 2,
      parallel_chains = 2,
      iter_warmup = 500,
      iter_sampling = 1000,
      refresh = 0
    )
    
    # Extract estimates
    draws <- fit$draws(variables = c("param1", "param2"), format = "df")
    
    data.frame(
      scenario_id = simulated_data$scenario_id[1],
      method = "naive",
      param1_est = mean(draws$param1),
      param1_se = sd(draws$param1),
      param2_est = mean(draws$param2),
      param2_se = sd(draws$param2),
      convergence = max(fit$summary()$rhat, na.rm = TRUE) < 1.01,
      loglik = NA
    )
  },
  pattern = map(simulated_data)
)
