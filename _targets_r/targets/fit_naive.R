tar_target(
  naive_fits,
  {
    fit_naive_model(simulated_data)
  },
  pattern = map(simulated_data)
)
