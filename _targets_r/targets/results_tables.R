tar_target(
  results_tables,
  {
    # Table 1: Numerical validation results
    table1_validation <- pmf_comparison |>
      dplyr::group_by(distribution, method) |>
      dplyr::summarise(
        mean_tvd = mean(total_variation_distance),
        .groups = "drop"
      )
    
    # Table 2: Parameter recovery summary
    table2_recovery <- parameter_recovery |>
      dplyr::group_by(method) |>
      dplyr::summarise(
        mean_bias = mean(c(bias_param1, bias_param2)),
        mean_coverage = mean(c(coverage_param1, coverage_param2)),
        .groups = "drop"
      )
    
    # Table 3: Computational performance
    # First get the Monte Carlo runtime at 10k sample size for comparison
    mc_runtime_10k <- runtime_comparison |>
      dplyr::filter(method == "monte_carlo", sample_size == 10000) |>
      dplyr::pull(runtime_seconds) |>
      dplyr::first()
    
    table3_performance <- runtime_comparison |>
      dplyr::filter(sample_size == 10000) |>
      dplyr::group_by(method) |>
      dplyr::summarise(
        runtime_10k = dplyr::first(runtime_seconds),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        relative_to_mc = runtime_10k / mc_runtime_10k
      )
    
    list(
      validation = table1_validation,
      recovery = table2_recovery,
      performance = table3_performance
    )
  }
)
