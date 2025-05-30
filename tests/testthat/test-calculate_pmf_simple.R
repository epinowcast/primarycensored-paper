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

test_that("calculate_pmf handles edge cases gracefully", {
  # Test with empty scenarios should fail gracefully
  scenarios <- data.frame()
  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "rate",
    param1 = 2,
    param2 = 1,
    stringsAsFactors = FALSE
  )

  expect_error(
    calculate_pmf(scenarios, distributions, 0),
    class = "error"
  )
})

test_that("calculate_pmf function signature is correct", {
  # Test function exists
  expect_true(exists("calculate_pmf"))

  # Test parameter names
  params <- names(formals(calculate_pmf))
  expected_params <- c("scenarios", "distributions", "growth_rate", "method")
  expect_identical(params, expected_params)

  # Test default method parameter
  default_method <- formals(calculate_pmf)$method
  expect_true(is.call(default_method)) # Should be a call to c()
})
