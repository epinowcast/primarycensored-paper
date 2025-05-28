tar_target(
  model_diagnostics,
  {
    # Placeholder for model diagnostics
    message("Running model diagnostics...")
    list(
      convergence = TRUE,
      effective_sample_size = 1000
    )
  }
)
