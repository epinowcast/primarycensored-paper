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

# Distribution Helper Tests ---------------------------------------------------

test_that("distribution helper functions work correctly", {
  skip_if_not_installed("primarycensored")
  
  # Test exponential growth case
  expect_identical(get_primary_dist(0.1), primarycensored::dexpgrowth)
  expect_identical(get_primary_args(0.1), list(r = 0.1))
  expect_identical(get_rprimary(0.1), primarycensored::rexpgrowth)
  expect_identical(get_rprimary_args(0.1), list(r = 0.1))
  
  # Test uniform case
  expect_identical(get_primary_dist(0), dunif)
  expect_identical(get_primary_args(0), list())
  expect_identical(get_rprimary(0), stats::runif)
  expect_identical(get_rprimary_args(0), list())
})

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

test_that("distribution helpers handle negative growth rates", {
  skip_if_not_installed("primarycensored")
  
  growth_rate <- -0.05
  
  primary_dist <- get_primary_dist(growth_rate)
  primary_args <- get_primary_args(growth_rate)
  rprimary <- get_rprimary(growth_rate)
  rprimary_args <- get_rprimary_args(growth_rate)
  
  expect_identical(primary_dist, primarycensored::dexpgrowth)
  expect_identical(primary_args, list(r = -0.05))
  expect_identical(rprimary, primarycensored::rexpgrowth)
  expect_identical(rprimary_args, list(r = -0.05))
  
  test_density <- do.call(primary_dist, c(list(5), primary_args))
  expect_true(is.numeric(test_density))
  expect_true(test_density >= 0)
  
  samples <- do.call(rprimary, c(list(n = 100), rprimary_args))
  expect_true(all(is.finite(samples)))
  expect_true(all(samples >= 0))
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

test_that("format_pmf_results preserves scenario information", {
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
  pmf_values <- pmf_values / sum(pmf_values)
  method <- "numerical"
  runtime <- 2.5
  
  result <- format_pmf_results(scenarios, delays, pmf_values, method, runtime)
  
  scenario_cols <- setdiff(names(scenarios), "scenario_id")
  for (col in scenario_cols) {
    if (col %in% names(result)) {
      expect_true(all(result[[col]] == scenarios[[col]]))
    }
  }
  
  expect_equal(result$delay, delays)
  expect_equal(result$probability, pmf_values)
  expect_equal(sum(result$probability), 1, tolerance = 1e-10)
})

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