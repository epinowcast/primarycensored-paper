# Utility functions for primarycensored analysis

#' Save a plot to the figures directory
#' @param plot A ggplot object
#' @param filename Character string for the filename
#' @param width Numeric width in inches
#' @param height Numeric height in inches
#' @param ... Additional arguments passed to ggsave
#' @return The full file path where the plot was saved, or NULL if saving failed
.save_plot <- function(plot, filename, width = 8, height = 6, ...) {
  # Ensure figures directory exists
  figures_dir <- here::here("figures")
  if (!dir.exists(figures_dir)) {
    dir.create(figures_dir, recursive = TRUE)
  }
  
  # Construct full file path
  file_path <- file.path(figures_dir, filename)
  
  # Try to save the plot with error handling
  tryCatch({
    ggplot2::ggsave(
      filename = file_path,
      plot = plot,
      width = width,
      height = height,
      ...
    )
    message("Plot saved successfully to: ", file_path)
    return(file_path)
  }, error = function(e) {
    warning("Failed to save plot '", filename, "': ", e$message)
    return(NULL)
  })
}

#' Save a data frame as CSV
#' @param data A data frame
#' @param filename Character string for the filename
#' @param path Character string for subdirectory in data/
#' @return The full file path where the data was saved
.save_data <- function(data, filename, path = "processed") {
  # Validate inputs
  if (!is.data.frame(data) && !data.table::is.data.table(data)) {
    stop("'data' must be a data frame or data.table")
  }
  
  if (!is.character(filename) || length(filename) != 1 || 
      nchar(trimws(filename)) == 0) {
    stop("'filename' must be a non-empty character string")
  }
  
  # Construct full file path
  dir_path <- here::here("data", path)
  file_path <- file.path(dir_path, filename)
  
  # Create directory if it doesn't exist
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  
  # Save the data
  data.table::fwrite(
    x = data,
    file = file_path
  )
  
  # Return the full file path
  return(file_path)
}

#' Create a PMF result data frame with consistent structure
#' @param scenarios Scenario metadata
#' @param method Character string indicating method ("analytical" or "numerical")
#' @param delays Vector of delay values
#' @param probability Vector of probabilities
#' @param runtime_seconds Numeric runtime in seconds
#' @return A data frame with consistent PMF result structure
.create_pmf_result <- function(scenarios, method, delays, probability, runtime_seconds) {
  data.frame(
    scenario_id = scenarios$scenario_id,
    distribution = scenarios$distribution,
    truncation = scenarios$truncation,
    censoring = scenarios$censoring,
    method = method,
    delay = delays,
    probability = probability,
    runtime_seconds = runtime_seconds
  )
}