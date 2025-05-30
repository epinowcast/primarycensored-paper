tar_target(
  monte_carlo_samples,
  {
    # Generate Monte Carlo samples for each distribution and sample size
    purrr::map_dfr(distributions$dist_name, function(dist_name) {
      dist_info <- distributions[distributions$dist_name == dist_name, ]
      
      purrr::map_dfr(sample_sizes, function(n) {
        # Generate large Monte Carlo sample using do.call for parameters
        dist_args <- list(n = n)
        dist_args[[names(formals(get(paste0("r", dist_info$dist_family))))[2]]] <- dist_info$param1
        dist_args[[names(formals(get(paste0("r", dist_info$dist_family))))[3]]] <- dist_info$param2
        
        mc_samples <- rprimarycensored(
          n = n,
          rdist = function(n) do.call(get(paste0("r", dist_info$dist_family)), dist_args),
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
