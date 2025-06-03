tar_target(convergence_diagnostics, {
  # Extract convergence diagnostics from Bayesian model fits
  bayesian_fits <- simulated_model_fits |>
    dplyr::filter(method %in% c("primarycensored", "ward"))

  if (nrow(bayesian_fits) == 0) {
    # Return empty structure if no Bayesian fits available
    data.frame(
      method = character(0),
      mean_rhat = numeric(0),
      total_divergences = numeric(0),
      mean_ess = numeric(0),
      mean_runtime = numeric(0)
    )
  } else {
    # Calculate convergence statistics by method
    bayesian_fits |>
      dplyr::group_by(method) |>
      dplyr::summarise(
        mean_rhat = mean(convergence, na.rm = TRUE),
        total_divergences = sum(num_divergent, na.rm = TRUE),
        mean_ess = mean(pmin(ess_bulk_min, ess_tail_min), na.rm = TRUE),
        mean_runtime = mean(runtime_seconds, na.rm = TRUE),
        .groups = "drop"
      )
  }
})
