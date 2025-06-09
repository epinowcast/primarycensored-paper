test_that("fit_primarycensored_mle recovers parameters using fitdistrplus", {
  skip_if_not_installed("primarycensored")

  set.seed(131415)
  true_shape <- 1.5
  true_scale <- 2.5
  n <- 100
  d <- 15
  # Generate test data
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = d
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1,
    relative_obs_time = d
  )

  fitting_grid <- data.frame(
    scenario_id = "test_mle_gamma",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  result <- fit_primarycensored_mle(fitting_grid)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "primarycensored_mle")
  expect_gt(result$param1_est, true_shape * 0.7) # Shape parameter recovery
  expect_lt(result$param1_est, true_shape * 1.3)
  expect_gt(result$param2_est, true_scale * 0.7) # Scale parameter recovery
  expect_lt(result$param2_est, true_scale * 1.3)

  # MLE should converge successfully
  expect_true(is.na(result$convergence) || result$convergence == 0)
})

test_that("fit_primarycensored_mle handles lognormal distribution", {
  skip_if_not_installed("primarycensored")

  set.seed(161718)
  n <- 80
  d <- Inf
  meanlog <- 0.5
  sdlog <- 0.7
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rlnorm(n, meanlog = meanlog, sdlog = sdlog),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = d
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1,
    relative_obs_time = d # No truncation for MLE test
  )

  fitting_grid <- data.frame(
    scenario_id = "test_mle_lognormal",
    sample_size = n,
    distribution = "lognormal",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  result <- fit_primarycensored_mle(fitting_grid)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "primarycensored_mle")
  expect_gt(result$param1_est, meanlog * 0.7) # meanlog bounds
  expect_lt(result$param1_est, meanlog * 1.3)
  expect_gt(result$param2_est, sdlog * 0.7) # sdlog bounds
  expect_lt(result$param2_est, sdlog * 1.3)
})
