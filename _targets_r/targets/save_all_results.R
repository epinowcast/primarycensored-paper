tar_target(
  saved_results,
  {
    # Save main results tables
    .save_data(results_tables$validation, "table1_validation.csv", path = "results")
    .save_data(results_tables$recovery, "table2_recovery.csv", path = "results")
    .save_data(results_tables$performance, "table3_performance.csv", path = "results")
    
    # Save detailed results for reproducibility
    .save_data(scenario_grid, "scenario_definitions.csv", path = "results")
    .save_data(all_model_fits, "all_model_fits.csv", path = "results")
    .save_data(ebola_model_fits, "ebola_results.csv", path = "results")
    
    TRUE
  }
)
