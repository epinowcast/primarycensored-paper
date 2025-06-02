tar_target(compile_naive_model, {
  cmdstanr::cmdstan_model(here::here("stan", "naive_delay_model.stan"))
})
