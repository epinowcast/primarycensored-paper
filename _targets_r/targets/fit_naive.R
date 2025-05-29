tar_target(
  naive_fits,
  {
    library(fitdistrplus)
    
    # Skip Burr distribution
    if (simulated_data$distribution[1] == "burr") {
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
    
    # Naive approach: use observed delays directly, ignoring primary censoring
    obs_delays <- simulated_data$delay_observed
    
    # Remove any infinite values if truncation applied
    obs_delays <- obs_delays[is.finite(obs_delays)]
    
    # Fit distribution using method of moments as a naive approach
    if (simulated_data$distribution[1] == "gamma") {
      # Method of moments for gamma
      mean_delay <- mean(obs_delays)
      var_delay <- var(obs_delays)
      scale_est <- var_delay / mean_delay
      shape_est <- mean_delay / scale_est
      
      param1_est <- shape_est
      param2_est <- scale_est
      
      # Rough standard error estimates
      param1_se <- shape_est / sqrt(length(obs_delays))
      param2_se <- scale_est / sqrt(length(obs_delays))
      
    } else if (simulated_data$distribution[1] == "lognormal") {
      # Method of moments for lognormal
      log_delays <- log(obs_delays[obs_delays > 0])
      meanlog_est <- mean(log_delays)
      sdlog_est <- sd(log_delays)
      
      param1_est <- meanlog_est
      param2_est <- sdlog_est
      
      # Rough standard error estimates
      param1_se <- sdlog_est / sqrt(length(log_delays))
      param2_se <- sdlog_est / sqrt(2 * length(log_delays))
    }
    
    data.frame(
      scenario_id = simulated_data$scenario_id[1],
      method = "naive",
      param1_est = param1_est,
      param1_se = param1_se,
      param2_est = param2_est,
      param2_se = param2_se,
      convergence = 0,
      loglik = NA
    )
  },
  pattern = map(simulated_data)
)
