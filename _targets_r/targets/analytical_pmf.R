tar_target(
  analytical_pmf,
  calculate_pmf(
    scenarios = scenarios,
    distributions = distributions,
    growth_rate = scenarios$growth_rate,
    method = "analytical"
  ),
  pattern = map(scenarios)
)
