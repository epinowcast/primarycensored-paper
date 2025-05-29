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
        if (dist_info$dist_family == "gamma") {
          mc_samples <- rprimarycensored(
            n = n,
            rdist = rgamma,
            rprimary = runif,
            pwindow = 1,
            swindow = 1,
            D = Inf,
            shape = dist_info$param1,
            scale = dist_info$param2
          )
        } else if (dist_info$dist_family == "lnorm") {
          mc_samples <- rprimarycensored(
            n = n,
            rdist = rlnorm,
            rprimary = runif,
            pwindow = 1,
            swindow = 1,
            D = Inf,
            meanlog = dist_info$param1,
            sdlog = dist_info$param2
          )
        }
        
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
