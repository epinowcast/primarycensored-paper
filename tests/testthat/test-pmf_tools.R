test_that("get_primary_dist returns correct distribution functions", {
  # Test uniform distribution for growth_rate = 0
  expect_identical(get_primary_dist(0), dunif)
  
  # Test exponential growth for non-zero growth_rate
  expect_identical(get_primary_dist(0.1), dexpgrowth)
  expect_identical(get_primary_dist(-0.05), dexpgrowth)
})

test_that("get_primary_args returns correct arguments", {
  # Test uniform distribution arguments
  expect_identical(get_primary_args(0), list())
  
  # Test exponential growth arguments
  expect_identical(get_primary_args(0.1), list(r = 0.1))
  expect_identical(get_primary_args(-0.05), list(r = -0.05))
})

test_that("get_rprimary returns correct random generation functions", {
  # Test uniform random generation for growth_rate = 0
  expect_identical(get_rprimary(0), stats::runif)
  
  # Test exponential growth random generation for non-zero growth_rate
  expect_identical(get_rprimary(0.1), primarycensored::rexpgrowth)
  expect_identical(get_rprimary(-0.05), primarycensored::rexpgrowth)
})

test_that("get_rprimary_args returns correct arguments", {
  # Test uniform distribution arguments
  expect_identical(get_rprimary_args(0), list())
  
  # Test exponential growth arguments
  expect_identical(get_rprimary_args(0.1), list(r = 0.1))
  expect_identical(get_rprimary_args(-0.05), list(r = -0.05))
})

test_that("format_pmf_results creates correct data frame structure", {
  # Create test scenario
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "gamma",
    truncation = "finite",
    censoring = "double",
    growth_rate = 0.1
  )
  
  delays <- 0:5
  pmf_values <- c(0.1, 0.2, 0.3, 0.2, 0.1, 0.1)
  method <- "analytical"
  runtime_seconds <- 1.5
  
  result <- format_pmf_results(scenarios, delays, pmf_values, method, runtime_seconds)
  
  # Check structure
  expect_s3_class(result, "data.frame")
  expect_identical(nrow(result), length(delays))
  expect_identical(ncol(result), 9L)
  
  # Check column names
  expected_cols <- c("scenario_id", "distribution", "truncation", "censoring", 
                     "growth_rate", "method", "delay", "probability", "runtime_seconds")
  expect_identical(names(result), expected_cols)
  
  # Check values
  expect_identical(result$scenario_id, rep(1, 6))
  expect_identical(result$distribution, rep("gamma", 6))
  expect_identical(result$method, rep("analytical", 6))
  expect_identical(result$delay, delays)
  expect_identical(result$probability, pmf_values)
  expect_identical(result$runtime_seconds, rep(1.5, 6))
})