tar_target(
  numerical_pmf,
  calculate_pmf(
    scenarios = scenarios,
    distributions = distributions,
    growth_rate = scenarios$growth_rate,
    method = "numerical"
  ),
  pattern = map(scenarios)
)