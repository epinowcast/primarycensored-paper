tar_target(
  distributions,
  data.frame(
    dist_name = c("gamma", "lognormal", "burr"),
    dist_family = c("gamma", "lnorm", "burr"),
    param1 = c(5, 1.5, 3),       # shape/meanlog/shape1
    param2 = c(1, 0.5, 1.5),     # scale/sdlog/shape2
    param3 = c(NA, NA, 4),       # NA/NA/scale
    mean = c(5, 5, 5),           # All have mean = 5 days
    variance = c(5, 10, 10),     # Increasing variance
    has_analytical = c(TRUE, TRUE, FALSE)
  )
)
