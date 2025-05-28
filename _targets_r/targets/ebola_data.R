tar_target(
  ebola_data,
  {
    # Placeholder for Ebola linelist data
    # Real implementation would load Fang et al. 2016 data
    message("Loading Ebola case study data...")
    
    # Simulate example structure
    data.frame(
      case_id = 1:1000,
      symptom_onset_date = as.Date("2014-05-01") + sample(0:500, 1000, replace = TRUE),
      sample_date = as.Date("2014-05-01") + sample(5:510, 1000, replace = TRUE)
    ) |>
      dplyr::filter(sample_date > symptom_onset_date)
  }
)
