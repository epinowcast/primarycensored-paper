// Simplified Ward et al. latent variable model for double interval censored data
// Treats primary event times as latent parameters to be estimated

data {
  int<lower=1> N;                           // Number of observations
  vector[N] Y;                              // Observed delays
  array[N] real obs_times;                  // Observation times (for truncation)
  array[N] real pwindow_widths;             // Primary window widths  
  array[N] real swindow_widths;             // Secondary window widths
  int<lower=1,upper=2> dist_id;             // 1 = gamma, 2 = lognormal
  int prior_only;                           // Should the likelihood be ignored?
}

parameters {
  real param1_raw;                          // Unconstrained parameter for transformation
  real<lower=0> param2;                     // scale (gamma) or sdlog (lognormal)
  
  vector<lower=0, upper=1>[N] ptime_raw;    // Raw primary event times (0-1)
  vector<lower=0, upper=1>[N] stime_raw;    // Raw secondary event times (0-1)
}

transformed parameters {
  real param1;                              // Transformed param1 based on distribution
  vector[N] ptime;                          // Actual primary event times
  vector[N] stime;                          // Actual secondary event times
  vector[N] delay;                          // True delays (stime - ptime)
  
  // Transform param1 based on distribution type
  if (dist_id == 1) {
    // Gamma: param1 must be positive (shape parameter)
    param1 = exp(param1_raw);
  } else {
    // Lognormal: param1 can be any real (meanlog parameter)  
    param1 = param1_raw;
  }
  
  // Transform raw parameters to actual event times within censoring windows
  ptime = to_vector(pwindow_widths) .* ptime_raw;   // Primary times within [0, pwindow]
  stime = ptime + Y + to_vector(swindow_widths) .* stime_raw;  // Secondary times within [delay, delay + swindow]
  delay = stime - ptime;                    // True delays
}

model {
  // Priors - match naive model exactly for consistency
  if (dist_id == 1) {
    // Gamma distribution priors
    // Note: param1_raw gets exp() transform, so prior on log(shape)
    param1_raw ~ normal(log(2), 1);  // log(shape) - implies exp(param1_raw) ~ lognormal(log(2), 1)
    param2 ~ gamma(2, 1);  // scale
  } else if (dist_id == 2) {
    // Lognormal distribution priors
    param1_raw ~ normal(1.5, 1);  // meanlog (no transformation needed)
    param2 ~ gamma(2, 1);     // sdlog
  }
  
  // Uniform priors on latent event times
  ptime_raw ~ uniform(0, 1);
  stime_raw ~ uniform(0, 1);
  
  // Likelihood - only if not prior_only
  if (!prior_only) {
    if (dist_id == 1) {
      // Gamma distribution
      delay ~ gamma(param1, param2);
    } else if (dist_id == 2) {
      // Lognormal distribution
      delay ~ lognormal(param1, param2);
    }
    
    // Truncation constraint if finite observation time
    for (n in 1:N) {
      if (obs_times[n] < 1e5) {  // If observation time is effectively finite
        if (dist_id == 1) {
          // Gamma distribution truncation
          target += -gamma_lcdf(obs_times[n] - ptime[n] | param1, param2);
        } else if (dist_id == 2) {
          // Lognormal distribution truncation
          target += -lognormal_lcdf(obs_times[n] - ptime[n] | param1, param2);
        }
      }
    }
  }
}

generated quantities {
  vector[N] log_lik;  // For model comparison
  
  for (n in 1:N) {
    if (dist_id == 1) {
      log_lik[n] = gamma_lpdf(delay[n] | param1, param2);
    } else {
      log_lik[n] = lognormal_lpdf(delay[n] | param1, param2);
    }
  }
}
