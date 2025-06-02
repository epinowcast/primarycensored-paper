tarchetypes::tar_group_by(
  fitting_grid,
  {
    # Create simulation grid with embedded data
    simulation_grid <- monte_carlo_samples |>
      dplyr::group_by(scenario_id, sample_size, distribution, truncation, censoring, growth_rate) |>
      dplyr::summarise(
        data = list(dplyr::cur_data()),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        data_type = "simulation",
        dataset_id = paste0(scenario_id, "_n", sample_size)
      )
    
    # Create Ebola fitting entries
    ebola_grid <- ebola_case_study_data |>
      dplyr::mutate(
        data_type = "ebola",
        dataset_id = paste0("ebola_", window_id, "_", analysis_type),
        scenario_id = dataset_id,
        sample_size = n_cases,
        distribution = "gamma",  # Ebola analysis uses gamma
        truncation = "none",     # Will be determined by analysis
        censoring = "double",    # Double interval censoring
        growth_rate = 0.2       # Exponential growth assumption
      ) |>
      dplyr::select(scenario_id, sample_size, distribution, truncation, 
                   censoring, growth_rate, data_type, dataset_id)
    
    # Combine both grids
    combined_grid <- dplyr::bind_rows(simulation_grid, ebola_grid)
    
    # Apply test mode filtering if enabled
    if (test_mode) {
      combined_grid <- combined_grid |>
        dplyr::filter(
          # Take one scenario of each distribution type with smallest sample size
          (data_type == "simulation" & 
           scenario_id %in% c(
             scenarios$scenario_id[scenarios$distribution == "gamma"][1],
             scenarios$scenario_id[scenarios$distribution == "lognormal"][1]
           ) & 
           sample_size == min(sample_sizes)) |
          # Take one Ebola scenario
          (data_type == "ebola" & dplyr::row_number() == 1)
        )
    }
    
    combined_grid
  },
  dataset_id  # Group by unique dataset identifier
)
