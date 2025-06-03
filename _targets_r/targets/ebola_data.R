tar_target(ebola_data, {
  ebola_data_raw |>
    dplyr::rename(
      symptom_onset_date = Date.of.symptom.onset,
      sample_date = Date.of.sample.tested
    ) |>
    dplyr::mutate(
      case_id = ID,
      symptom_onset_date = as.Date(symptom_onset_date, format = "%d-%b-%y"),
      sample_date = as.Date(sample_date, format = "%d-%b-%y")
    ) |>
    dplyr::select(case_id, symptom_onset_date, sample_date) |>
    dplyr::filter(
      !is.na(symptom_onset_date),
      !is.na(sample_date),
      sample_date >= symptom_onset_date
    )
})