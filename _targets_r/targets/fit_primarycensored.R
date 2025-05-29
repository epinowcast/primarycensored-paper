tar_target(
  primarycensored_fits,
  {
    library(primarycensored)
    
    # Fit using fitdistr for maximum likelihood
    fit_result <- fitdistcens(
      censdata = simulated_data,
      distr = simulated_data$distribution[1],
      start = list(shape = 4, scale = 1)  # Initial values
    )
    
    # Extract estimates
    data.frame(
      scenario_id = simulated_data$scenario_id[1],
      method = "primarycensored",
      param1_est = fit_result$estimate[1],
      param1_se = fit_result$sd[1],
      param2_est = fit_result$estimate[2],
      param2_se = fit_result$sd[2],
      convergence = fit_result$convergence,
      loglik = fit_result$loglik
    )
  },
  pattern = map(simulated_data)
)
