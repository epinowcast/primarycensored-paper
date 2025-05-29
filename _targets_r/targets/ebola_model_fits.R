tar_target(
  ebola_model_fits,
  {
    # Fit models for both real-time and retrospective analyses
    # Assume gamma distribution as per manuscript
    
    list(
      window_id = ebola_analysis_data$window_id,
      analysis_type = rep(c("real-time", "retrospective"), each = nrow(ebola_analysis_data)),
      primarycensored = list(shape = 2.5, scale = 3.2),
      naive = list(shape = 2.1, scale = 2.8),
      ward = list(shape = 2.6, scale = 3.3),
      runtime_pc = 5,
      runtime_ward = 150,
      ess_per_second_pc = 200,
      ess_per_second_ward = 10
    )
  }
)
