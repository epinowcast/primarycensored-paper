tar_target(
  primarycensored_fits,
  {
    library(primarycensored)
    
    # Get scenario info
    scenario_info <- simulated_data[1, ]
    
    # Prepare data in format required by fitdistdoublecens
    # fitdistdoublecens expects columns named 'left' and 'right'
    fit_data <- data.frame(
      left = simulated_data$delay_observed,
      right = simulated_data$delay_observed + simulated_data$swindow
    )
    
    # Skip Burr distribution scenarios for now
    if (scenario_info$distribution == "burr") {
      return(data.frame(
        scenario_id = scenario_info$scenario_id,
        method = "primarycensored",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        param3_est = NA,
        param3_se = NA,
        convergence = 1,
        loglik = NA
      ))
    }
    
    # Set distribution and starting values
    if (scenario_info$distribution == "gamma") {
      dist_name <- "gamma"
      # Use rate parameterization (rate = 1/scale)
      start_vals <- list(shape = 5, rate = 1)
    } else if (scenario_info$distribution == "lognormal") {
      dist_name <- "lnorm" 
      start_vals <- list(meanlog = 1.5, sdlog = 0.5)
    }
    
    # Fit using primarycensored's fitdistdoublecens
    tryCatch({
      fit_result <- fitdistdoublecens(
        fit_data,
        distr = dist_name,
        start = start_vals,
        pwindow = scenario_info$pwindow,
        D = scenario_info$max_delay
      )
      
      # Extract estimates
      data.frame(
        scenario_id = scenario_info$scenario_id,
        method = "primarycensored",
        param1_est = fit_result$estimate[1],
        param1_se = fit_result$sd[1],
        param2_est = fit_result$estimate[2],
        param2_se = fit_result$sd[2],
        param3_est = if(length(fit_result$estimate) > 2) fit_result$estimate[3] else NA,
        param3_se = if(length(fit_result$sd) > 2) fit_result$sd[3] else NA,
        convergence = 0,
        loglik = fit_result$loglik
      )
    }, error = function(e) {
      # Return NA values if fitting fails
      warning("Primary censored fitting failed: ", e$message)
      data.frame(
        scenario_id = scenario_info$scenario_id,
        method = "primarycensored",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        param3_est = NA,
        param3_se = NA,
        convergence = 1,
        loglik = NA
      )
    })
  },
  pattern = map(simulated_data)
)
