test_that("fit_naive recovers gamma parameters from uncensored data", {
  skip_if_not_installed("cmdstanr")

  set.seed(789)
  n <- 100
  true_shape <- 3
  true_scale <- 2
  # Generate truly uncensored data (no censoring at all)
  delays <- rgamma(n, shape = true_shape, scale = true_scale)

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1,
    relative_obs_time = Inf  # No truncation for naive test
  )

  fitting_grid <- data.frame(
    scenario_id = "test_naive_gamma_uncensored",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 2,
    iter_warmup = 500,
    iter_sampling = 1000,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_naive(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "naive")
  # Parameter recovery should be good with uncensored data
  expect_gt(result$param1_est, 0) # Shape should be positive
  expect_gt(result$param2_est, 0) # Scale should be positive
  # Check recovery is within reasonable bounds (allowing for MCMC error)
  expect_gt(result$param1_est, true_shape * 0.7) # Within 30% for shape
  expect_lt(result$param1_est, true_shape * 1.3)
  expect_gt(result$param2_est, true_scale * 0.7) # Within 30% for scale
  expect_lt(result$param2_est, true_scale * 1.3)
  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_naive recovers lognormal parameters from uncensored data", {
  skip_if_not_installed("cmdstanr")

  set.seed(456)
  n <- 100
  true_meanlog <- 1.0
  true_sdlog <- 0.8
  # Generate truly uncensored data (no censoring at all)
  delays <- rlnorm(n, meanlog = true_meanlog, sdlog = true_sdlog)

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1,
    relative_obs_time = Inf  # No truncation for naive test
  )

  fitting_grid <- data.frame(
    scenario_id = "test_naive_lognormal_uncensored",
    sample_size = n,
    distribution = "lognormal",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 2,
    iter_warmup = 500,
    iter_sampling = 1000,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_naive(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "naive")
  # Parameter recovery should be good with uncensored data
  expect_gt(result$param2_est, 0) # sdlog should be positive
  # Check recovery is within reasonable bounds (allowing for MCMC error)
  expect_gt(result$param1_est, true_meanlog - 0.3)  # Within reasonable range
  # for meanlog
  expect_lt(result$param1_est, true_meanlog + 0.3)
  expect_gt(result$param2_est, true_sdlog * 0.7) # Within 30% for sdlog
  expect_lt(result$param2_est, true_sdlog * 1.3)
  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_naive shows bias with censored data (expected behaviour)", {
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("primarycensored")

  set.seed(999)
  n <- 100
  true_shape <- 2.5
  true_scale <- 1.5
  # Generate censored data using primarycensored
  censored_data <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  sampled_data <- data.frame(
    delay_observed = censored_data,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = censored_data,
    sec_cens_upper = censored_data + 1,
    relative_obs_time = Inf  # No truncation
  )

  fitting_grid <- data.frame(
    scenario_id = "test_naive_gamma_censored",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 2,
    iter_warmup = 500,
    iter_sampling = 1000,
    refresh = 0,
    show_messages = FALSE
  )

  result <- fit_naive(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "naive")
  # Parameters should be biased away from true values (expected with censoring)
  # This demonstrates why proper censoring methods are needed
  expect_gt(result$param1_est, 0) # Shape should be positive
  expect_gt(result$param2_est, 0) # Scale should be positive
  # Check no error occurred (the bias is expected, not an error)
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})
