tar_target(
  distributions,
  data.frame(
    dist_name = c("gamma", "lognormal"),
    dist_family = c("gamma", "lnorm"),
    param1 = c(5, 1.5),          # shape/meanlog
    param2 = c(1, 0.5),          # scale/sdlog
    param3 = c(NA, NA),          # NA for both
    mean = c(5, 5),              # All have mean = 5 days
    variance = c(5, 10),         # Increasing variance
    has_analytical = c(TRUE, TRUE)
  )
)
