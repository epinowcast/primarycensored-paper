tar_target(
  runtime_comparison,
  {
    # Placeholder for runtime measurements
    data.frame(
      method = rep(c("analytical", "numerical", "monte_carlo", "ward"), times = 4),
      sample_size = rep(c(10, 100, 1000, 10000), each = 1, times = 4),
      runtime_seconds = c(
        0.001, 0.01, 0.1, 1,      # analytical
        0.01, 0.1, 1, 10,          # numerical  
        0.1, 1, 10, 100,           # monte_carlo
        1, 10, 100, 1000           # ward latent
      )
    )
  }
)
