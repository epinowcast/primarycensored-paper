# Utility functions for primarycensored analysis

#' Save a plot to the figures directory
#' @param plot A ggplot object
#' @param filename Character string for the filename
#' @param width Numeric width in inches
#' @param height Numeric height in inches
#' @param ... Additional arguments passed to ggsave
.save_plot <- function(plot, filename, width = 8, height = 6, ...) {
  ggplot2::ggsave(
    filename = here::here("figures", filename),
    plot = plot,
    width = width,
    height = height,
    ...
  )
}

#' Save a data frame as CSV
#' @param data A data frame
#' @param filename Character string for the filename
#' @param path Character string for subdirectory in data/
.save_data <- function(data, filename, path = "processed") {
  data.table::fwrite(
    x = data,
    file = here::here("data", path, filename)
  )
}