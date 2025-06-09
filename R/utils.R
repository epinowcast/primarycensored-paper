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
#' Converts date pairs to delay format with proper censoring intervals and
#' analysis-type specific truncation times:
#' - Real-time: Truncated at window end (simulates real-time analysis)
#' - Retrospective: Truncated at outbreak end (simulates post-outbreak analysis)
#'
#' @param case_study_row A single row from ebola_case_study_data containing
#'   window metadata and a data list column with the actual observations
#' @return A data frame row with metadata and nested delay data
#' @export
transform_ebola_to_delays <- function(case_study_row) {
  # Suppress CMD check warnings for dplyr usage
  symptom_onset_date <- sample_date <- delay_observed <- NULL

  # Extract the data frame from the nested structure
  ebola_data <- case_study_row$data[[1]]

  # Extract metadata
  window_id <- case_study_row$window_id
  analysis_type <- case_study_row$analysis_type
  window_label <- case_study_row$window_label
  start_day <- case_study_row$start_day
  end_day <- case_study_row$end_day

  # Validate input data
  if (nrow(ebola_data) == 0) {
    warning("Empty data frame provided to transform_ebola_to_delays")
    # Return row with empty nested data maintaining structure
    return(data.frame(
      window_id = window_id,
      analysis_type = analysis_type,
      window_label = window_label,
      start_day = start_day,
      end_day = end_day,
      n_cases = 0,
      data = I(list(data.frame()))
    ))
  }

  if (any(is.na(ebola_data$symptom_onset_date)) ||
        any(is.na(ebola_data$sample_date))) {
    warning("Missing dates found in Ebola data - ",
            "these will result in NA delays")
  }

  # Calculate dates for truncation based on analysis type
  outbreak_start <- min(ebola_data$symptom_onset_date, na.rm = TRUE)
  # window_end_day is days since outbreak start, so add to get actual date
  window_end_date <- outbreak_start + end_day

  # For retrospective analysis, use end of outbreak;
  # for real-time, use window end
  if (analysis_type == "retrospective") {
    # Use end of outbreak (maximum sample date)
    truncation_date <- max(ebola_data$sample_date, na.rm = TRUE)
  } else {
    # Real-time analysis: truncate at window end (RHS of window)
    truncation_date <- window_end_date
  }

  # Transform the data
  transformed_data <- ebola_data |>
    dplyr::mutate(
      # Calculate delay from symptom onset to sample test
      delay_observed = as.numeric(sample_date - symptom_onset_date),
      # Primary event (onset) censoring - assuming daily reporting
      prim_cens_lower = 0,
      prim_cens_upper = 1,
      # Secondary event (sample) censoring - assuming daily reporting
      sec_cens_lower = delay_observed,
      sec_cens_upper = delay_observed + 1,
      # Observation time for truncation (analysis-type dependent)
      relative_obs_time = as.numeric(truncation_date - symptom_onset_date)
    ) |>
    dplyr::select(-symptom_onset_date, -sample_date)  # Remove date columns

  # Return row with metadata and nested transformed data
  data.frame(
    window_id = window_id,
    analysis_type = analysis_type,
    window_label = window_label,
    start_day = start_day,
    end_day = end_day,
    n_cases = nrow(transformed_data),
    data = I(list(transformed_data))
  )
}

#' Summarise Ebola delay data by window and analysis type
#'
#' @param ebola_delay_data A data frame with rows containing metadata and
#'   nested delay data
#' @return A data frame with summary statistics for each window/analysis
#' @export
summarise_ebola_windows <- function(ebola_delay_data) {

  # Validate input data
  if (nrow(ebola_delay_data) == 0) {
    warning("Empty data frame provided to summarise_ebola_windows")
    return(data.frame(
      window_id = character(),
      analysis_type = character(),
      window_label = character(),
      n_observations = integer(),
      mean_delay = numeric(),
      median_delay = numeric(),
      sd_delay = numeric(),
      min_delay = numeric(),
      max_delay = numeric(),
      mean_relative_obs_time = numeric(),
      median_relative_obs_time = numeric(),
      sd_relative_obs_time = numeric(),
      min_relative_obs_time = numeric(),
      max_relative_obs_time = numeric()
    ))
  }

  # Process each row to extract summary statistics
  result_list <- lapply(seq_len(nrow(ebola_delay_data)), function(i) {
    row <- ebola_delay_data[i, ]

    if (row$n_cases > 0 && length(row$data[[1]]) > 0) {
      df <- row$data[[1]]
      data.frame(
        window_id = row$window_id,
        analysis_type = row$analysis_type,
        window_label = row$window_label,
        n_observations = row$n_cases,
        mean_delay = mean(df$delay_observed, na.rm = TRUE),
        median_delay = stats::median(df$delay_observed, na.rm = TRUE),
        sd_delay = stats::sd(df$delay_observed, na.rm = TRUE),
        min_delay = min(df$delay_observed, na.rm = TRUE),
        max_delay = max(df$delay_observed, na.rm = TRUE),
        mean_relative_obs_time = mean(df$relative_obs_time, na.rm = TRUE),
        median_relative_obs_time = stats::median(df$relative_obs_time,
                                                 na.rm = TRUE),
        sd_relative_obs_time = stats::sd(df$relative_obs_time, na.rm = TRUE),
        min_relative_obs_time = min(df$relative_obs_time, na.rm = TRUE),
        max_relative_obs_time = max(df$relative_obs_time, na.rm = TRUE)
      )
    } else {
      data.frame(
        window_id = if (length(row$window_id) > 0) {
          row$window_id
        } else {
          NA_character_
        },
        analysis_type = if (length(row$analysis_type) > 0) {
          row$analysis_type
        } else {
          NA_character_
        },
        window_label = if (length(row$window_label) > 0) {
          row$window_label
        } else {
          NA_character_
        },
        n_observations = 0,
        mean_delay = NA_real_,
        median_delay = NA_real_,
        sd_delay = NA_real_,
        min_delay = NA_real_,
        max_delay = NA_real_,
        mean_relative_obs_time = NA_real_,
        median_relative_obs_time = NA_real_,
        sd_relative_obs_time = NA_real_,
        min_relative_obs_time = NA_real_,
        max_relative_obs_time = NA_real_
      )
    }
  })

  # Combine all results
  dplyr::bind_rows(result_list)
}
