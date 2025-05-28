tar_target(
  truncation_scenarios,
  data.frame(
    trunc_name = c("none", "moderate", "severe"),
    max_delay = c(Inf, 10, 5),
    scenario_type = c("retrospective", "real-time", "real-time")
  )
)
