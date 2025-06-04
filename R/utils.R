#' Save a plot to the figures directory
#'
#' @param plot The plot object to save
#' @param filename The filename (without path)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution in dots per inch
#' @export
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  ggplot2::ggsave(
    filename = here::here("figures", filename),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
}

#' Save data to the results directory
#'
#' @param data The data object to save
#' @param filename The filename (without path)
#' @export
save_data <- function(data, filename) {
  write.csv(
    data,
    file = here::here("data/results", filename),
    row.names = FALSE
  )
}
