tar_target(observation_windows, {
  data.frame(
    window_id = 1:4,
    start_day = c(0, 60, 120, 180),
    end_day = c(60, 120, 180, 240),
    window_label = c("0-60 days", "60-120 days", "120-180 days", "180-240 days")
  )
})
