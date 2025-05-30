tar_target(
  ebola_model_fits,
  {
    # Fit models for both real-time and retrospective analyses
    # Assume gamma distribution as per manuscript
    
    list(
      window_id = ebola_case_study_data$window_id,
      analysis_type = ebola_case_study_data$analysis_type,
      window_label = ebola_case_study_data$window_label,
      n_cases = ebola_case_study_data$n_cases,
      primarycensored = list(shape = 2.5, scale = 3.2),
      naive = list(shape = 2.1, scale = 2.8),
      ward = list(shape = 2.6, scale = 3.3),
      runtime_pc = 5,
      runtime_ward = 150,
      ess_per_second_pc = 200,
      ess_per_second_ward = 10
    )
  },
  pattern = map(ebola_case_study_data)
)
