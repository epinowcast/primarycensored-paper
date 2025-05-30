tar_target(
  ebola_case_study_data,
  {
    # Get the base date (earliest symptom onset)
    base_date <- min(ebola_data$symptom_onset_date)
    
    # Create window start and end dates
    window_start <- base_date + observation_windows$start_day
    window_end <- base_date + observation_windows$end_day
    
    # Filter data based on analysis type
    filtered_data <- ebola_data |>
      dplyr::filter(
        symptom_onset_date >= window_start,  # LHS: based on onset date
        if (ebola_case_study_scenarios$analysis_type == "real_time") {
          sample_date < window_end  # RHS: based on sample date
        } else {
          symptom_onset_date < window_end  # RHS: based on onset date
        }
      )
    # Return combined metadata and data
    data.frame(
      window_id = observation_windows$window_id,
      analysis_type = ebola_case_study_scenarios$analysis_type,
      window_label = observation_windows$window_label,
      start_day = observation_windows$start_day,
      end_day = observation_windows$end_day,
      n_cases = nrow(filtered_data),
      data = I(list(filtered_data))  # Use I() to store data frame in list column
    )
  },
  pattern = cross(observation_windows, ebola_case_study_scenarios)
)
