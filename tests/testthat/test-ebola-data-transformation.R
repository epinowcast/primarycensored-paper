test_that("transform_ebola_to_delays correctly converts dates to numeric delays", {
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
  
  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  
  # Check delay calculation
  expect_equal(result$delay_observed, c(4, 5))
  
  # Check censoring windows
  expect_equal(result$prim_cens_lower, c(0, 0))
  expect_equal(result$prim_cens_upper, c(1, 1))
  expect_equal(result$sec_cens_lower, c(4, 5))
  expect_equal(result$sec_cens_upper, c(5, 6))
  
  # Check relative observation time
  # Window ends at day 60, so 60 days after 2014-05-01
  expect_equal(result$relative_obs_time, c(60, 51))
  
  # Check that date columns are removed
  expect_false("symptom_onset_date" %in% names(result))
  expect_false("sample_date" %in% names(result))
  
  # Check that case_id is preserved
  expect_equal(result$case_id, c("case1", "case2"))
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
  
  # Check zero delay
  expect_equal(result$delay_observed, 0)
  expect_equal(result$sec_cens_lower, 0)
  expect_equal(result$sec_cens_upper, 1)
})

test_that("summarise_ebola_windows creates correct summary statistics", {
  # Create test delay data with clearer grouping
  test_delay_data <- data.frame(
    window_id = c("window_1", "window_1", "window_1", "window_1", 
                  "window_2", "window_2", "window_2", "window_2"),
    analysis_type = c("real_time", "real_time", "retrospective", "retrospective",
                     "real_time", "real_time", "retrospective", "retrospective"),
    delay_observed = c(3, 5, 7, 2, 4, 6, 8, 10),
    relative_obs_time = c(10, 12, 14, 16, 20, 22, 24, 26)
  )
  
  result <- summarise_ebola_windows(test_delay_data)
  
  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4)  # 2 windows × 2 analysis types
  
  # Check columns exist
  expected_cols <- c("window_id", "analysis_type", "n_observations", 
                    "mean_delay", "median_delay", "sd_delay", 
                    "min_delay", "max_delay", "mean_relative_obs_time")
  expect_true(all(expected_cols %in% names(result)))
  
  # Check specific values for window_1, real_time (rows with delays 3, 5)
  window1_rt <- result[result$window_id == "window_1" & 
                      result$analysis_type == "real_time", ]
  expect_equal(window1_rt$n_observations, 2)
  expect_equal(window1_rt$mean_delay, 4)  # (3 + 5) / 2
  expect_equal(window1_rt$median_delay, 4)
  expect_equal(window1_rt$min_delay, 3)
  expect_equal(window1_rt$max_delay, 5)
})

test_that("summarise_ebola_windows handles single observation per group", {
  test_delay_data <- data.frame(
    window_id = "window_1",
    analysis_type = "real_time",
    delay_observed = 5,
    relative_obs_time = 10
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
  expect_equal(nrow(result), 0)
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
  
  # Should still return results for valid data
  expect_equal(nrow(result), 2)
  expect_true(is.na(result$delay_observed[2]))
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