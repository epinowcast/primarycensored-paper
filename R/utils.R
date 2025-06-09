#' Save a plot to the figures directory
#'
#' @param plot The plot object to save
#' @param filename The filename (without path)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution in dots per inch
#' @export
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  ggplot2::ggsave(
    filename = here::here("figures", filename),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
}

#' Save data to the results directory
#'
#' @param data The data object to save
#' @param filename The filename (without path)
#' @export
save_data <- function(data, filename) {
  write.csv(
    data,
    file = here::here("data/results", filename),
    row.names = FALSE
  )
}

#' Transform Ebola case study data from dates to numeric delays
#'
#' @param case_study_row A single row from ebola_case_study_data containing
#'   window metadata and a data list column with the actual observations
#' @return A data frame with numeric delay values and censoring intervals
#' @export
transform_ebola_to_delays <- function(case_study_row) {
  # Extract the data frame and window end day from the row
  ebola_data <- case_study_row$data[[1]]
  window_end_day <- case_study_row$end_day
  
  # Calculate window end date (days since start of outbreak)
  outbreak_start <- min(ebola_data$symptom_onset_date, na.rm = TRUE)
  window_end_date <- outbreak_start + window_end_day
  
  ebola_data |>
    dplyr::mutate(
      # Calculate delay from symptom onset to sample test
      delay_observed = as.numeric(sample_date - symptom_onset_date),
      # Primary event (onset) censoring - assuming daily reporting
      prim_cens_lower = 0,
      prim_cens_upper = 1,
      # Secondary event (sample) censoring - assuming daily reporting
      sec_cens_lower = delay_observed,
      sec_cens_upper = delay_observed + 1,
      # Observation time for truncation (time from onset to window end)
      relative_obs_time = as.numeric(window_end_date - symptom_onset_date)
    ) |>
    dplyr::select(-symptom_onset_date, -sample_date)  # Remove date columns
}

#' Summarise Ebola delay data by window and analysis type
#'
#' @param ebola_delay_data A data frame with transformed delay data containing
#'   window_id, analysis_type, and delay_observed columns
#' @return A data frame with summary statistics for each window/analysis combination
#' @export
summarise_ebola_windows <- function(ebola_delay_data) {
  ebola_delay_data |>
    dplyr::group_by(window_id, analysis_type) |>
    dplyr::summarise(
      n_observations = dplyr::n(),
      mean_delay = mean(delay_observed),
      median_delay = stats::median(delay_observed),
      sd_delay = stats::sd(delay_observed),
      min_delay = min(delay_observed),
      max_delay = max(delay_observed),
      mean_relative_obs_time = mean(relative_obs_time),
      .groups = "drop"
    )
}
