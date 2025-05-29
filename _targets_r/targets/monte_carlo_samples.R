tar_target(
  monte_carlo_samples,
  {
    library(primarycensored)
    sample_sizes <- c(10, 100, 1000, 10000)
    
    # Generate Monte Carlo samples for each distribution and sample size
    purrr::map_dfr(distributions$dist_name, function(dist_name) {
      dist_info <- distributions[distributions$dist_name == dist_name, ]
      
      purrr::map_dfr(sample_sizes, function(n) {
        # Generate large Monte Carlo sample
        mc_samples <- rprimarycensored(
          n = n,
          rdist = get(paste0("r", dist_info$dist_family)),
          rprimary = runif,
          pwindow = 1,
          swindow = 1,
          D = Inf
        )
        
        # Calculate empirical PMF
        pmf <- table(mc_samples) / n
        
        data.frame(
          distribution = dist_name,
          sample_size = n,
          delay = as.numeric(names(pmf)),
          probability = as.numeric(pmf)
        )
      })
    })
  }
)
