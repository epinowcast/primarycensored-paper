tar_target(stan_settings, {
  list(
    chains = 2,
    parallel_chains = 1,
    iter_warmup = 1000,
    iter_sampling = 1000,
    adapt_delta = 0.95,
    show_messages = FALSE,
    show_exceptions = FALSE,
    refresh = 0
  )
})