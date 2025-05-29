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
        analytical_pmf <- dprimarycensored(
          x = delays,
          pdist = get(paste0("p", dist_info$dist_family)),
          pwindow = 1,
          swindow = 1,
          D = Inf,
          dprimary = dunif,
          dist_params = list(
            shape = dist_info$param1,
            scale = dist_info$param2
          )
        )
      } else {
        analytical_pmf <- rep(NA, length(delays))
      }
      
      # Numerical PMF (all distributions)
      numerical_pmf <- dprimarycensored(
        x = delays,
        pdist = get(paste0("p", dist_info$dist_family)),
        pwindow = 1,
        swindow = 1,
        D = Inf,
        dprimary = dunif,
        dist_params = if(dist_name == "burr") {
          list(shape1 = dist_info$param1, shape2 = dist_info$param2, scale = dist_info$param3)
        } else {
          list(shape = dist_info$param1, scale = dist_info$param2)
        },
        use_numerical = TRUE
      )
      
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
