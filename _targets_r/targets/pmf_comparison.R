tar_target(
  pmf_comparison,
  {
    library(primarycensored)
    
    # Compare analytical, numerical, and Monte Carlo PMFs
    purrr::map_dfr(distributions$dist_name, function(dist_name) {
      dist_info <- distributions[distributions$dist_name == dist_name, ]
      
      # Define delay values to evaluate
      delays <- 0:20
      
      # Analytical PMF (for gamma and lognormal)
      if (dist_info$has_analytical) {
        if (dist_name == "gamma") {
          analytical_pmf <- dprimarycensored(
            x = delays,
            pdist = pgamma,
            pwindow = 1,
            swindow = 1,
            D = Inf,
            shape = dist_info$param1,
            rate = 1/dist_info$param2  # Convert scale to rate
          )
        } else if (dist_name == "lognormal") {
          analytical_pmf <- dprimarycensored(
            x = delays,
            pdist = plnorm,
            pwindow = 1,
            swindow = 1,
            D = Inf,
            meanlog = dist_info$param1,
            sdlog = dist_info$param2
          )
        }
      } else {
        analytical_pmf <- rep(NA, length(delays))
      }
      
      # For numerical comparison, we'll compute the same distributions
      # The package will automatically use numerical methods when needed
      if (dist_name == "gamma") {
        numerical_pmf <- dprimarycensored(
          x = delays,
          pdist = pgamma,
          pwindow = 1,
          swindow = 1,
          D = Inf,
          shape = dist_info$param1,
          rate = 1/dist_info$param2  # Convert scale to rate
        )
      } else if (dist_name == "lognormal") {
        numerical_pmf <- dprimarycensored(
          x = delays,
          pdist = plnorm,
          pwindow = 1,
          swindow = 1,
          D = Inf,
          meanlog = dist_info$param1,
          sdlog = dist_info$param2
        )
      } else {
        # Burr distribution - would need custom implementation
        numerical_pmf <- rep(NA, length(delays))
      }
      
      # Get Monte Carlo PMF
      mc_data <- monte_carlo_samples[
        monte_carlo_samples$distribution == dist_name & 
        monte_carlo_samples$sample_size == 10000,
      ]
      
      # Create complete PMF including zeros
      mc_pmf <- numeric(length(delays))
      for (i in seq_along(delays)) {
        matching_rows <- mc_data[mc_data$delay == delays[i], ]
        if (nrow(matching_rows) > 0) {
          mc_pmf[i] <- matching_rows$probability[1]
        }
      }
      
      # Calculate total variation distance
      tvd_analytical <- if(any(!is.na(analytical_pmf))) {
        sum(abs(analytical_pmf - mc_pmf)) / 2
      } else { NA }
      
      tvd_numerical <- if(any(!is.na(numerical_pmf))) {
        sum(abs(numerical_pmf - mc_pmf)) / 2
      } else { NA }
      
      data.frame(
        distribution = dist_name,
        method = c("analytical", "numerical"),
        total_variation_distance = c(tvd_analytical, tvd_numerical)
      )
    })
  }
)
