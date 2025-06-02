test_that("complete PMF workflow produces valid results", {
  skip_if_not_installed("primarycensored")
  
  # Create a complete scenario setup
  scenarios <- data.frame(
    scenario_id = c("gamma_none_daily_r0.05", "lognormal_none_medium_r0.05", "weibull_none_weekly_r0.05"),
    distribution = c("gamma", "lognormal", "weibull"),
    truncation = c("none", "none", "none"),
    censoring = c("daily", "medium", "weekly"),
    growth_rate = c(0.05, 0.05, 0.05),
    relative_obs_time = c(10, 15, 20),
    primary_width = c(1, 2, 1),
    secondary_width = c(1, 1, 2),
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = c("gamma", "lognormal", "weibull"),
    dist_family = c("gamma", "lnorm", "weibull"),
    param1_name = c("shape", "meanlog", "shape"),
    param2_name = c("scale", "sdlog", "scale"),
    param1 = c(2, 1.5, 2.5),
    param2 = c(1, 0.5, 3),
    stringsAsFactors = FALSE
  )
  
  growth_rate <- 0.05
  
  # Run complete workflow
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Verify results structure
  expect_s3_class(result, "data.frame")
  expect_true("scenario_id" %in% names(result))
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))
  
  # Check each scenario has valid PMF
  for (id in unique(result$scenario_id)) {
    scenario_data <- result[result$scenario_id == id, ]
    
    # PMF properties
    expect_true(all(scenario_data$probability >= 0))
    expect_true(all(scenario_data$probability <= 1))
    expect_true(sum(scenario_data$probability) <= 1)
    
    # Check delays are sequential
    expect_equal(scenario_data$delay, seq_along(scenario_data$delay) - 1)
  }
})

test_that("workflow handles different truncation scenarios correctly", {
  skip_if_not_installed("primarycensored")
  
  # Test finite vs infinite truncation
  scenarios <- data.frame(
    scenario_id = c("gamma_finite_daily_r0.1", "gamma_infinite_daily_r0.1"),
    distribution = "gamma",
    truncation = c("finite", "infinite"),
    censoring = c("daily", "daily"),
    growth_rate = c(0.1, 0.1),
    relative_obs_time = c(10, Inf),
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
  
  growth_rate <- 0.1
  
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Separate results by truncation
  finite_result <- result[result$scenario_id == 1, ]
  infinite_result <- result[result$scenario_id == 2, ]
  
  # Finite truncation should have delays up to relative_obs_time
  expect_true(max(finite_result$delay) <= scenarios$relative_obs_time[1])
  
  # Both should have valid PMFs
  expect_true(sum(finite_result$probability) <= 1)
  expect_true(sum(infinite_result$probability) <= 1)
})

test_that("workflow performance scales with problem size", {
  skip_if_not_installed("primarycensored")
  
  # Small problem
  scenarios_small <- data.frame(
    scenario_id = "gamma_none_daily_r0.05",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.05,
    relative_obs_time = 5,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  # Large problem
  scenarios_large <- data.frame(
    scenario_id = "gamma_none_daily_r0.05",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.05,
    relative_obs_time = 50,
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
  
  growth_rate <- 0.05
  
  # Time both
  time_small <- system.time({
    result_small <- calculate_pmf(
      scenarios_small, distributions, growth_rate, "analytical"
    )
  })["elapsed"]
  
  time_large <- system.time({
    result_large <- calculate_pmf(
      scenarios_large, distributions, growth_rate, "analytical"
    )
  })["elapsed"]
  
  # Runtime should be recorded
  expect_true(all(result_small$runtime_seconds > 0))
  expect_true(all(result_large$runtime_seconds > 0))
  
  # Both should produce valid results
  expect_true(all(result_small$probability >= 0))
  expect_true(all(result_large$probability >= 0))
})

test_that("workflow handles gamma distribution with zero growth", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0,
    relative_obs_time = 15,
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
  
  result <- calculate_pmf(scenarios, distributions, 0, "analytical")
  
  # Check valid PMF
  expect_true(all(result$probability >= 0, na.rm = TRUE))
  expect_true(sum(result$probability, na.rm = TRUE) <= 1)
})

test_that("workflow handles weibull distribution with negative growth", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "weibull_none_medium_r-0.05",
    distribution = "weibull",
    truncation = "none",
    censoring = "medium",
    growth_rate = -0.05,
    relative_obs_time = 15,
    primary_width = 2,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "weibull",
    dist_family = "weibull",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 1.5,
    param2 = 2,
    stringsAsFactors = FALSE
  )
  
  result <- calculate_pmf(scenarios, distributions, -0.05, "analytical")
  
  # Check valid PMF
  expect_true(all(result$probability >= 0, na.rm = TRUE))
  expect_true(sum(result$probability, na.rm = TRUE) <= 1)
})

test_that("workflow error handling for invalid inputs", {
  skip_if_not_installed("primarycensored")
  
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "rate",
    param1 = 2,
    param2 = 1,
    stringsAsFactors = FALSE
  )
  
  # Test with missing required columns
  bad_scenarios <- data.frame(
    scenario_id = "gamma_bad",
    distribution = "gamma"
    # Missing relative_obs_time, primary_width, secondary_width
  )
  
  expect_error(
    calculate_pmf(bad_scenarios, distributions, 0.1, "analytical")
  )
  
  # Test with unsupported distribution
  unsupported_scenarios <- data.frame(
    scenario_id = "beta_none_daily_r0.1",
    distribution = "beta",  # Not supported
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.1,
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  unsupported_dist <- data.frame(
    dist_name = "beta",
    dist_family = "beta",
    param1_name = "shape1",
    param2_name = "shape2",
    param1 = 2,
    param2 = 2,
    stringsAsFactors = FALSE
  )
  
  expect_error(
    calculate_pmf(unsupported_scenarios, unsupported_dist, 0.1, "analytical"),
    class = "error"
  )
})