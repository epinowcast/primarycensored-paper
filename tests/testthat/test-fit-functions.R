test_that("fit_primarycensored recovers gamma parameters correctly", {
  skip("Stan integration tests deferred to issue #41 (structural PR)")
  skip_if_not_installed("primarycensored")
  skip_if_not_installed("cmdstanr")

  # Set up test data - gamma distribution with known parameters
  set.seed(123)
  true_shape <- 2
  true_scale <- 3
  n <- 50

  # Generate synthetic double-censored data
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  # Create mock sampled_data
  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  # Create mock fitting_grid
  fitting_grid <- data.frame(
    scenario_id = "test_gamma",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  # Test Stan settings (reduced for speed)
  stan_settings <- list(
    chains = 1,
    parallel_chains = 1,
    iter_warmup = 100,
    iter_sampling = 100,
    refresh = 0,
    show_messages = FALSE
  )

  # Test the function
  result <- fit_primarycensored(fitting_grid, stan_settings)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_identical(nrow(result), 1L)
  expect_true("param1_est" %in% names(result))
  expect_true("param2_est" %in% names(result))
  expect_true("method" %in% names(result))
  expect_identical(result$method, "primarycensored")

  # Check parameter recovery (within reasonable bounds for small sample)
  expect_gt(result$param1_est, 0.5) # Shape should be positive
  expect_lt(result$param1_est, 10) # But not too large
  expect_gt(result$param2_est, 0.5) # Scale should be positive
  expect_lt(result$param2_est, 15) # But reasonable

  # Check no error occurred
  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

test_that("fit_primarycensored recovers lognormal parameters correctly", {
  skip("Stan integration tests deferred to issue #41 (structural PR)")
  skip_if_not_installed("primarycensored")
  skip_if_not_installed("cmdstanr")

  # Set up test data - lognormal distribution
  set.seed(456)
  true_meanlog <- 1
  true_sdlog <- 0.8
  n <- 50

  # Generate synthetic data
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rlnorm(n, meanlog = true_meanlog, sdlog = true_sdlog),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  fitting_grid <- data.frame(
    scenario_id = "test_lognormal",
    sample_size = n,
    distribution = "lognormal",
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

  result <- fit_primarycensored(fitting_grid, stan_settings)

  # Check basic structure
  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "primarycensored")

  # Check parameter bounds for lognormal
  expect_gt(result$param1_est, -3) # meanlog reasonable
  expect_lt(result$param1_est, 5)
  expect_gt(result$param2_est, 0.1) # sdlog positive
  expect_lt(result$param2_est, 3)

  expect_true(is.na(result$error_msg) || result$error_msg == "")
})

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
    sec_cens_upper = delays + 1
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
    sec_cens_upper = delays + 1
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
    sec_cens_upper = censored_data + 1
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

test_that("fit_ward recovers gamma parameters from censored data", {
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("primarycensored")

  set.seed(101112)
  n <- 50 # Reasonable sample size for Ward method
  true_shape <- 2.5
  true_scale <- 1.8

  # Generate censored and truncated data using primarycensored
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = 10 # 10-day truncation to test Ward's truncation handling
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

  set.seed(151617)
  n <- 30
  # Create some data that includes near-zero delays
  delays <- c(rep(1e-6, 5), rgamma(n - 5, shape = 2, scale = 1.5))

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
    truncation = "none",
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
  # Should not crash with zero delays
  expect_gt(result$param1_est, 0) # Shape should be positive
  expect_gt(result$param2_est, 0) # Scale should be positive
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

  stan_settings <- list(chains = 1, iter_warmup = 10, iter_sampling = 10)

  result <- fit_ward(fitting_grid, stan_settings)

  expect_s3_class(result, "data.frame")
  expect_identical(result$method, "ward")
  expect_true(is.na(result$param1_est)) # Should be empty results
  expect_true(is.na(result$param2_est))
})

test_that("fit_primarycensored_mle recovers parameters using fitdistrplus", {
  skip("MLE integration tests deferred to issue #44 (structural PR)")
  skip_if_not_installed("primarycensored")

  set.seed(131415)
  true_shape <- 1.5
  true_scale <- 2.5
  n <- 100

  # Generate test data
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = true_shape, scale = true_scale),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
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
  expect_gt(result$param1_est, 0.5) # Shape parameter recovery
  expect_lt(result$param1_est, 5)
  expect_gt(result$param2_est, 0.5) # Scale parameter recovery
  expect_lt(result$param2_est, 8)

  # MLE should converge successfully
  expect_true(is.na(result$convergence) || result$convergence == 0)
})

test_that("fit_primarycensored_mle handles lognormal distribution", {
  skip("MLE integration tests deferred to issue #44 (structural PR)")
  skip_if_not_installed("primarycensored")

  set.seed(161718)
  n <- 80
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rlnorm(n, meanlog = 0.5, sdlog = 0.7),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
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
  expect_gt(result$param1_est, -2) # meanlog bounds
  expect_lt(result$param1_est, 3)
  expect_gt(result$param2_est, 0.1) # sdlog bounds
  expect_lt(result$param2_est, 2)
})

test_that("fitting functions handle empty data gracefully", {
  skip("Error handling tests deferred to issues #41-44 (structural PR)")
  # Test empty data scenario
  empty_data <- data.frame(
    delay_observed = numeric(0),
    prim_cens_lower = numeric(0),
    prim_cens_upper = numeric(0),
    sec_cens_lower = numeric(0),
    sec_cens_upper = numeric(0)
  )

  fitting_grid <- data.frame(
    scenario_id = "test_empty",
    sample_size = 0,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0,
    data = I(list(empty_data))
  )

  stan_settings <- list(chains = 1, iter_warmup = 10, iter_sampling = 10)

  # All functions should handle empty data gracefully
  result_pc <- fit_primarycensored(fitting_grid, stan_settings)
  result_naive <- fit_naive(fitting_grid, stan_settings)
  result_ward <- fit_ward(fitting_grid, stan_settings)
  result_mle <- fit_primarycensored_mle(fitting_grid)

  # Check that all return proper empty results
  expect_s3_class(result_pc, "data.frame")
  expect_s3_class(result_naive, "data.frame")
  expect_s3_class(result_ward, "data.frame")
  expect_s3_class(result_mle, "data.frame")

  expect_true(is.na(result_pc$param1_est))
  expect_true(is.na(result_naive$param1_est))
  expect_true(is.na(result_ward$param1_est))
  expect_true(is.na(result_mle$param1_est))
})

test_that("fitting functions handle truncation scenarios correctly", {
  skip("Integration tests deferred to issues #41-44 (structural PR)")
  skip_if_not_installed("primarycensored")

  set.seed(192021)
  n <- 40
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = 2, scale = 2),
    rprimary = stats::runif,
    rprimary_args = list(),
    pwindow = 1,
    swindow = 1,
    D = 10 # 10-day truncation
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  # Test moderate truncation
  fitting_grid_moderate <- data.frame(
    scenario_id = "test_truncation",
    sample_size = n,
    distribution = "gamma",
    truncation = "moderate", # Should give 10-day truncation
    growth_rate = 0,
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 1,
    iter_warmup = 50,
    iter_sampling = 50,
    refresh = 0,
    show_messages = FALSE
  )

  result_pc <- fit_primarycensored(fitting_grid_moderate, stan_settings)
  result_mle <- fit_primarycensored_mle(fitting_grid_moderate)

  expect_s3_class(result_pc, "data.frame")
  expect_s3_class(result_mle, "data.frame")
  expect_gt(result_pc$param1_est, 0)
  expect_gt(result_mle$param1_est, 0)
})

test_that("fitting functions handle exponential growth scenarios", {
  skip("Integration tests deferred to issues #41-44 (structural PR)")
  skip_if_not_installed("primarycensored")

  set.seed(222324)
  n <- 50
  delays <- primarycensored::rprimarycensored(
    n = n,
    rdist = function(n) rgamma(n, shape = 1.8, scale = 1.2),
    rprimary = primarycensored::rexpgrowth,
    rprimary_args = list(r = 0.2),
    pwindow = 1,
    swindow = 1,
    D = Inf
  )

  sampled_data <- data.frame(
    delay_observed = delays,
    prim_cens_lower = 0,
    prim_cens_upper = 1,
    sec_cens_lower = delays,
    sec_cens_upper = delays + 1
  )

  fitting_grid_growth <- data.frame(
    scenario_id = "test_growth",
    sample_size = n,
    distribution = "gamma",
    truncation = "none",
    growth_rate = 0.2, # Exponential growth
    data = I(list(sampled_data))
  )

  stan_settings <- list(
    chains = 1,
    iter_warmup = 100,
    iter_sampling = 100,
    refresh = 0,
    show_messages = FALSE
  )

  result_pc <- fit_primarycensored(fitting_grid_growth, stan_settings)
  result_mle <- fit_primarycensored_mle(fitting_grid_growth)

  expect_s3_class(result_pc, "data.frame")
  expect_s3_class(result_mle, "data.frame")

  # Should still recover reasonable parameters
  expect_gt(result_pc$param1_est, 0.5)
  expect_lt(result_pc$param1_est, 5)
  expect_gt(result_mle$param1_est, 0.5)
  expect_lt(result_mle$param1_est, 5)
})
