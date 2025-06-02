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

  valid_analytical <- result_analytical$probability[
    !is.na(result_analytical$probability)
  ]
  valid_numerical <- result_numerical$probability[
    !is.na(result_numerical$probability)
  ]

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


# Setup and Formatting Tests -------------------------------------------------

# Note: setup_pmf_inputs tests are in test-pmf_setup_inputs.R
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

  finite_valid <- finite_result$probability[
    !is.na(finite_result$probability)
  ]
  infinite_valid <- infinite_result$probability[
    !is.na(infinite_result$probability)
  ]

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

# Integration Tests with primarycensored Package -----------------------------

test_that("local PMF calculations work with realistic data flows", {
  skip_if_not_installed("primarycensored")

  # Test realistic scenario configurations
  scenarios <- data.frame(
    scenario_id = c("short_delays", "long_delays"),
    distribution = c("gamma", "lognormal"),
    truncation = c("none", "none"),
    censoring = c("daily", "weekly"),
    growth_rate = c(0.1, 0.05),
    relative_obs_time = c(14, 30),
    primary_width = c(1, 7),
    secondary_width = c(1, 7),
    stringsAsFactors = FALSE
  )

  distributions <- data.frame(
    dist_name = c("gamma", "lognormal"),
    dist_family = c("gamma", "lnorm"),
    param1_name = c("shape", "meanlog"),
    param2_name = c("scale", "sdlog"),
    param1 = c(2.5, 1.2),
    param2 = c(1.8, 0.6),
    stringsAsFactors = FALSE
  )

  # Test each scenario can be processed
  for (i in 1:nrow(scenarios)) {
    scenario <- scenarios[i, ]
    dist_info <- distributions[
      distributions$dist_name == scenario$distribution,
    ]

    result <- calculate_pmf(
      scenario, dist_info, scenario$growth_rate, "analytical"
    )

    # Verify realistic outputs
    expect_s3_class(result, "data.frame")
    expect_true(all(c("scenario_id", "probability", "delay") %in%
      names(result)))

    # Check probabilities are valid
    valid_probs <- result$probability[!is.na(result$probability)]
    expect_true(length(valid_probs) > 0)
    expect_true(all(valid_probs >= 0))
    expect_true(all(valid_probs <= 1))

    # Verify delays are correctly structured (starts at 0, consecutive integers)
    expect_true(min(result$delay) == 0)
    expect_true(all(diff(result$delay) == 1))
    expect_true(length(result$delay) > 10)  # Reasonable range
    expect_identical(result$scenario_id[1], scenario$scenario_id)
  }
})

test_that("helper functions integrate properly with primarycensored API", {
  skip_if_not_installed("primarycensored")

  # Test that our helper functions work with primarycensored functions
  test_cases <- list(
    list(growth_rate = 0.1, expected_type = "closure"),
    list(growth_rate = 0, expected_type = "closure"),
    list(growth_rate = -0.05, expected_type = "closure")
  )

  for (case in test_cases) {
    # Test primary distribution helpers
    dprimary <- get_primary_dist(case$growth_rate)
    dprimary_args <- get_primary_args(case$growth_rate)

    expect_type(dprimary, case$expected_type)
    expect_type(dprimary_args, "list")

    # Test random generation helpers
    rprimary <- get_rprimary(case$growth_rate)
    rprimary_args <- get_rprimary_args(case$growth_rate)

    expect_type(rprimary, case$expected_type)
    expect_type(rprimary_args, "list")

    # Test that functions work with primarycensored
    test_value <- do.call(dprimary, c(list(x = 5), dprimary_args))
    expect_true(is.numeric(test_value))
    expect_true(is.finite(test_value))
    expect_true(test_value >= 0)
  }
})

