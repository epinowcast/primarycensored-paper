tar_target(
  primarycensored_fits,
  fit_primarycensored(fitting_grid, stan_settings, compile_primarycensored_model),
  pattern = map(fitting_grid)
)