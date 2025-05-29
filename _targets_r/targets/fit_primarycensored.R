tar_target(
  primarycensored_fits,
  {
    library(primarycensored)
    
    # Prepare data in the format expected by fitdistdoublecens
    # Use the secondary censoring bounds as left/right
    censored_data <- data.frame(
      left = simulated_data$sec_cens_lower,
      right = simulated_data$sec_cens_upper
    )
    
    # Remove non-finite values
    censored_data <- censored_data[is.finite(censored_data$left) & is.finite(censored_data$right), ]
    
    # Skip if no data
    if (nrow(censored_data) == 0) {
      return(data.frame(
        scenario_id = simulated_data$scenario_id[1],
        method = "primarycensored",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = 1,
        loglik = NA
      ))
    }
    
    # Get truncation value
    D_value <- if (simulated_data$truncation[1] == "none") {
      Inf
    } else if (simulated_data$truncation[1] == "moderate") {
      10
    } else {
      5
    }
    
    # Set starting values based on distribution
    if (simulated_data$distribution[1] == "gamma") {
      start_vals <- list(shape = 5, scale = 1)
    } else if (simulated_data$distribution[1] == "lognormal") {
      start_vals <- list(meanlog = 1.5, sdlog = 0.5)
    }
    
    # Fit using fitdistdoublecens
    tryCatch({
      fit_result <- fitdistdoublecens(
        censdata = censored_data,
        distr = if(simulated_data$distribution[1] == "lognormal") "lnorm" else simulated_data$distribution[1],
        start = start_vals,
        pwindow = simulated_data$censoring[1],
        D = D_value
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
    }, error = function(e) {
      # Return NA values if fitting fails
      data.frame(
        scenario_id = simulated_data$scenario_id[1],
        method = "primarycensored",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = 1,
        loglik = NA
      )
    })
  },
  pattern = map(simulated_data)
)
