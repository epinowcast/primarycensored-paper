# Tests for primarycensored package integration and functionality
# These tests verify individual functions work correctly with primarycensored

# PMF Calculation Tests -------------------------------------------------------

test_that("calculate_pmf produces valid results for gamma distribution", {
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
  skip_if_not_installed("primarycensored")
  
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
  skip_if_not_installed("primarycensored")
  
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
  skip_if_not_installed("primarycensored")
  
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
  
  valid_analytical <- result_analytical$probability[!is.na(result_analytical$probability)]
  valid_numerical <- result_numerical$probability[!is.na(result_numerical$probability)]
  
  expect_true(length(valid_analytical) > 0)
  expect_true(length(valid_numerical) > 0)
  expect_true(all(valid_analytical >= 0))
  expect_true(all(valid_numerical >= 0))
  expect_true(all(valid_analytical <= 1))
  expect_true(all(valid_numerical <= 1))
  
  expect_equal(valid_analytical, valid_numerical, tolerance = 1e-3)
})

test_that("calculate_pmf handles edge case parameter values", {
  skip_if_not_installed("primarycensored")
  
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

# Integration with primarycensored package -------------------------------------

test_that("distribution helpers integrate with primarycensored", {
  skip_if_not_installed("primarycensored")
  
  growth_rate <- 0.1
  primary_dist <- get_primary_dist(growth_rate)
  primary_args <- get_primary_args(growth_rate)
  
  test_value <- do.call(primary_dist, c(list(5), primary_args))
  expect_true(is.numeric(test_value))
  expect_true(test_value >= 0)
  
  direct_value <- primarycensored::dexpgrowth(5, r = 0.1)
  expect_equal(test_value, direct_value)
})

test_that("random generation functions work correctly", {
  skip_if_not_installed("primarycensored")
  
  # Test exponential growth case
  growth_rate <- 0.05
  rprimary <- get_rprimary(growth_rate)
  rprimary_args <- get_rprimary_args(growth_rate)
  
  n_samples <- 1000
  samples <- do.call(rprimary, c(list(n = n_samples), rprimary_args))
  
  expect_length(samples, n_samples)
  expect_true(all(samples >= 0))
  expect_true(all(is.finite(samples)))
  
  # Test uniform case
  rprimary_zero <- get_rprimary(0)
  samples_zero <- rprimary_zero(n_samples, min = 0, max = 10)
  
  expect_length(samples_zero, n_samples)
  expect_true(all(samples_zero >= 0))
  expect_true(all(samples_zero <= 10))
})

# Setup and Formatting Tests -------------------------------------------------

test_that("setup_pmf_inputs creates valid inputs", {
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
  
  inputs <- setup_pmf_inputs(scenarios[1,], distributions, 0.1)
  
  expect_true(all(c("delays", "valid_delays", "args") %in% names(inputs)))
  
  test_pmf <- primarycensored::dprimarycensored(
    inputs$delays[1],
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    pdist = pgamma,
    dprimary = get_primary_dist(0.1),
    dprimary_args = get_primary_args(0.1),
    shape = distributions$param1,
    scale = distributions$param2
  )
  
  expect_true(is.numeric(test_pmf))
  expect_true(test_pmf >= 0)
  expect_true(test_pmf <= 1)
})

# Note: format_pmf_results tests are in test-pmf_tools.R

# Workflow Integration Tests --------------------------------------------------

test_that("complete PMF workflow produces valid results", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = c("gamma_none_daily_r0.05", "lognormal_none_medium_r0.05"),
    distribution = c("gamma", "lognormal"),
    truncation = c("none", "none"),
    censoring = c("daily", "medium"),
    growth_rate = c(0.05, 0.05),
    relative_obs_time = c(10, 15),
    primary_width = c(1, 2),
    secondary_width = c(1, 1),
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = c("gamma", "lognormal"),
    dist_family = c("gamma", "lnorm"),
    param1_name = c("shape", "meanlog"),
    param2_name = c("scale", "sdlog"),
    param1 = c(2, 1.5),
    param2 = c(1, 0.5),
    stringsAsFactors = FALSE
  )
  
  result_list <- list()
  for (i in 1:nrow(scenarios)) {
    result_list[[i]] <- calculate_pmf(
      scenarios[i, ],
      distributions[distributions$dist_name == scenarios$distribution[i], ],
      scenarios$growth_rate[i],
      "analytical"
    )
  }
  
  result <- do.call(rbind, result_list)
  
  expect_s3_class(result, "data.frame")
  expect_true("scenario_id" %in% names(result))
  expect_true("probability" %in% names(result))
  expect_true("delay" %in% names(result))
  
  for (id in unique(result$scenario_id)) {
    scenario_data <- result[result$scenario_id == id, ]
    valid_probs <- scenario_data$probability[!is.na(scenario_data$probability)]
    expect_true(length(valid_probs) > 0)
    expect_true(all(valid_probs >= 0))
    expect_true(all(valid_probs <= 1))
    expect_equal(scenario_data$delay, seq_along(scenario_data$delay) - 1)
  }
})

