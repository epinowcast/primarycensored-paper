tar_target(compile_ward_model, {
  cmdstanr::cmdstan_model(here::here("stan", "ward_latent_model.stan"))
})