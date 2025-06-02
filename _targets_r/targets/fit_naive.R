tar_target(
  naive_fits,
  {
    library(dplyr)
    
    # Use pre-sampled data
    sample_key <- paste(fitting_grid$scenario_id, fitting_grid$sample_size, sep = "_")
    sampled_data <- dplyr::bind_rows(monte_carlo_samples) |>
      dplyr::filter(sample_size_scenario == sample_key)
    
    # Check if we have data
    if (nrow(sampled_data) == 0 || !"delay_observed" %in% names(sampled_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = fitting_grid$sample_size,
        method = "naive",
        param1_est = NA,
        param1_se = NA,
        param2_est = NA,
        param2_se = NA,
        convergence = NA,
        loglik = NA,
        runtime_seconds = NA
      ))
    }
    
    # Use the new function for cleaner code
    estimate_naive_delay_model(
      data = sampled_data,
      distribution = sampled_data$distribution[1],
      scenario_id = fitting_grid$scenario_id,
      sample_size = fitting_grid$sample_size
    )
  },
  pattern = map(fitting_grid)
)
