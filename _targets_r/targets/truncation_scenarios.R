tar_target(truncation_scenarios, {
  data.frame(
    trunc_name = c("none", "moderate", "severe"),
    relative_obs_time = c(Inf, 10, 5),  # Days from primary event
    scenario_type = c("retrospective", "real-time", "real-time")
  )
})