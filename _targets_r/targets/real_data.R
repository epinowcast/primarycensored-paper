# Placeholder for loading real-world data
tar_target(
  real_world_data,
  {
    # TODO: Load actual data
    message("Loading real-world data...")
    data.frame(
      id = 1:10,
      primary_time = 1:10,
      secondary_time = 1:10 + rlnorm(10, 1.5, 0.5)
    )
  }
)
