tar_target(
  ward_fits,
  {
    # Placeholder for Ward et al. Stan model
    # Would implement latent variable approach
    
    data.frame(
      scenario_id = simulated_data$scenario_id[1],
      method = "ward",
      param1_est = 5.1,
      param1_se = 0.2,
      param2_est = 1.1,
      param2_se = 0.1,
      convergence = 0,
      loglik = -1000
    )
  },
  pattern = map(simulated_data)
)
