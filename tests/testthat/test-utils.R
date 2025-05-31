test_that("save_plot function parameters are correct", {
  # Test function exists and has correct parameters
  expect_true(exists("save_plot"))
  expect_length(formals(save_plot), 5)
  expect_identical(names(formals(save_plot)), c("plot", "filename", "width", "height", "dpi"))
  
  # Test default parameter values
  defaults <- formals(save_plot)
  expect_identical(defaults$width, 8)
  expect_identical(defaults$height, 6)
  expect_identical(defaults$dpi, 300)
})

test_that("save_data function parameters are correct", {
  # Test function exists and has correct parameters
  expect_true(exists("save_data"))
  expect_length(formals(save_data), 2)
  expect_identical(names(formals(save_data)), c("data", "filename"))
})

test_that("estimate_naive_delay_model validates distribution parameter", {
  # Create test data
  data <- data.frame(delay_observed = c(1, 2, 3, 4, 5))
  
  # Test valid distributions
  result_gamma <- estimate_naive_delay_model(data, "gamma", 1, 100)
  expect_s3_class(result_gamma, "data.frame")
  expect_identical(result_gamma$distribution, "gamma")
  
  result_lognormal <- estimate_naive_delay_model(data, "lognormal", 1, 100)
  expect_s3_class(result_lognormal, "data.frame")
  expect_identical(result_lognormal$distribution, "lognormal")
  
  # Test invalid distribution
  expect_error(
    estimate_naive_delay_model(data, "normal", 1, 100),
    "'arg' should be one of"
  )
})

test_that("estimate_naive_delay_model returns correct structure", {
  # Create test data
  data <- data.frame(delay_observed = c(1, 2, 3, 4, 5))
  
  result <- estimate_naive_delay_model(data, "gamma", 1, 100)
  
  # Check structure
  expect_s3_class(result, "data.frame")
  expect_identical(nrow(result), 1L)
  expect_identical(ncol(result), 9L)
  
  # Check column names
  expected_cols <- c("scenario_id", "sample_size", "model", "distribution",
                     "mean_est", "sd_est", "param1_est", "param2_est", "runtime_seconds")
  expect_identical(names(result), expected_cols)
  
  # Check specific values
  expect_identical(result$scenario_id, 1)
  expect_identical(result$sample_size, 100)
  expect_identical(result$model, "naive")
  expect_identical(result$distribution, "gamma")
  expect_identical(result$mean_est, mean(data$delay_observed))
  expect_identical(result$sd_est, sd(data$delay_observed))
})

test_that("estimate_naive_delay_model handles edge cases", {
  # Test with single observation
  data_single <- data.frame(delay_observed = 5)
  result_single <- estimate_naive_delay_model(data_single, "gamma", 1, 1)
  expect_s3_class(result_single, "data.frame")
  expect_identical(result_single$mean_est, 5)
  expect_true(is.na(result_single$sd_est)) # sd of single value is NA
  
  # Test with different parameters
  data <- data.frame(delay_observed = c(1, 2, 3))
  result <- estimate_naive_delay_model(data, "lognormal", 99, 500, seed = 456, chains = 4)
  expect_identical(result$scenario_id, 99)
  expect_identical(result$sample_size, 500)
  expect_identical(result$distribution, "lognormal")
})