test_that("transform_ebola_to_delays converts dates to numeric delays", {
  # Create test data that mimics ebola_case_study_data structure
  test_case_study_row <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 2
  )

  # Create test data
  test_data <- data.frame(
    case_id = c("case1", "case2"),
    symptom_onset_date = as.Date(c("2014-05-01", "2014-05-10")),
    sample_date = as.Date(c("2014-05-05", "2014-05-15"))
  )

  # Add data as list column (matching the actual structure)
  test_case_study_row$data <- I(list(test_data))

  # Transform the data
  result <- transform_ebola_to_delays(test_case_study_row)

  # Check structure - should be a single row with nested data
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  # Check metadata columns
  expect_equal(result$window_id, "window_1")
  expect_equal(result$analysis_type, "real_time")
  expect_equal(result$window_label, "0-60 days")
  expect_equal(result$n_cases, 2)

  # Check nested data structure
  expect_true("data" %in% names(result))
  expect_true(is.list(result$data))

  # Extract nested data for detailed checks
  nested_data <- result$data[[1]]
  expect_s3_class(nested_data, "data.frame")
  expect_equal(nrow(nested_data), 2)

  # Check delay calculation
  expect_equal(nested_data$delay_observed, c(4, 5))

  # Check censoring windows
  expect_equal(nested_data$prim_cens_lower, c(0, 0))
  expect_equal(nested_data$prim_cens_upper, c(1, 1))
  expect_equal(nested_data$sec_cens_lower, c(4, 5))
  expect_equal(nested_data$sec_cens_upper, c(5, 6))

  # Check relative observation time for real-time analysis
  # Real-time uses window end (day 60) for truncation
  expect_equal(nested_data$relative_obs_time, c(60, 51))

  # Check that date columns are removed
  expect_false("symptom_onset_date" %in% names(nested_data))
  expect_false("sample_date" %in% names(nested_data))

  # Check that case_id is preserved
  expect_equal(nested_data$case_id, c("case1", "case2"))
})

test_that("transform_ebola_to_delays handles edge cases", {
  # Test with single observation
  test_case_study_row <- data.frame(
    window_id = "window_1",
    analysis_type = "retrospective",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 1
  )

  test_data <- data.frame(
    case_id = "case1",
    symptom_onset_date = as.Date("2014-05-01"),
    sample_date = as.Date("2014-05-01")  # Same day
  )

  test_case_study_row$data <- I(list(test_data))

  result <- transform_ebola_to_delays(test_case_study_row)

  # Check structure
  expect_equal(nrow(result), 1)
  expect_equal(result$n_cases, 1)

  # Extract nested data
  nested_data <- result$data[[1]]

  # Check zero delay
  expect_equal(nested_data$delay_observed, 0)
  expect_equal(nested_data$sec_cens_lower, 0)
  expect_equal(nested_data$sec_cens_upper, 1)

  # Check relative observation time for retrospective analysis
  # Retrospective uses outbreak end (max sample date, no buffer)
  # Sample date: 2014-05-01, so relative obs time: 0 days
  expect_equal(nested_data$relative_obs_time, 0)
})

test_that("transform_ebola_to_delays real-time vs retrospective", {
  # Create identical data for both analysis types
  test_data <- data.frame(
    case_id = c("case1", "case2"),
    symptom_onset_date = as.Date(c("2014-05-01", "2014-05-10")),
    # Second extends beyond window
    sample_date = as.Date(c("2014-05-05", "2014-06-15"))
  )

  # Real-time analysis (window 1: 0-60 days)
  realtime_row <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 2,
    data = I(list(test_data))
  )

  # Retrospective analysis (same window)
  retrospective_row <- data.frame(
    window_id = "window_1",
    analysis_type = "retrospective",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 2,
    data = I(list(test_data))
  )

  realtime_result <- transform_ebola_to_delays(realtime_row)
  retrospective_result <- transform_ebola_to_delays(retrospective_row)

  # Extract nested data
  realtime_data <- realtime_result$data[[1]]
  retrospective_data <- retrospective_result$data[[1]]

  # Check that delays are identical (same source data)
  expect_equal(
    realtime_data$delay_observed,
    retrospective_data$delay_observed
  )

  # Check that relative observation times differ
  # Real-time: truncated at window end (60 days from outbreak start)
  expect_equal(realtime_data$relative_obs_time, c(60, 51))

  # Retrospective: truncated at outbreak end (max sample date)
  # Max sample date: 2014-06-15
  # Relative obs times: 2014-06-15 - c(2014-05-01, 2014-05-10) = c(45, 36)
  expect_equal(retrospective_data$relative_obs_time, c(45, 36))
})

