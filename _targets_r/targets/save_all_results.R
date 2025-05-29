tar_target(
  saved_results,
  {
    # Save detailed results for reproducibility
    .save_data(scenario_grid, "scenario_definitions.csv", path = "results")
    .save_data(all_model_fits, "all_model_fits.csv", path = "results")
    .save_data(parameter_recovery, "parameter_recovery.csv", path = "results")
    .save_data(pmf_comparison, "pmf_comparison.csv", path = "results")
    .save_data(runtime_comparison, "runtime_comparison.csv", path = "results")
    # TODO: Add ebola results when available
    # .save_data(ebola_model_fits, "ebola_results.csv", path = "results")
    
    TRUE
  }
)
