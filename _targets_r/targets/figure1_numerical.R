tar_target(
  figure1_numerical,
  {
    # Panel A: PMF comparison
    panel_a <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "A. PMF Comparison")

    # Panel B: Accuracy metrics
    panel_b <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "B. Total Variation Distance")

    # Panel C: Runtime comparison
    panel_c <- ggplot2::ggplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "C. Computational Efficiency") +
      ggplot2::scale_y_log10()

    # Combine panels
    patchwork::wrap_plots(panel_a, panel_b, panel_c, ncol = 3)
  }
)