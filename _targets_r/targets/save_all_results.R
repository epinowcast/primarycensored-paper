tar_target(
  saved_results,
  {
    # Save detailed results for reproducibility
    save_data(scenario_grid, "scenario_definitions.csv")
    save_data(simulated_model_fits, "simulated_model_fits.csv")
    # Note: parameter_recovery, pmf_comparison, runtime_comparison don't exist yet
    # save_data(parameter_recovery, "parameter_recovery.csv")
    # save_data(pmf_comparison, "pmf_comparison.csv")
    # save_data(runtime_comparison, "runtime_comparison.csv")
    save_data(ebola_model_fits, "ebola_results.csv")

    TRUE
  }
)
