tar_target(
  naive_fits,
  {
    library(dplyr)
    
    # Get all simulated data and filter to the specific scenario
    all_sim_data <- dplyr::bind_rows(simulated_data)
    full_data <- all_sim_data |>
      filter(scenario_id == fitting_grid$scenario_id)
    
    # Sample the requested number of observations
    n <- fitting_grid$sample_size
    if (n > nrow(full_data)) {
      return(data.frame(
        scenario_id = fitting_grid$scenario_id,
        sample_size = n,
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
    
    sampled_data <- full_data[1:n, ]
    
    # Use the new function for cleaner code
    .estimate_naive_delay_model(
      data = sampled_data,
      distribution = sampled_data$distribution[1],
      scenario_id = fitting_grid$scenario_id,
      sample_size = n
    )
  },
  pattern = map(fitting_grid)
)
