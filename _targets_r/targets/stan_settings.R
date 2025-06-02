tar_target(stan_settings, {
  list(
    chains = if (test_mode) test_chains else 2,
    parallel_chains = 1,  # Run sequentially to avoid resource contention
    iter_warmup = if (test_mode) test_iterations else 1000,
    iter_sampling = if (test_mode) test_iterations else 1000,
    adapt_delta = 0.95,
    show_messages = FALSE,
    show_exceptions = FALSE,
    refresh = 0
  )
})
