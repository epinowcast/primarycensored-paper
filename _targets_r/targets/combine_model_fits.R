tar_target(
  all_model_fits,
  {
    # Placeholder for combined model results
    # Real implementation would properly extract and combine fit results
    
    # Create placeholder combined results
    expand.grid(
      method = c("primarycensored", "naive", "ward"),
      scenario_id = paste0("scenario_", 1:27),
      parameter = c("param1", "param2")
    ) |>
      dplyr::mutate(
        estimate = ifelse(method == "primarycensored", 5.0, 
                         ifelse(method == "naive", 4.5, 5.1)),
        se = 0.1
      )
  }
)
