tar_target(simulated_model_fits, {
  dplyr::bind_rows(
    primarycensored_fits,
    naive_fits,
    ward_fits
  )
})
