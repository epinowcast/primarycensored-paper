test_that("save_plot function parameters are correct", {
  # Test function exists and has correct parameters
  expect_true(exists("save_plot"))
  expect_length(formals(save_plot), 5)
  expect_identical(
    names(formals(save_plot)),
    c("plot", "filename", "width", "height", "dpi")
  )

  # Test default parameter values
  defaults <- formals(save_plot)
  expect_identical(defaults$width, 8)
  expect_identical(defaults$height, 6)
  expect_identical(defaults$dpi, 300)
})

test_that("save_data function parameters are correct", {
  # Test function exists and has correct parameters
  expect_true(exists("save_data"))
  expect_length(formals(save_data), 2)
  expect_identical(names(formals(save_data)), c("data", "filename"))
})

