tar_target(distributions, {
  data.frame(
    dist_name = c("gamma", "lognormal", "burr"),
    dist_family = c("gamma", "lnorm", "gamma"),  # Using gamma as placeholder for burr
    param1 = c(5, 1.5, 5),       # shape/meanlog/shape (burr using gamma params)
    param2 = c(1, 0.5, 1),       # scale/sdlog/scale (burr using gamma params)
    param3 = c(NA, NA, NA),      # NA/NA/NA (burr params to be implemented later)
    param1_name = c("shape", "meanlog", "shape"),
    param2_name = c("scale", "sdlog", "scale"),
    mean = c(5, 5, 5),           # All have mean = 5 days
    variance = c(5, 10, 5),      # gamma, lognormal, burr (using gamma variance)
    has_analytical = c(TRUE, TRUE, FALSE)
  )
})