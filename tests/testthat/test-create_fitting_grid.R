test_that("create_fitting_grid combines simulation and ebola data correctly", {
  skip_if_not_installed("dplyr")

  # Create mock Monte Carlo samples
  mock_monte_carlo <- data.frame(
    scenario_id = c(
      "gamma_none_daily_r0", "gamma_none_daily_r0",
      "lognormal_moderate_weekly_r0.2"
    ),
    sample_size = c(100, 100, 200),
    distribution = c("gamma", "gamma", "lognormal"),
    truncation = c("none", "none", "moderate"),
    censoring = c("daily", "daily", "weekly"),
    growth_rate = c(0, 0, 0.2),
    delay_observed = c(2.5, 3.1, 4.2)
  )

  # Create mock Ebola delay data (transformed format with nested structure)
  ebola_data_1 <- data.frame(
    delay_observed = c(1.2, 2.3),
    prim_cens_lower = c(0, 0),
    prim_cens_upper = c(1, 1),
    sec_cens_lower = c(1.2, 2.3),
    sec_cens_upper = c(2.2, 3.3),
    relative_obs_time = c(60, 58)
  )
  ebola_data_2 <- data.frame(
    delay_observed = c(3.4, 4.5),
    prim_cens_lower = c(0, 0),
    prim_cens_upper = c(1, 1),
    sec_cens_lower = c(3.4, 4.5),
    sec_cens_upper = c(4.4, 5.5),
    relative_obs_time = c(120, 118)
  )

  mock_ebola <- data.frame(
    window_id = c(1, 2),
    analysis_type = c("real_time", "retrospective"),
    window_label = c("0-60 days", "60-120 days"),
    start_day = c(0, 60),
    end_day = c(60, 120),
    n_cases = c(2, 2),
    data = I(list(ebola_data_1, ebola_data_2))
  )

  # Mock scenarios for test mode filtering
  mock_scenarios <- data.frame(
    scenario_id = c("gamma_none_daily_r0", "lognormal_moderate_weekly_r0.2"),
    distribution = c("gamma", "lognormal")
  )

  # Test normal mode
  result <- create_fitting_grid(
    monte_carlo_samples = mock_monte_carlo,
    ebola_delay_data = mock_ebola,
    scenarios = mock_scenarios,
    sample_sizes = c(100, 200),
    test_mode = FALSE
  )

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_true(all(c(
    "scenario_id", "sample_size", "distribution", "truncation",
    "censoring", "growth_rate", "data_type", "dataset_id", "data"
  ) %in% names(result)))

  # Check data types
  expect_true("simulation" %in% result$data_type)
  expect_true("ebola" %in% result$data_type)

  # Check simulation data
  sim_data <- result[result$data_type == "simulation", ]
  expect_gt(nrow(sim_data), 0)
  expect_true(all(grepl("_n", sim_data$dataset_id)))

  # Check Ebola data
  ebola_data <- result[result$data_type == "ebola", ]
  expect_gt(nrow(ebola_data), 0)
  expect_true(all(grepl("ebola_", ebola_data$dataset_id)))
  expect_true(all(ebola_data$distribution == "gamma"))
  expect_true(all(ebola_data$growth_rate == 0.2))
})

test_that("create_fitting_grid handles test mode filtering", {
  skip_if_not_installed("dplyr")

  # Create mock data with multiple scenarios
  mock_monte_carlo <- data.frame(
    scenario_id = c(
      "gamma_none_daily_r0", "gamma_none_daily_r0",
      "lognormal_moderate_weekly_r0.2", "lognormal_moderate_weekly_r0.2"
    ),
    sample_size = c(100, 200, 100, 200),
    distribution = c("gamma", "gamma", "lognormal", "lognormal"),
    truncation = c("none", "none", "moderate", "moderate"),
    censoring = c("daily", "daily", "weekly", "weekly"),
    growth_rate = c(0, 0, 0.2, 0.2),
    delay_observed = c(2.5, 3.1, 4.2, 5.3)
  )

  # Create nested mock data for second test
  ebola_data_test2_1 <- data.frame(
    delay_observed = c(1.2, 2.3),
    prim_cens_lower = c(0, 0),
    prim_cens_upper = c(1, 1),
    sec_cens_lower = c(1.2, 2.3),
    sec_cens_upper = c(2.2, 3.3),
    relative_obs_time = c(60, 58)
  )
  ebola_data_test2_2 <- data.frame(
    delay_observed = c(3.4, 4.5),
    prim_cens_lower = c(0, 0),
    prim_cens_upper = c(1, 1),
    sec_cens_lower = c(3.4, 4.5),
    sec_cens_upper = c(4.4, 5.5),
    relative_obs_time = c(120, 118)
  )

  mock_ebola <- data.frame(
    window_id = c(1, 2),
    analysis_type = c("real_time", "retrospective"),
    window_label = c("0-60 days", "60-120 days"),
    start_day = c(0, 60),
    end_day = c(60, 120),
    n_cases = c(2, 2),
    data = I(list(ebola_data_test2_1, ebola_data_test2_2))
  )

  mock_scenarios <- data.frame(
    scenario_id = c("gamma_none_daily_r0", "lognormal_moderate_weekly_r0.2"),
    distribution = c("gamma", "lognormal")
  )

  # Test with test mode enabled
  result_test <- create_fitting_grid(
    monte_carlo_samples = mock_monte_carlo,
    ebola_delay_data = mock_ebola,
    scenarios = mock_scenarios,
    sample_sizes = c(100, 200),
    test_mode = TRUE
  )

  # In test mode, should have limited data
  expect_s3_class(result_test, "data.frame")
  expect_lt(nrow(result_test), nrow(mock_monte_carlo) + nrow(mock_ebola))

  # Should have exactly one scenario per distribution with smallest sample size
  expect_equal(nrow(result_test), 2)  # One for gamma, one for lognormal
  expect_true(all(result_test$data_type == "simulation"))
  expect_equal(sum(result_test$distribution == "gamma"), 1)
  expect_equal(sum(result_test$distribution == "lognormal"), 1)
  expect_true(all(result_test$sample_size == 200))  # Second smallest

  # Should have NO Ebola data in test mode
  ebola_data <- result_test[result_test$data_type == "ebola", ]
  expect_equal(nrow(ebola_data), 0)
})

test_that("create_fitting_grid handles empty input gracefully", {
  skip_if_not_installed("dplyr")

  # Empty Monte Carlo samples
  empty_monte_carlo <- data.frame(
    scenario_id = character(0),
    sample_size = numeric(0),
    distribution = character(0),
    truncation = character(0),
    censoring = character(0),
    growth_rate = numeric(0)
  )

  # Empty Ebola data with nested structure
  empty_ebola <- data.frame(
    window_id = numeric(0),
    analysis_type = character(0),
    window_label = character(0),
    start_day = numeric(0),
    end_day = numeric(0),
    n_cases = numeric(0),
    data = I(list())
  )

  mock_scenarios <- data.frame(
    scenario_id = character(0),
    distribution = character(0)
  )

  # Should not error with empty inputs
  result <- create_fitting_grid(
    monte_carlo_samples = empty_monte_carlo,
    ebola_delay_data = empty_ebola,
    scenarios = mock_scenarios,
    sample_sizes = c(100),
    test_mode = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_identical(nrow(result), 0L)
})
