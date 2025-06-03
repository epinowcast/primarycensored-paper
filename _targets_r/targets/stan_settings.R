tar_target(stan_settings, {
  list(
    chains = if (test_mode) 1 else 2, # Just 1 chain for test mode
    parallel_chains = 1, # Run sequentially to avoid resource contention
    iter_warmup = if (test_mode) 50 else 1000, # Much lower iterations for testing
    iter_sampling = if (test_mode) 50 else 1000,
    adapt_delta = 0.95,
    show_messages = FALSE,
    show_exceptions = FALSE,
    refresh = 0
  )
})
