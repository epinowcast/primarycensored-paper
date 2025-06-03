tarchetypes::tar_group_by(
  fitting_grid,
  create_fitting_grid(
    monte_carlo_samples = monte_carlo_samples,
    ebola_case_study_data = ebola_case_study_data,
    scenarios = scenarios,
    sample_sizes = sample_sizes,
    test_mode = test_mode
  ),
  dataset_id  # Group by unique dataset identifier
)