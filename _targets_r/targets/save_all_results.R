tar_target(
  saved_results,
  {
    # Create results directory if it doesn't exist
    results_dir <- here("data", "results")
    if (!dir.exists(results_dir)) {
      dir.create(results_dir, recursive = TRUE)
    }
    
    # Save detailed results for reproducibility
    write.csv(scenario_grid, file = file.path(results_dir, "scenario_definitions.csv"), row.names = FALSE)
    write.csv(all_model_fits, file = file.path(results_dir, "all_model_fits.csv"), row.names = FALSE)
    write.csv(parameter_recovery, file = file.path(results_dir, "parameter_recovery.csv"), row.names = FALSE)
    write.csv(pmf_comparison, file = file.path(results_dir, "pmf_comparison.csv"), row.names = FALSE)
    write.csv(runtime_comparison, file = file.path(results_dir, "runtime_comparison.csv"), row.names = FALSE)
    write.csv(ebola_model_fits, file = file.path(results_dir, "ebola_results.csv"), row.names = FALSE)
    
    # Return paths of saved files
    list.files(results_dir, pattern = "\\.csv$", full.names = TRUE)
  }
)
