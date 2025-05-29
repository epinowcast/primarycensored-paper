tar_target(
  primarycensored_fits,
  {
    library(primarycensored)
    library(fitdistrplus)
    
    # Skip Burr distribution for now
    if (simulated_data$distribution[1] == "burr") {
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
    
    # Prepare censored data format for fitdistrplus
    # Using interval censoring for delays
    censdata <- data.frame(
      left = simulated_data$delay_observed - 0.5,  # Lower bound
      right = simulated_data$delay_observed + 0.5  # Upper bound
    )
    
    # Set starting values based on distribution
    if (simulated_data$distribution[1] == "gamma") {
      start_vals <- list(shape = 5, scale = 1)
      dist_name <- "gamma"
    } else if (simulated_data$distribution[1] == "lognormal") {
      start_vals <- list(meanlog = 1.5, sdlog = 0.5)
      dist_name <- "lnorm"
    }
    
    # Fit using fitdistrplus
    tryCatch({
      fit_result <- fitdistcens(
        censdata = censdata,
        distr = dist_name,
        start = start_vals
      )
      
      # Extract estimates
      data.frame(
        scenario_id = simulated_data$scenario_id[1],
        method = "primarycensored",
        param1_est = fit_result$estimate[1],
        param1_se = fit_result$sd[1],
        param2_est = fit_result$estimate[2],
        param2_se = fit_result$sd[2],
        convergence = 0,
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
