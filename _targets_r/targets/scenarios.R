tar_target(
  scenarios,
  data.frame(
    scenario_id = c("base", "long_delay", "high_censoring"),
    n = c(1000, 1000, 1000),
    rate = c(0.1, 0.1, 0.1),
    meanlog = c(1.5, 2.0, 1.5),
    sdlog = c(0.5, 0.7, 0.5),
    censoring_interval = c(1, 1, 7),
    distribution = "lognormal",
    seed = 123
  )
)
