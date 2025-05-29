tar_target(
  figure3_ebola,
  {
    # Panel A: Parameter estimates over time
    panel_a <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "A. Parameter Estimates")
    
    # Panel B: Mean delay over observation windows
    panel_b <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "B. Mean Delay Estimates")
    
    # Panel C: Computational performance
    panel_c <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "C. Effective Samples per Second") +
      ggplot2::scale_y_log10()
    
    patchwork::wrap_plots(panel_a, panel_b, panel_c, ncol = 3)
  }
)
