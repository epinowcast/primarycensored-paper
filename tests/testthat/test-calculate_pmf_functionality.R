test_that("calculate_pmf matches dprimarycensored for gamma distribution", {
  skip_if_not_installed("primarycensored")
  
  # Set up test scenario
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
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Calculate directly with dprimarycensored for comparison
  delays <- result$delay
  
  direct_pmf <- primarycensored::dprimarycensored(
    delays,
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    pdist = pgamma,
    dprimary = primarycensored::dexpgrowth,
    dprimary_args = list(r = growth_rate),
    shape = 2,
    scale = 1
  )
  
  # Compare results
  expect_equal(result$probability, direct_pmf, tolerance = 1e-10)
})

test_that("calculate_pmf matches dprimarycensored for lognormal distribution", {
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
  
  growth_rate <- 0.05
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Calculate directly with dprimarycensored for comparison
  delays <- result$delay
  
  direct_pmf <- primarycensored::dprimarycensored(
    delays,
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    pdist = plnorm,
    dprimary = primarycensored::dexpgrowth,
    dprimary_args = list(r = growth_rate),
    meanlog = 1.5,
    sdlog = 0.5
  )
  
  # Compare results
  expect_equal(result$probability, direct_pmf, tolerance = 1e-10)
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
  
  growth_rate <- 0
  
  # Calculate using our function
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Calculate directly with dprimarycensored using uniform primary
  delays <- result$delay
  
  direct_pmf <- primarycensored::dprimarycensored(
    delays,
    pwindow = scenarios$primary_width,
    swindow = scenarios$secondary_width,
    D = scenarios$relative_obs_time,
    pdist = pgamma,
    dprimary = dunif,
    dprimary_args = list(min = 0, max = scenarios$primary_width),
    shape = 3,
    scale = 2
  )
  
  # Compare results
  expect_equal(result$probability, direct_pmf, tolerance = 1e-10)
})

test_that("calculate_pmf numerical method matches analytical for simple cases", {
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
  
  growth_rate <- 0.05
  
  # Calculate using both methods
  result_analytical <- calculate_pmf(
    scenarios, distributions, growth_rate, "analytical"
  )
  result_numerical <- calculate_pmf(
    scenarios, distributions, growth_rate, "numerical"
  )
  
  # Results should be very close
  expect_equal(
    result_analytical$probability,
    result_numerical$probability,
    tolerance = 1e-3
  )
})

test_that("calculate_pmf handles single gamma scenario correctly", {
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
  
  # Calculate PMF
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Check basic properties
  expect_true(all(result$probability >= 0, na.rm = TRUE))
  expect_true(all(result$probability <= 1, na.rm = TRUE))
  expect_true(all(result$distribution == "gamma"))
})

test_that("calculate_pmf handles single lognormal scenario correctly", {
  skip_if_not_installed("primarycensored")
  
  scenarios <- data.frame(
    scenario_id = "lognormal_none_medium_r0.1",
    distribution = "lognormal",
    truncation = "none",
    censoring = "medium",
    growth_rate = 0.1,
    relative_obs_time = 12,
    primary_width = 2,
    secondary_width = 1,
    stringsAsFactors = FALSE
  )
  
  distributions <- data.frame(
    dist_name = "lognormal",
    dist_family = "lnorm",
    param1_name = "meanlog",
    param2_name = "sdlog",
    param1 = 1,
    param2 = 0.5,
    stringsAsFactors = FALSE
  )
  
  growth_rate <- 0.1
  
  # Calculate PMF
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Check basic properties
  expect_true(all(result$probability >= 0, na.rm = TRUE))
  expect_true(all(result$probability <= 1, na.rm = TRUE))
  expect_true(all(result$distribution == "lognormal"))
})

test_that("calculate_pmf handles edge case parameter values", {
  skip_if_not_installed("primarycensored")
  
  # Test with very small shape parameter
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
  
  growth_rate <- 0
  
  result <- calculate_pmf(scenarios, distributions, growth_rate, "analytical")
  
  # Check results are valid (handle NAs appropriately)
  valid_probs <- result$probability[!is.na(result$probability)]
  expect_true(all(valid_probs >= 0))
  expect_true(all(valid_probs <= 1))
  expect_true(sum(valid_probs) <= 1)
})