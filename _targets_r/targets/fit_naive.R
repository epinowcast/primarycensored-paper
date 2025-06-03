tar_target(
  naive_fits,
  fit_naive(fitting_grid, stan_settings, compile_naive_model),
  pattern = map(fitting_grid)
)