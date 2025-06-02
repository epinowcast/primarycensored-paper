test_that("calculate_pmf validates method parameter", {
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "gamma",
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )

  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "rate",
    param1 = 2,
    param2 = 1,
    stringsAsFactors = FALSE
  )

  growth_rate <- 0.1

  # Test invalid method
  expect_error(
    calculate_pmf(scenarios, distributions, growth_rate, "invalid"),
    "'arg' should be one of"
  )

  # Test that function exists and accepts valid method arguments
  expect_true(exists("calculate_pmf"))
  expect_true("analytical" %in% eval(formals(calculate_pmf)$method))
  expect_true("numerical" %in% eval(formals(calculate_pmf)$method))
})

test_that("calculate_pmf produces valid results for gamma distribution", {

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

  result <- calculate_pmf(scenarios, distributions, 0.1, "analytical")

  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))

  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf produces valid results for lognormal distribution", {

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

  result <- calculate_pmf(scenarios, distributions, 0.05, "analytical")

  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))

  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf handles zero growth rate correctly", {

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

  result <- calculate_pmf(scenarios, distributions, 0, "analytical")

  expect_s3_class(result, "data.frame")
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))

  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(length(valid_probs) > 0)
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

test_that("calculate_pmf numerical vs analytical methods", {

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

  result_analytical <- calculate_pmf(
    scenarios, distributions, 0.05, "analytical"
  )
  result_numerical <- calculate_pmf(
    scenarios, distributions, 0.05, "numerical"
  )

  valid_analytical <- result_analytical$probability[
    !is.na(result_analytical$probability)
  ]
  valid_numerical <- result_numerical$probability[
    !is.na(result_numerical$probability)
  ]

  expect_true(length(valid_analytical) > 0)
  expect_true(length(valid_numerical) > 0)
  expect_true(all(valid_analytical >= 0))
  expect_true(all(valid_numerical >= 0))
  expect_true(all(valid_analytical <= 1))
  expect_true(all(valid_numerical <= 1))

  expect_equal(valid_analytical, valid_numerical, tolerance = 1e-3)
})

test_that("calculate_pmf handles edge case parameter values", {

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

  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})

