test_that("distribution helpers integrate correctly with primarycensored", {
  skip_if_not_installed("primarycensored")
  
  # Test that our helper functions produce the right inputs for primarycensored
  growth_rate <- 0.1
  
  # Get primary distribution function and args
  primary_dist <- get_primary_dist(growth_rate)
  primary_args <- get_primary_args(growth_rate)
  
  # Verify these work with primarycensored
  test_value <- do.call(primary_dist, c(list(5), primary_args))
  expect_true(is.numeric(test_value))
  expect_true(test_value >= 0)
  
  # Compare with direct call
  direct_value <- primarycensored::dexpgrowth(5, r = 0.1)
  expect_equal(test_value, direct_value)
})

test_that("get_rprimary functions generate valid samples", {
  skip_if_not_installed("primarycensored")
  
  # Test exponential growth case
  growth_rate <- 0.05
  rprimary <- get_rprimary(growth_rate)
  rprimary_args <- get_rprimary_args(growth_rate)
  
  # Generate samples
  n_samples <- 1000
  samples <- do.call(rprimary, c(list(n = n_samples), rprimary_args))
  
  expect_length(samples, n_samples)
  expect_true(all(samples >= 0))
  expect_true(all(is.finite(samples)))
  
  # Test uniform case (growth_rate = 0)
  rprimary_zero <- get_rprimary(0)
  rprimary_args_zero <- get_rprimary_args(0)
  
  # For uniform, we need min and max
  samples_zero <- rprimary_zero(n_samples, min = 0, max = 10)
  
  expect_length(samples_zero, n_samples)
  expect_true(all(samples_zero >= 0))
  expect_true(all(samples_zero <= 10))
})

test_that("setup_pmf_inputs creates valid inputs for dprimarycensored", {
  skip_if_not_installed("primarycensored")
  
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
  
  growth_rate <- 0.1
  
  # Get inputs
  inputs <- setup_pmf_inputs(scenarios[1,], distributions, growth_rate)
  
  # Verify all required fields are present
  expect_true(all(c("delays", "valid_delays", "args") %in% names(inputs)))
  
  # Test that these inputs work with dprimarycensored
  test_pmf <- primarycensored::dprimarycensored(
    inputs$delays[1],
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    pdist = pgamma,
    dprimary = get_primary_dist(growth_rate),
    dprimary_args = get_primary_args(growth_rate),
    shape = distributions$param1,
    scale = distributions$param2
  )
  
  expect_true(is.numeric(test_pmf))
  expect_true(test_pmf >= 0)
  expect_true(test_pmf <= 1)
})

test_that("distribution helpers handle negative growth rates", {
  skip_if_not_installed("primarycensored")
  
  # Negative growth rate (declining epidemic)
  growth_rate <- -0.05
  
  primary_dist <- get_primary_dist(growth_rate)
  primary_args <- get_primary_args(growth_rate)
  rprimary <- get_rprimary(growth_rate)
  rprimary_args <- get_rprimary_args(growth_rate)
  
  # Check functions are correct
  expect_identical(primary_dist, dexpgrowth)
  expect_identical(primary_args, list(r = -0.05))
  expect_identical(rprimary, primarycensored::rexpgrowth)
  expect_identical(rprimary_args, list(r = -0.05))
  
  # Test that negative growth rate works
  test_density <- do.call(primary_dist, c(list(5), primary_args))
  expect_true(is.numeric(test_density))
  expect_true(test_density >= 0)
  
  # Generate samples
  samples <- do.call(rprimary, c(list(n = 100), rprimary_args))
  expect_true(all(is.finite(samples)))
  expect_true(all(samples >= 0))
})

test_that("format_pmf_results preserves all scenario information", {
  # Create complex scenario
  scenarios <- data.frame(
    scenario_id = 1,
    distribution = "weibull",
    truncation = "finite",
    censoring = "primary",
    growth_rate = 0.02,
    relative_obs_time = 20,
    primary_width = 2,
    secondary_width = 1,
    custom_field = "test_value",
    stringsAsFactors = FALSE
  )
  
  delays <- 0:10
  pmf_values <- dnorm(delays, mean = 5, sd = 2)
  pmf_values <- pmf_values / sum(pmf_values)  # Normalize
  method <- "numerical"
  runtime <- 2.5
  
  result <- format_pmf_results(scenarios, delays, pmf_values, method, runtime)
  
  # Check all scenario columns are preserved
  scenario_cols <- setdiff(names(scenarios), "scenario_id")
  for (col in scenario_cols) {
    if (col %in% names(result)) {
      expect_true(all(result[[col]] == scenarios[[col]]))
    }
  }
  
  # Check PMF values
  expect_equal(result$delay, delays)
  expect_equal(result$probability, pmf_values)
  expect_equal(sum(result$probability), 1, tolerance = 1e-10)
})