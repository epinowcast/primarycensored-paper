test_that("calculate_pmf produces valid results for gamma distribution", {
  skip_if_not_installed("primarycensored")
  
  # Set up test scenario
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0.1",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.1,
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 2,
    param2 = 1,
    stringsAsFactors = FALSE
  )
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, 0.1, "analytical")
  
  # Basic validity checks
  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))
  
  # Check probabilities are valid
  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf produces valid results for lognormal distribution", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "lognormal_none_medium_r0.05",
    distribution = "lognormal",
    truncation = "none",
    censoring = "medium",
    growth_rate = 0.05,
    relative_obs_time = 15,
    primary_width = 2,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "lognormal",
    dist_family = "lnorm",
    param1_name = "meanlog",
    param2_name = "sdlog",
    param1 = 1.5,
    param2 = 0.5,
    stringsAsFactors = FALSE
  )
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, 0.05, "analytical")
  
  # Basic validity checks
  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))
  
  # Check probabilities are valid
  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf handles zero growth rate correctly", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0,
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 3,
    param2 = 2,
    stringsAsFactors = FALSE
  )
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, 0, "analytical")
  
  # Basic validity checks for zero growth rate
  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))
  
  # Check probabilities are valid
  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf numerical method produces valid results", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0.05",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.05,
    relative_obs_time = 8,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 2,
    param2 = 1,
    stringsAsFactors = FALSE
  )
  
  # Calculate using both methods
  result_analytical <- calculate_pmf(
    scenarios, distributions, 0.05, "analytical"
  )
  result_numerical <- calculate_pmf(
    scenarios, distributions, 0.05, "numerical"
  )
  
  # Both should produce valid results
  valid_analytical <- result_analytical$probability[!is.na(result_analytical$probability)]
  valid_numerical <- result_numerical$probability[!is.na(result_numerical$probability)]
  
  expect_true(length(valid_analytical) > 0)
  expect_true(length(valid_numerical) > 0)
  expect_true(all(valid_analytical >= 0))
  expect_true(all(valid_numerical >= 0))
})

test_that("calculate_pmf distribution helper functions work correctly", {
  skip_if_not_installed("primarycensored")
  
  # Test exponential growth case
  expect_identical(get_primary_dist(0.1), primarycensored::dexpgrowth)
  expect_identical(get_primary_args(0.1), list(r = 0.1))
  expect_identical(get_rprimary(0.1), primarycensored::rexpgrowth)
  expect_identical(get_rprimary_args(0.1), list(r = 0.1))
  
  # Test uniform case
  expect_identical(get_primary_dist(0), dunif)
  expect_identical(get_primary_args(0), list())
  expect_identical(get_rprimary(0), stats::runif)
  expect_identical(get_rprimary_args(0), list())
})

test_that("calculate_pmf handles edge case parameter values", {
  skip_if_not_installed("primarycensored")
  
  # Test with very small shape parameter
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0,
    relative_obs_time = 5,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 0.1,  # Very small shape
    param2 = 1,
    stringsAsFactors = FALSE
  )
  
  result <- calculate_pmf(scenarios, distributions, 0, "analytical")
  
  # Check results are valid (handle NAs appropriately)
  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})