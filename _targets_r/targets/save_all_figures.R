tar_target(
  saved_figures,
  {
    # Create figures directory if it doesn't exist
    if (!dir.exists(here("figures"))) {
      dir.create(here("figures"))
    }
    
    # Main figures
    ggplot2::ggsave(
      filename = here("figures", "figure1_numerical_validation.pdf"),
      plot = figure1_numerical,
      width = 12,
      height = 4,
      units = "in"
    )
    
    ggplot2::ggsave(
      filename = here("figures", "figure2_parameter_recovery.pdf"),
      plot = figure2_parameters,
      width = 12,
      height = 4,
      units = "in"
    )
    
    ggplot2::ggsave(
      filename = here("figures", "figure3_ebola_case_study.pdf"),
      plot = figure3_ebola,
      width = 12,
      height = 4,
      units = "in"
    )
    
    # Return paths of saved figures
    c(
      "figures/figure1_numerical_validation.pdf",
      "figures/figure2_parameter_recovery.pdf",
      "figures/figure3_ebola_case_study.pdf"
    )
  }
)
