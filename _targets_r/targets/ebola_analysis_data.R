tar_target(
  ebola_analysis_data,
  {
    # Prepare data for each observation window
    # Real implementation would handle date calculations properly
    
    # Compute minimum symptom onset date once to avoid repeated calculations
    min_onset_date <- min(ebola_data$symptom_onset_date)
    
    # Use vectorized operations instead of rowwise
    observation_windows |>
      dplyr::mutate(
        data = purrr::map2(start_day, end_day, function(start, end) {
          ebola_data |>
            dplyr::filter(
              symptom_onset_date >= min_onset_date + start,
              symptom_onset_date <= min_onset_date + end  # Using inclusive interval
            )
        })
      )
  }
)
