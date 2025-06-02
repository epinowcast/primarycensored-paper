tar_target(compile_stan_models, {
  list(
    naive_model = cmdstanr::cmdstan_model(here::here("stan", "naive_delay_model.stan")),
    ward_model = cmdstanr::cmdstan_model(here::here("stan", "ward_latent_model.stan"))
  )
})
