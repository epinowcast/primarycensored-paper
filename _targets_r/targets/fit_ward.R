tar_target(
  ward_fits,
  fit_ward(fitting_grid, stan_settings, compile_ward_model),
  pattern = map(fitting_grid)
)