test_that("workflow handles different truncation scenarios", {
  skip_if_not_installed("primarycensored")
  
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
  
  result_list <- list()
  for (i in 1:nrow(scenarios)) {
    result_list[[i]] <- calculate_pmf(
      scenarios[i, ],
      distributions,
      scenarios$growth_rate[i],
      "analytical"
    )
  }
  
  result <- do.call(rbind, result_list)
  
  finite_result <- result[result$scenario_id == "gamma_finite_daily_r0.1", ]
  infinite_result <- result[result$scenario_id == "gamma_infinite_daily_r0.1", ]
  
  expect_true(nrow(finite_result) > 0)
  expect_true(nrow(infinite_result) > 0)
  
  finite_valid <- finite_result$probability[!is.na(finite_result$probability)]
  infinite_valid <- infinite_result$probability[!is.na(infinite_result$probability)]
  
  expect_true(length(finite_valid) > 0)
  expect_true(length(infinite_valid) > 0)
  expect_true(all(finite_valid >= 0))
  expect_true(all(infinite_valid >= 0))
})

test_that("workflow handles special distribution cases", {
  skip_if_not_installed("primarycensored")
  
  # Zero growth rate
  scenarios_zero <- data.frame(
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
  
  # Negative growth rate
  scenarios_neg <- data.frame(
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
    dist_name = c("gamma", "weibull"),
    dist_family = c("gamma", "weibull"),
    param1_name = c("shape", "shape"),
    param2_name = c("scale", "scale"),
    param1 = c(2, 1.5),
    param2 = c(1, 2),
    stringsAsFactors = FALSE
  )
  
  result_zero <- calculate_pmf(
    scenarios_zero, 
    distributions[distributions$dist_name == "gamma", ], 
    0, 
    "analytical"
  )
  result_neg <- calculate_pmf(
    scenarios_neg, 
    distributions[distributions$dist_name == "weibull", ], 
    -0.05, 
    "analytical"
  )
  
  expect_true(all(result_zero$probability >= 0, na.rm = TRUE))
  expect_true(sum(result_zero$probability, na.rm = TRUE) <= 1)
  expect_true(all(result_neg$probability >= 0, na.rm = TRUE))
  expect_true(sum(result_neg$probability, na.rm = TRUE) <= 1)
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
  
  # Missing required columns
  bad_scenarios <- data.frame(
    scenario_id = "gamma_bad",
    distribution = "gamma"
  )
  
  expect_error(
    calculate_pmf(bad_scenarios, distributions, 0.1, "analytical")
  )
  
  # Unsupported distribution
  unsupported_scenarios <- data.frame(
    scenario_id = "beta_none_daily_r0.1",
    distribution = "beta",
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
  
  result_unsupported <- calculate_pmf(
    unsupported_scenarios, unsupported_dist, 0.1, "analytical"
  )
  
  expect_true(is.data.frame(result_unsupported))
})

# Output Equivalence Tests ----------------------------------------------------

test_that("calculate_pmf matches direct primarycensored::dprimarycensored calls", {
  skip_if_not_installed("primarycensored")
  
  # Test gamma distribution
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
  
  # Get result from local function
  local_result <- calculate_pmf(scenarios, distributions, 0.1, "analytical")
  
  # Calculate directly using primarycensored
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 10]  # swindow = 1, D = 10
  
  direct_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    direct_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 1,
      swindow = 1,
      D = 10,
      pdist = pgamma,
      dprimary = primarycensored::dexpgrowth,
      dprimary_args = list(r = 0.1),
      shape = 2,
      scale = 1
    )
    direct_probs[delays %in% valid_delays] <- direct_values
  }
  
  # Compare results
  expect_equal(local_result$probability, direct_probs, tolerance = 1e-10)
  expect_equal(local_result$delay, delays)
})

