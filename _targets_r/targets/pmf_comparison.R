tar_target(
  pmf_comparison,
  {
    tictoc::tic("pmf_comparison")
    
    # Combine analytical and monte carlo PMFs for comparison
    combined_pmf <- dplyr::bind_rows(
      analytical_pmf,
      monte_carlo_pmf |> 
        dplyr::mutate(method = "monte_carlo") |>
        dplyr::select(scenario_id, distribution, truncation, censoring, method, delay, probability)
    )
    
    # Calculate total variation distance between analytical and Monte Carlo
    result <- combined_pmf |>
      dplyr::group_by(scenario_id, distribution, truncation, censoring, delay) |>
      dplyr::summarise(
        analytical_prob = probability[method == "analytical"],
        monte_carlo_prob = probability[method == "monte_carlo" & sample_size == 10000],
        .groups = "drop"
      ) |>
      dplyr::filter(!is.na(analytical_prob), !is.na(monte_carlo_prob)) |>
      dplyr::group_by(scenario_id, distribution, truncation, censoring) |>
      dplyr::summarise(
        total_variation_distance = sum(abs(analytical_prob - monte_carlo_prob)) / 2,
        .groups = "drop"
      )
    
    runtime <- tictoc::toc(quiet = TRUE)
    attr(result, "runtime_seconds") <- runtime$toc - runtime$tic
    
    # Also return the combined PMF data for plotting
    list(
      comparison_metrics = result,
      combined_pmf = combined_pmf
    )
  }
)
