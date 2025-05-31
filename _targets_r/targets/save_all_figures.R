tar_target(
  saved_figures,
  {
    # Main figures
    save_plot(figure1_numerical, "figure1_numerical_validation.pdf", width = 12, height = 4)
    save_plot(figure2_parameters, "figure2_parameter_recovery.pdf", width = 12, height = 4)
    save_plot(figure3_ebola, "figure3_ebola_case_study.pdf", width = 12, height = 4)
    
    # Supplementary figures would be added here
    
    TRUE
  }
)
