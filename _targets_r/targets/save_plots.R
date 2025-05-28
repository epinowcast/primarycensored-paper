tar_target(
  saved_plots,
  {
    .save_plot(delay_comparison_plot, "delay_comparison.pdf")
    .save_plot(simulation_results_plot, "simulation_results.pdf")
    TRUE
  }
)