test_that("calculate_pmf matches direct calls for lognormal distribution", {
  skip_if_not_installed("primarycensored")
  
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
  
  # Get result from local function
  local_result <- calculate_pmf(scenarios, distributions, 0.05, "analytical")
  
  # Calculate directly using primarycensored
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 15]  # swindow = 1, D = 15
  
  direct_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    direct_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 2,
      swindow = 1,
      D = 15,
      pdist = plnorm,
      dprimary = primarycensored::dexpgrowth,
      dprimary_args = list(r = 0.05),
      meanlog = 1.5,
      sdlog = 0.5
    )
    direct_probs[delays %in% valid_delays] <- direct_values
  }
  
  # Compare results
  expect_equal(local_result$probability, direct_probs, tolerance = 1e-10)
  expect_equal(local_result$delay, delays)
})

test_that("calculate_pmf matches direct calls for zero growth rate", {
  skip_if_not_installed("primarycensored")
  
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
  
  # Get result from local function
  local_result <- calculate_pmf(scenarios, distributions, 0, "analytical")
  
  # Calculate directly using primarycensored with uniform primary
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 10]  # swindow = 1, D = 10
  
  direct_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    direct_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 1,
      swindow = 1,
      D = 10,
      pdist = pgamma,
      dprimary = dunif,
      dprimary_args = list(),
      shape = 3,
      scale = 2
    )
    direct_probs[delays %in% valid_delays] <- direct_values
  }
  
  # Compare results
  expect_equal(local_result$probability, direct_probs, tolerance = 1e-10)
  expect_equal(local_result$delay, delays)
})

test_that("setup_pmf_inputs produces equivalent primarycensored call parameters", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "weibull_none_medium_r0.1",
    distribution = "weibull",
    truncation = "none",
    censoring = "medium",
    growth_rate = 0.1,
    relative_obs_time = 12,
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
  
  # Get inputs from local function
  inputs <- setup_pmf_inputs(scenarios, distributions, 0.1)
  
  # Test that the arguments produce same result as direct call
  test_delay <- 5
  local_value <- do.call(primarycensored::dprimarycensored, 
                        c(list(x = test_delay), inputs$args[-1]))  # Remove x from args
  
  direct_value <- primarycensored::dprimarycensored(
    test_delay,
    pwindow = 2,
    swindow = 1,
    D = 12,
    pdist = pweibull,
    dprimary = primarycensored::dexpgrowth,
    dprimary_args = list(r = 0.1),
    shape = 1.5,
    scale = 2
  )
  
  expect_equal(local_value, direct_value, tolerance = 1e-10)
})

test_that("numerical integration matches primarycensored numerical methods", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "gamma_none_daily_r0.1",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.1,
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
  
  # Get numerical result from local function
  local_numerical <- calculate_pmf(scenarios, distributions, 0.1, "numerical")
  
  # Calculate directly using primarycensored with numerical flag
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 8]  # swindow = 1, D = 8
  
  direct_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    pdist_numerical <- primarycensored::add_name_attribute(pgamma, "pdistnumerical")
    direct_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 1,
      swindow = 1,
      D = 8,
      pdist = pdist_numerical,
      dprimary = primarycensored::dexpgrowth,
      dprimary_args = list(r = 0.1),
      shape = 2,
      scale = 1
    )
    direct_probs[delays %in% valid_delays] <- direct_values
  }
  
  # Compare results - numerical methods may have slightly different precision
  expect_equal(local_numerical$probability, direct_probs, tolerance = 1e-6)
})

