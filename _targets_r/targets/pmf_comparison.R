tar_target(
  pmf_comparison,
  {
    # library(primarycensored) # Removed - should be in globals
    
    # Compare analytical, numerical, and Monte Carlo PMFs
    purrr::map_dfr(distributions$dist_name, function(dist_name) {
      dist_info <- distributions[distributions$dist_name == dist_name, ]
      
      # Define delay values to evaluate
      delays <- 0:20
      
      # Build parameter list using stored parameter names
      params <- list()
      params[[dist_info$param1_name]] <- dist_info$param1
      params[[dist_info$param2_name]] <- dist_info$param2
      if (!is.na(dist_info$param3_name)) {
        params[[dist_info$param3_name]] <- dist_info$param3
      }
      
      # Get distribution function
      pdist_func <- get(paste0("p", dist_info$dist_family))
      
      # Analytical PMF (for gamma and lognormal)
      if (dist_info$has_analytical) {
        analytical_pmf <- do.call(dprimarycensored, c(
          list(x = delays, pdist = pdist_func, pwindow = 1, swindow = 1, D = Inf, dprimary = dunif),
          params
        ))
      } else {
        analytical_pmf <- rep(NA, length(delays))
      }
      
      # Numerical PMF (all distributions) - same parameters as analytical
      numerical_pmf <- do.call(dprimarycensored, c(
        list(x = delays, pdist = pdist_func, pwindow = 1, swindow = 1, D = Inf, dprimary = dunif),
        params
      ))
      
      # Get Monte Carlo PMF
      mc_pmf <- monte_carlo_samples %>%
        dplyr::filter(distribution == dist_name, sample_size == 10000) %>%
        dplyr::filter(delay %in% delays) %>%
        dplyr::pull(probability)
      
      # Calculate total variation distance
      tvd_analytical <- if(any(!is.na(analytical_pmf))) {
        sum(abs(analytical_pmf - mc_pmf)) / 2
      } else { NA }
      
      tvd_numerical <- sum(abs(numerical_pmf - mc_pmf)) / 2
      
      data.frame(
        distribution = dist_name,
        method = c("analytical", "numerical"),
        total_variation_distance = c(tvd_analytical, tvd_numerical)
      )
    })
  }
)