test_that("summarise_ebola_windows creates correct summary statistics", {
  # Create test data with nested structure
  test_data_1 <- data.frame(
    delay_observed = c(3, 5),
    relative_obs_time = c(10, 12)
  )
  test_data_2 <- data.frame(
    delay_observed = c(7, 2),
    relative_obs_time = c(14, 16)
  )
  test_data_3 <- data.frame(
    delay_observed = c(4, 6),
    relative_obs_time = c(20, 22)
  )
  test_data_4 <- data.frame(
    delay_observed = c(8, 10),
    relative_obs_time = c(24, 26)
  )

  test_delay_data <- data.frame(
    window_id = c("window_1", "window_1", "window_2", "window_2"),
    analysis_type = c("real_time", "retrospective",
                      "real_time", "retrospective"),
    window_label = c("0-60 days", "0-60 days", "60-120 days", "60-120 days"),
    n_cases = c(2, 2, 2, 2),
    data = I(list(test_data_1, test_data_2, test_data_3, test_data_4))
  )

  result <- summarise_ebola_windows(test_delay_data)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4)  # 2 windows × 2 analysis types

  # Check columns exist
  expected_cols <- c("window_id", "analysis_type", "window_label",
                     "n_observations",
                     "mean_delay", "median_delay", "sd_delay",
                     "min_delay", "max_delay", "mean_relative_obs_time",
                     "median_relative_obs_time", "sd_relative_obs_time",
                     "min_relative_obs_time", "max_relative_obs_time")
  expect_true(all(expected_cols %in% names(result)))

  # Check specific values for window_1, real_time (rows with delays 3, 5)
  window1_rt <- result[result$window_id == "window_1" &
                         result$analysis_type == "real_time", ]
  expect_equal(window1_rt$n_observations, 2)
  expect_equal(window1_rt$mean_delay, 4)  # Mean of 3 and 5
  expect_equal(window1_rt$median_delay, 4)
  expect_equal(window1_rt$min_delay, 3)
  expect_equal(window1_rt$max_delay, 5)
  expect_equal(window1_rt$mean_relative_obs_time, 11)  # Mean of 10 and 12
})

test_that("summarise_ebola_windows handles single observation per group", {
  test_data <- data.frame(
    delay_observed = 5,
    relative_obs_time = 10
  )

  test_delay_data <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    window_label = "0-60 days",
    n_cases = 1,
    data = I(list(test_data))
  )

  result <- summarise_ebola_windows(test_delay_data)

  expect_equal(nrow(result), 1)
  expect_equal(result$n_observations, 1)
  expect_equal(result$mean_delay, 5)
  expect_equal(result$sd_delay, NA_real_)  # SD of single value is NA
})

test_that("transform_ebola_to_delays handles empty datasets", {
  test_case_study_row <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 0
  )

  # Empty data frame
  empty_data <- data.frame(
    case_id = character(),
    symptom_onset_date = as.Date(character()),
    sample_date = as.Date(character())
  )

  test_case_study_row$data <- I(list(empty_data))

  expect_warning(
    result <- transform_ebola_to_delays(test_case_study_row),
    "Empty data frame provided"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)  # Still returns one row with empty nested data
  expect_equal(result$n_cases, 0)
  expect_equal(nrow(result$data[[1]]), 0)
})

test_that("transform_ebola_to_delays warns about missing dates", {
  test_case_study_row <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    window_label = "0-60 days",
    start_day = 0,
    end_day = 60,
    n_cases = 2
  )

  # Data with missing dates
  test_data <- data.frame(
    case_id = c("case1", "case2"),
    symptom_onset_date = as.Date(c("2014-05-01", NA)),
    sample_date = as.Date(c("2014-05-05", "2014-05-15"))
  )

  test_case_study_row$data <- I(list(test_data))

  expect_warning(
    result <- transform_ebola_to_delays(test_case_study_row),
    "Missing dates found"
  )

  # Should still return one row with nested data
  expect_equal(nrow(result), 1)
  expect_equal(result$n_cases, 2)

  # Check nested data contains both rows, one with NA
  nested_data <- result$data[[1]]
  expect_equal(nrow(nested_data), 2)
  expect_true(is.na(nested_data$delay_observed[2]))
})

test_that("summarise_ebola_windows handles empty datasets", {
  empty_delay_data <- data.frame(
    window_id = character(),
    analysis_type = character(),
    delay_observed = numeric(),
    relative_obs_time = numeric()
  )

  expect_warning(
    result <- summarise_ebola_windows(empty_delay_data),
    "Empty data frame provided"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)

  # Check correct column structure
  expected_cols <- c("window_id", "analysis_type", "n_observations",
                     "mean_delay", "median_delay", "sd_delay",
                     "min_delay", "max_delay", "mean_relative_obs_time")
  expect_true(all(expected_cols %in% names(result)))
})
