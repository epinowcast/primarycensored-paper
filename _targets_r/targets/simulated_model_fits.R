tar_target(simulated_model_fits, {
  dplyr::bind_rows(
    primarycensored_fits,
    primarycensored_fitdistrplus_fits,
    naive_fits,
    ward_fits
  )
})
