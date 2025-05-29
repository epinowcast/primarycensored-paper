// Naive delay distribution model
// This model estimates delay distributions from censored data
// but does NOT properly account for primary event censoring
// This leads to biased estimates as demonstrated in the paper

data {
  int<lower=0> N;  // number of observations
  array[N] real<lower=0> delay_lower;  // lower bound of observed delay
  array[N] real<lower=0> delay_upper;  // upper bound of observed delay
  int<lower=1, upper=3> dist_id;  // 1=gamma, 2=lognormal, 3=weibull
}

parameters {
  real<lower=0> param1;  // shape (gamma/weibull) or meanlog (lognormal)
  real<lower=0> param2;  // scale (gamma/weibull) or sdlog (lognormal)
}

model {
  // Priors
  param1 ~ normal(5, 2);
  param2 ~ normal(1, 1);
  
  // Likelihood - treating delays as interval censored
  // but ignoring the primary event censoring
  for (i in 1:N) {
    real cdf_lower;
    real cdf_upper;
    
    if (dist_id == 1) {
      // Gamma distribution
      cdf_lower = gamma_cdf(delay_lower[i] | param1, param2);
      cdf_upper = gamma_cdf(delay_upper[i] | param1, param2);
    } else if (dist_id == 2) {
      // Lognormal distribution
      cdf_lower = lognormal_cdf(delay_lower[i] | param1, param2);
      cdf_upper = lognormal_cdf(delay_upper[i] | param1, param2);
    } else if (dist_id == 3) {
      // Weibull distribution
      cdf_lower = weibull_cdf(delay_lower[i] | param1, param2);
      cdf_upper = weibull_cdf(delay_upper[i] | param1, param2);
    }
    
    // Log probability of observation in interval
    target += log(cdf_upper - cdf_lower);
  }
}

generated quantities {
  // Calculate mean delay for comparison
  real mean_delay;
  
  if (dist_id == 1) {
    // Gamma mean = shape * scale
    mean_delay = param1 * param2;
  } else if (dist_id == 2) {
    // Lognormal mean = exp(meanlog + sdlog^2/2)
    mean_delay = exp(param1 + param2^2 / 2);
  } else if (dist_id == 3) {
    // Weibull mean = scale * Gamma(1 + 1/shape)
    mean_delay = param2 * tgamma(1 + 1/param1);
  }
}