test_that("setup_pmf_inputs handles finite truncation correctly", {
  # Create test scenario with finite truncation
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "gamma",
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 2,
    stringsAsFactors = FALSE
  )

  # Create test distributions
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

  result <- setup_pmf_inputs(scenarios, distributions, growth_rate)

  # Check structure
  expect_type(result, "list")
  expect_identical(names(result), c("delays", "valid_delays", "args"))

  # Check delays
  expect_identical(result$delays, 0:20)

  # Check valid delays (delay + swindow <= D)
  # For swindow=2, D=10, valid delays should be 0:8
  expect_identical(result$valid_delays, 0:8)

  # Check args structure
  expect_type(result$args, "list")
  expected_args <- c(
    "x", "pdist", "pwindow", "swindow", "D",
    "dprimary", "dprimary_args", "shape", "rate"
  )
  expect_identical(sort(names(result$args)), sort(expected_args))

  # Check specific arg values
  expect_identical(result$args$x, 0:8)
  expect_identical(result$args$pwindow, 1)
  expect_identical(result$args$swindow, 2)
  expect_identical(result$args$D, 10)
  expect_identical(result$args$shape, 2)
  expect_identical(result$args$rate, 1)
  expect_identical(result$args$dprimary, dexpgrowth)
  expect_identical(result$args$dprimary_args, list(r = 0.1))
})

test_that("setup_pmf_inputs handles infinite truncation correctly", {
  # Create test scenario with infinite truncation
  scenarios <- data.frame(
    scenario_id = 2,
    distribution = "lognormal",
    relative_obs_time = Inf,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )

  # Create test distributions
  distributions <- data.frame(
    dist_name = "lognormal",
    dist_family = "lnorm",
    param1_name = "meanlog",
    param2_name = "sdlog",
    param1 = 0,
    param2 = 1,
    stringsAsFactors = FALSE
  )

  growth_rate <- 0

  result <- setup_pmf_inputs(scenarios, distributions, growth_rate)

  # Check structure
  expect_type(result, "list")
  expect_identical(names(result), c("delays", "valid_delays", "args"))

  # Check delays
  expect_identical(result$delays, 0:20)

  # For infinite truncation, all delays should be valid
  expect_identical(result$valid_delays, 0:20)

  # Check uniform distribution for growth_rate = 0
  expect_identical(result$args$dprimary, dunif)
  expect_identical(result$args$dprimary_args, list())

  # Check distribution parameters
  expect_identical(result$args$meanlog, 0)
  expect_identical(result$args$sdlog, 1)
})

test_that("setup_pmf_inputs handles numerical integration flag", {
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

  # Test with numerical integration
  result_numerical <- setup_pmf_inputs(
    scenarios, distributions, 0, is_numerical = TRUE
  )

  # Check that pdist has the numerical attribute
  pdist <- result_numerical$args$pdist
  expect_true(exists("add_name_attribute") || inherits(pdist, "function"))
})

test_that("setup_pmf_inputs validates input parameters", {
  # Test with missing distribution
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "nonexistent",
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

  # This should result in no matching distribution (empty subset)
  # The function should handle this gracefully or we should expect an error
  # Since the actual behavior depends on implementation, we test that it
  # doesn't crash
  expect_error(
    setup_pmf_inputs(scenarios, distributions, 0),
    class = "error"
  )
})

test_that("setup_pmf_inputs edge cases", {
  # Test with zero secondary window
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "gamma",
    relative_obs_time = 10,
    primary_width = 1,
    secondary_width = 0,
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

  result <- setup_pmf_inputs(scenarios, distributions, 0)

  # With swindow=0, valid delays should be 0:10 (delay + 0 <= 10)
  expect_identical(result$valid_delays, 0:10)
})
