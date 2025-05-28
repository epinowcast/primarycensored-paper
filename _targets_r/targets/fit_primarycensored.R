tar_target(
  primarycensored_fits,
  fit_primarycensored(simulated_data, formula = ~ 1),
  pattern = map(simulated_data)
)
