tar_target(
  saved_results,
  {
    # Verify .save_data function exists
    if (!exists(".save_data")) {
      stop(".save_data function not found. Ensure utils.R is sourced.")
    }
    
    # Track save results
    save_results <- list()
    
    # Save main results tables with error handling
    save_results$table1 <- tryCatch({
      if (!exists("results_tables") || is.null(results_tables$validation)) {
        warning("results_tables$validation not found, skipping.")
        NULL
      } else {
        .save_data(results_tables$validation, "table1_validation.csv", 
                   path = "results")
      }
    }, error = function(e) {
      warning("Failed to save table1_validation: ", e$message)
      NULL
    })
    
    save_results$table2 <- tryCatch({
      if (!exists("results_tables") || is.null(results_tables$recovery)) {
        warning("results_tables$recovery not found, skipping.")
        NULL
      } else {
        .save_data(results_tables$recovery, "table2_recovery.csv", 
                   path = "results")
      }
    }, error = function(e) {
      warning("Failed to save table2_recovery: ", e$message)
      NULL
    })
    
    save_results$table3 <- tryCatch({
      if (!exists("results_tables") || is.null(results_tables$performance)) {
        warning("results_tables$performance not found, skipping.")
        NULL
      } else {
        .save_data(results_tables$performance, "table3_performance.csv", 
                   path = "results")
      }
    }, error = function(e) {
      warning("Failed to save table3_performance: ", e$message)
      NULL
    })
    
    # Save detailed results for reproducibility
    save_results$scenarios <- tryCatch({
      if (!exists("scenario_grid")) {
        warning("scenario_grid not found, skipping.")
        NULL
      } else {
        .save_data(scenario_grid, "scenario_definitions.csv", path = "results")
      }
    }, error = function(e) {
      warning("Failed to save scenario_definitions: ", e$message)
      NULL
    })
    
    save_results$model_fits <- tryCatch({
      if (!exists("all_model_fits")) {
        warning("all_model_fits not found, skipping.")
        NULL
      } else {
        .save_data(all_model_fits, "all_model_fits.csv", path = "results")
      }
    }, error = function(e) {
      warning("Failed to save all_model_fits: ", e$message)
      NULL
    })
    
    save_results$ebola <- tryCatch({
      if (!exists("ebola_model_fits")) {
        warning("ebola_model_fits not found, skipping.")
        NULL
      } else {
        .save_data(ebola_model_fits, "ebola_results.csv", path = "results")
      }
    }, error = function(e) {
      warning("Failed to save ebola_results: ", e$message)
      NULL
    })
    
    # Return list of saved files
    save_results
  },
  # Explicit dependencies
  deps = c("results_tables", "scenario_grid", "all_model_fits", "ebola_model_fits")
)
