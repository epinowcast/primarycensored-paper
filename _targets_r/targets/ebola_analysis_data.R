tar_target(
  ebola_analysis_data,
  {
    # Prepare data for each observation window
    # Real implementation would handle date calculations properly
    
    observation_windows |>
      dplyr::rowwise() |>
      dplyr::mutate(
        data = list(
          ebola_data |>
            dplyr::filter(
              symptom_onset_date >= min(ebola_data$symptom_onset_date) + start_day,
              symptom_onset_date < min(ebola_data$symptom_onset_date) + end_day
            )
        )
      ) |>
      dplyr::ungroup()
  }
)
