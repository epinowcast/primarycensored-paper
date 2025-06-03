#' Create unified fitting grid for parameter recovery analysis
#'
#' Combines simulated data with Ebola case study data into a single
#' dataframe with embedded data for unified fitting across all methods.
#'
#' @param monte_carlo_samples List of Monte Carlo samples from simulation
#'   scenarios
#' @param ebola_case_study_data Ebola case study data with observation windows
#' @param scenarios Scenario grid with distribution information
#' @param sample_sizes Vector of sample sizes for filtering in test mode
#' @param test_mode Logical indicating whether to apply test mode filtering
#' @return Data frame with embedded data ready for model fitting
#' @export
create_fitting_grid <- function(monte_carlo_samples, ebola_case_study_data,
                                scenarios, sample_sizes, test_mode = FALSE) {
  # Suppress CMD check warnings for data.table/dplyr usage
  scenario_id <- sample_size <- distribution <- truncation <- NULL
  censoring <- growth_rate <- window_id <- analysis_type <- NULL
  dataset_id <- n_cases <- data_type <- NULL
  
  # Create simulation grid with embedded data
  simulation_grid <- monte_carlo_samples |>
    dplyr::group_by(
      scenario_id, sample_size, distribution, truncation, censoring, growth_rate
    ) |>
    dplyr::summarise(
      data = list(dplyr::pick(dplyr::everything())),
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
      distribution = "gamma", # Ebola analysis uses gamma
      truncation = "none", # Will be determined by analysis
      censoring = "double", # Double interval censoring
      growth_rate = 0.2 # Exponential growth assumption
    ) |>
    dplyr::select(
      scenario_id, sample_size, distribution, truncation,
      censoring, growth_rate, data_type, dataset_id, data
    )

  # Combine both grids
  combined_grid <- dplyr::bind_rows(simulation_grid, ebola_grid)

  # Apply test mode filtering if enabled
  if (test_mode) {
    # Get simulation data only (exclude Ebola)
    sim_only <- combined_grid |>
      dplyr::filter(data_type == "simulation")

    # For each distribution, select one scenario with smallest sample size
    combined_grid <- sim_only |>
      dplyr::group_by(distribution) |>
      dplyr::filter(sample_size == min(sample_size)) |>
      dplyr::slice(1) |>  # Take first scenario for each distribution
      dplyr::ungroup()
  }

  combined_grid
}