test_that("end-to-end workflow produces consistent results", {
  skip_if_not_installed("primarycensored")

  # Simulate a realistic analysis workflow
  scenarios <- data.frame(
    scenario_id = "realistic_scenario",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.08,
    relative_obs_time = 21,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )

  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 3.2,
    param2 = 2.1,
    stringsAsFactors = FALSE
  )

  # Run complete workflow multiple times
  results <- list()
  for (i in 1:3) {
    results[[i]] <- calculate_pmf(scenarios, distributions, 0.08, "analytical")
  }

  # Verify consistency across runs
  for (i in 2:3) {
    expect_identical(results[[1]]$probability, results[[i]]$probability)
    expect_identical(results[[1]]$delay, results[[i]]$delay)
    expect_identical(results[[1]]$scenario_id, results[[i]]$scenario_id)
  }

  # Verify workflow produces expected structure
  result <- results[[1]]
  # Most probability mass captured
  expect_true(sum(result$probability, na.rm = TRUE) > 0.8)
})

test_that("package integration handles edge cases gracefully", {
  skip_if_not_installed("primarycensored")

  # Test extreme parameter values
  edge_scenarios <- data.frame(
    scenario_id = c("tiny_window", "large_D", "zero_growth"),
    distribution = c("gamma", "weibull", "lognormal"),
    truncation = c("none", "none", "none"),
    censoring = c("daily", "daily", "daily"),
    growth_rate = c(0.01, 0.2, 0),
    relative_obs_time = c(5, 50, 15),
    primary_width = c(0.1, 1, 1),
    secondary_width = c(0.1, 1, 1),
    stringsAsFactors = FALSE
  )

  edge_distributions <- data.frame(
    dist_name = c("gamma", "weibull", "lognormal"),
    dist_family = c("gamma", "weibull", "lnorm"),
    param1_name = c("shape", "shape", "meanlog"),
    param2_name = c("scale", "scale", "sdlog"),
    param1 = c(0.5, 0.8, 0.5),  # Small parameter values
    param2 = c(0.2, 0.5, 0.3),
    stringsAsFactors = FALSE
  )

  # Test each edge case
  for (i in 1:nrow(edge_scenarios)) {
    scenario <- edge_scenarios[i, ]
    dist_info <- edge_distributions[
      edge_distributions$dist_name == scenario$distribution,
    ]

    # Should not error with edge cases
    expect_no_error({
      result <- calculate_pmf(
        scenario, dist_info, scenario$growth_rate, "analytical"
      )
    })

    # Results should still be valid
    expect_s3_class(result, "data.frame")
    valid_probs <- result$probability[!is.na(result$probability)]
    expect_true(all(valid_probs >= 0))
    expect_true(all(valid_probs <= 1))
  }
})

test_that("numerical and analytical methods integrate consistently", {
  skip_if_not_installed("primarycensored")

  # Test that both methods work with primarycensored
  scenarios <- data.frame(
    scenario_id = "method_comparison",
    distribution = "gamma",
    truncation = "none",
    censoring = "daily",
    growth_rate = 0.05,
    relative_obs_time = 12,
    primary_width = 1,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )

  distributions <- data.frame(
    dist_name = "gamma",
    dist_family = "gamma",
    param1_name = "shape",
    param2_name = "scale",
    param1 = 2.0,
    param2 = 1.5,
    stringsAsFactors = FALSE
  )

  # Compare methods
  analytical_result <- calculate_pmf(
    scenarios, distributions, 0.05, "analytical"
  )
  numerical_result <- calculate_pmf(
    scenarios, distributions, 0.05, "numerical"
  )

  # Both should produce valid results
  expect_s3_class(analytical_result, "data.frame")
  expect_s3_class(numerical_result, "data.frame")

  # Should have same structure
  expect_identical(names(analytical_result), names(numerical_result))
  expect_identical(analytical_result$delay, numerical_result$delay)
  expect_identical(
    analytical_result$scenario_id, numerical_result$scenario_id
  )

  # Results should be close (allowing for numerical precision)
  analytical_probs <- analytical_result$probability[
    !is.na(analytical_result$probability)
  ]
  numerical_probs <- numerical_result$probability[
    !is.na(numerical_result$probability)
  ]

  expect_equal(length(analytical_probs), length(numerical_probs))
  expect_equal(analytical_probs, numerical_probs, tolerance = 1e-3)
})

