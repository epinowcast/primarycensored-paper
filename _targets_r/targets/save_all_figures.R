tar_target(
  saved_figures,
  {
    # Verify .save_plot function exists
    if (!exists(".save_plot")) {
      stop(".save_plot function not found. Ensure utils.R is sourced.")
    }
    
    # Track save results
    save_results <- list()
    
    # Main figures with error handling
    save_results$figure1 <- tryCatch({
      if (!exists("figure1_numerical")) {
        warning("figure1_numerical object not found, skipping.")
        NULL
      } else {
        .save_plot(figure1_numerical, "figure1_numerical_validation.pdf", 
                   width = 12, height = 4)
      }
    }, error = function(e) {
      warning("Failed to save figure1_numerical: ", e$message)
      NULL
    })
    
    save_results$figure2 <- tryCatch({
      if (!exists("figure2_parameters")) {
        warning("figure2_parameters object not found, skipping.")
        NULL
      } else {
        .save_plot(figure2_parameters, "figure2_parameter_recovery.pdf", 
                   width = 12, height = 4)
      }
    }, error = function(e) {
      warning("Failed to save figure2_parameters: ", e$message)
      NULL
    })
    
    save_results$figure3 <- tryCatch({
      if (!exists("figure3_ebola")) {
        warning("figure3_ebola object not found, skipping.")
        NULL
      } else {
        .save_plot(figure3_ebola, "figure3_ebola_case_study.pdf", 
                   width = 12, height = 4)
      }
    }, error = function(e) {
      warning("Failed to save figure3_ebola: ", e$message)
      NULL
    })
    
    # Supplementary figures would be added here
    
    # Return list of saved files
    save_results
  },
  # Explicit dependencies
  deps = c("figure1_numerical", "figure2_parameters", "figure3_ebola")
)