test_that("edge case parameters produce equivalent outputs", {
  skip_if_not_installed("primarycensored")
  
  # Very small shape parameter
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
  
  # Get result from local function
  local_result <- calculate_pmf(scenarios, distributions, 0, "analytical")
  
  # Calculate directly using primarycensored
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 5]  # swindow = 1, D = 5
  
  direct_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    direct_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 1,
      swindow = 1,
      D = 5,
      pdist = pgamma,
      dprimary = dunif,
      dprimary_args = list(),
      shape = 0.1,
      scale = 1
    )
    direct_probs[delays %in% valid_delays] <- direct_values
  }
  
  # Compare results
  expect_equal(local_result$probability, direct_probs, tolerance = 1e-10)
  
  # Test negative growth rate
  scenarios_neg <- data.frame(
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
  
  distributions_weibull <- data.frame(
    dist_name = "weibull",
    dist_family = "weibull",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 1.5,
    param2 = 2,
    stringsAsFactors = FALSE
  )
  
  local_neg <- calculate_pmf(scenarios_neg, distributions_weibull, -0.05, "analytical")
  
  delays <- 0:20
  valid_delays <- delays[delays + 1 <= 15]  # swindow = 1, D = 15
  
  direct_neg_probs <- rep(NA_real_, length(delays))
  if (length(valid_delays) > 0) {
    direct_neg_values <- primarycensored::dprimarycensored(
      valid_delays,
      pwindow = 2,
      swindow = 1,
      D = 15,
      pdist = pweibull,
      dprimary = primarycensored::dexpgrowth,
      dprimary_args = list(r = -0.05),
      shape = 1.5,
      scale = 2
    )
    direct_neg_probs[delays %in% valid_delays] <- direct_neg_values
  }
  
  expect_equal(local_neg$probability, direct_neg_probs, tolerance = 1e-10)
})

test_that("multi-scenario workflow maintains equivalence across all scenarios", {
  skip_if_not_installed("primarycensored")
  
  # Test multiple scenarios and distributions
  scenarios <- data.frame(
    scenario_id = c("gamma_none_daily_r0.1", "lognormal_none_medium_r0.05", "weibull_none_wide_r0"),
    distribution = c("gamma", "lognormal", "weibull"),
    truncation = c("none", "none", "none"),
    censoring = c("daily", "medium", "wide"),
    growth_rate = c(0.1, 0.05, 0),
    relative_obs_time = c(10, 15, 20),
    primary_width = c(1, 2, 3),
    secondary_width = c(1, 1, 2),
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = c("gamma", "lognormal", "weibull"),
    dist_family = c("gamma", "lnorm", "weibull"),
    param1_name = c("shape", "meanlog", "shape"),
    param2_name = c("scale", "sdlog", "scale"),
    param1 = c(2, 1.5, 1.8),
    param2 = c(1, 0.5, 2.5),
    stringsAsFactors = FALSE
  )
  
  # Test each scenario individually
  for (i in 1:nrow(scenarios)) {
    scenario <- scenarios[i, ]
    dist_info <- distributions[distributions$dist_name == scenario$distribution, ]
    
    # Get result from local function
    local_result <- calculate_pmf(scenario, dist_info, scenario$growth_rate, "analytical")
    
    # Calculate directly using primarycensored
    delays <- 0:20
    valid_delays <- delays[delays + scenario$secondary_width <= scenario$relative_obs_time]
    
    # Get appropriate distribution and primary functions
    pdist <- get(paste0("p", dist_info$dist_family))
    dprimary <- get_primary_dist(scenario$growth_rate)
    dprimary_args <- get_primary_args(scenario$growth_rate)
    
    direct_probs <- rep(NA_real_, length(delays))
    if (length(valid_delays) > 0) {
      args <- list(
        valid_delays,
        pwindow = scenario$primary_width,
        swindow = scenario$secondary_width,
        D = scenario$relative_obs_time,
        pdist = pdist,
        dprimary = dprimary,
        dprimary_args = dprimary_args
      )
      args[[dist_info$param1_name]] <- dist_info$param1
      args[[dist_info$param2_name]] <- dist_info$param2
      
      direct_values <- do.call(primarycensored::dprimarycensored, args)
      direct_probs[delays %in% valid_delays] <- direct_values
    }
    
    # Compare results for this scenario
    expect_equal(local_result$probability, direct_probs, tolerance = 1e-10,
                 info = paste("Scenario:", scenario$scenario_id))
    expect_equal(local_result$delay, delays,
                 info = paste("Scenario:", scenario$scenario_id))
  }
})