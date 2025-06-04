test_that("fit_ward recovers gamma parameters from censored data", {
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("primarycensored")

  set.seed(101112)
  n <- 50 # Reasonable sample size for Ward method
  true_shape <- 2.5
  true_scale <- 3.0  # Increased to reduce zero probability

  # Generate censored and truncated data using primarycensored
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = 15 # Increased truncation to reduce zero probability
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  fitting_grid <- data.frame(
    scenario_id = "test_ward_gamma",
    sample_size = n,
    distribution = "gamma",
    truncation = "moderate", # 10-day truncation
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 2,
    iter_warmup = 1000,
    iter_sampling = 1000,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_ward(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "ward")

  # Check parameter recovery (Ward should handle censoring and truncation)
  expect_gt(result$param1_est, 0) # Shape should be positive
  expect_gt(result$param2_est, 0) # Scale should be positive

  # Parameter recovery should be within reasonable bounds
  # (±30% for robust method)
  expect_gt(result$param1_est, true_shape * 0.7) # Within 30% for shape
  expect_lt(result$param1_est, true_shape * 1.3)
  expect_gt(result$param2_est, true_scale * 0.7) # Within 30% for scale
  expect_lt(result$param2_est, true_scale * 1.3)

  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_ward recovers lognormal parameters from censored data", {
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("primarycensored")

  set.seed(121314)
  n <- 50 # Reasonable sample size for Ward method
  true_meanlog <- 1.2
  true_sdlog <- 0.8

  # Generate censored and truncated data using primarycensored
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rlnorm(n, meanlog = true_meanlog, sdlog = true_sdlog),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = 15 # 15-day truncation to test Ward's truncation handling
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  fitting_grid <- data.frame(
    scenario_id = "test_ward_lognormal",
    sample_size = n,
    distribution = "lognormal",
    truncation = "moderate", # Truncation scenario
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 2,
    iter_warmup = 1000,
    iter_sampling = 1000,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_ward(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "ward")

  # Check parameter recovery (Ward should handle censoring and truncation)
  expect_gt(result$param2_est, 0) # sdlog should be positive

  # Parameter recovery should be within reasonable bounds
  # Ward method may have higher variance due to latent variable approach
  expect_gt(result$param1_est,
            true_meanlog - 1.2) # Relaxed range for Ward method meanlog
  expect_lt(result$param1_est, true_meanlog + 1.2)
  expect_gt(result$param2_est, true_sdlog * 0.4) # Relaxed range for Ward sdlog
  expect_lt(result$param2_est, true_sdlog * 1.6)

  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_ward handles zero delays correctly", {
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("primarycensored")

  set.seed(151617)
  n <- 50

  # Generate properly censored data using primarycensored
  # Use parameters that naturally generate some zero delays
  delays <- primarycensored::rprimarycensored(
    n = n,
    # Lower scale to get more zeros
    rdist = function(n) rgamma(n, shape = 1.5, scale = 0.5),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = 8  # Lower truncation to increase zero probability
  )

  # Create properly structured censored data
  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  fitting_grid <- data.frame(
    scenario_id = "test_ward_zero_delays",
    sample_size = n,
    distribution = "gamma",
    truncation = "moderate",  # Use moderate truncation for stability
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 1,
    iter_warmup = 500,
    iter_sampling = 500,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_ward(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "ward")

  # Ward method should handle zero delays by inferring latent times
  expect_gt(result$param1_est, 0) # Shape should be positive
  expect_gt(result$param2_est, 0) # Scale should be positive
  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_ward rejects large datasets", {
  # Test that Ward method returns empty results for large datasets
  n <- 1500 # Too large for Ward method

  sampled_data <- data.frame(
    delay_observed = rep(5, n),
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = rep(5, n),
    sec_cens_upper = rep(6, n)
  )

  fitting_grid <- data.frame(
    scenario_id = "test_ward_large",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 1,
    iter_warmup = 100,
    iter_sampling = 100,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_ward(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "ward")

  # Should return empty results (all NA) for large datasets
  expect_true(is.na(result$param1_est))
  expect_true(is.na(result$param2_est))
})
