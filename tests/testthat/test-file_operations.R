test_that("save_plot function signature and defaults", {
  # Test function exists
  expect_true(exists("save_plot"))

  # Test parameter names
  params <- names(formals(save_plot))
  expected_params <- c("plot", "filename", "width", "height", "dpi")
  expect_identical(params, expected_params)

  # Test default parameter values
  defaults <- formals(save_plot)
  expect_identical(defaults$width, 8)
  expect_identical(defaults$height, 6)
  expect_identical(defaults$dpi, 300)
})

test_that("save_data function signature", {
  # Test function exists
  expect_true(exists("save_data"))

  # Test parameter names
  params <- names(formals(save_data))
  expected_params <- c("data", "filename")
  expect_identical(params, expected_params)

  # Test no default parameters (both required)
  defaults <- formals(save_data)
  expect_true(is.symbol(defaults$data)) # Should be just the parameter name
  expect_true(is.symbol(defaults$filename))
})

test_that("file operation functions exist and are callable", {
  # Test that the functions exist and have correct structure
  expect_true(is.function(save_plot))
  expect_true(is.function(save_data))

  # Test that calling with wrong number of arguments fails
  # (may be due to missing args or missing dependencies)
  expect_error(save_plot())
  expect_error(save_data())
})
