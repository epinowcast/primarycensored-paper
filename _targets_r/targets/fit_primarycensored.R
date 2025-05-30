tar_target(
  primarycensored_fits,
  {
    library(primarycensored)
    
    # Get the full dataset for this scenario
    scenario_idx <- which(scenarios$scenario_id == fitting_grid$scenario_id)
    full_data <- simulated_data[[scenario_idx]]
    
    # Sample the requested number of observations
    n <- fitting_grid$sample_size
    if (n > nrow(full_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = n,
        method = "primarycensored",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = NA,
        loglik = NA,
        runtime_seconds = NA
      ))
    }
    
    sampled_data <- full_data[1:n, ]
    
    # Start timing after data preparation
    tictoc::tic("fit_primarycensored")
    
    # Fit using fitdistr for maximum likelihood
    fit_result <- fitdistcens(
      censdata = sampled_data,
      distr = sampled_data$distribution[1],
      start = list(shape = 4, scale = 1)  # Initial values
    )
    
    runtime <- tictoc::toc(quiet = TRUE)
    
    # Extract estimates
    data.frame(
      scenario_id = fitting_grid$scenario_id,
      sample_size = n,
      method = "primarycensored",
      param1_est = fit_result$estimate[1],
      param1_se = fit_result$sd[1],
      param2_est = fit_result$estimate[2],
      param2_se = fit_result$sd[2],
      convergence = fit_result$convergence,
      loglik = fit_result$loglik,
      runtime_seconds = runtime$toc - runtime$tic
    )
  },
  pattern = map(fitting_grid)
)
