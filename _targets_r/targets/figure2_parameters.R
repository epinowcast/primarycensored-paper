tar_target(
  figure2_parameters,
  {
    # Panel A: Gamma distribution posteriors
    panel_a <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "A. Gamma Parameter Recovery")
    
    # Panel B: Bias comparison across distributions
    panel_b <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "B. Relative Bias (%)")
    
    # Panel C: Effect of censoring width
    panel_c <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "C. Censoring Width Effect")
    
    patchwork::wrap_plots(panel_a, panel_b, panel_c, ncol = 3)
  }
)
