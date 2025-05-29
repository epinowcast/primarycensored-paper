tar_target(
  naive_fits,
  {
    # Naive approach: treat censored delays as true delays
    obs_delays <- simulated_data$delay_observed
    obs_delays <- obs_delays[is.finite(obs_delays)]
    
    # Skip if no finite observations
    if (length(obs_delays) == 0) {
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
    
    # Method of moments estimation
    if (simulated_data$distribution[1] == "gamma") {
      mean_delay <- mean(obs_delays)
      var_delay <- var(obs_delays)
      
      # Gamma parameters from moments
      scale_est <- var_delay / mean_delay
      shape_est <- mean_delay / scale_est
      
      param1_est <- shape_est
      param2_est <- scale_est
      param1_se <- shape_est / sqrt(length(obs_delays))
      param2_se <- scale_est / sqrt(length(obs_delays))
      
    } else if (simulated_data$distribution[1] == "lognormal") {
      # Log-transform for lognormal
      log_delays <- log(obs_delays[obs_delays > 0])
      
      if (length(log_delays) == 0) {
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
      
      meanlog_est <- mean(log_delays)
      sdlog_est <- sd(log_delays)
      
      param1_est <- meanlog_est
      param2_est <- sdlog_est
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
