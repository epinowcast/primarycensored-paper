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
  real param1;                              // shape (gamma, >0) or meanlog (lognormal, any real)
  real<lower=0> param2;                     // scale (gamma) or sdlog (lognormal)
  
  vector<lower=0, upper=1>[N] ptime_raw;    // Raw primary event times (0-1)
  vector<lower=0, upper=1>[N] stime_raw;    // Raw secondary event times (0-1)
}

transformed parameters {
  vector[N] ptime;                          // Actual primary event times
  vector[N] stime;                          // Actual secondary event times
  vector[N] delay;                          // True delays (stime - ptime)
  
  // Transform raw parameters to actual event times within censoring windows
  ptime = to_vector(pwindow_widths) .* ptime_raw;   // Primary times within [0, pwindow]
  stime = ptime + Y + to_vector(swindow_widths) .* stime_raw;  // Secondary times within [delay, delay + swindow]
  delay = stime - ptime;                    // True delays
}

model {
  // Priors - match naive model exactly for consistency
  if (dist_id == 1) {
    // Gamma distribution priors - reject if param1 <= 0
    if (param1 <= 0) reject("param1 must be positive for gamma distribution");
    param1 ~ gamma(2, 1);  // shape
    param2 ~ gamma(2, 1);  // scale
  } else if (dist_id == 2) {
    // Lognormal distribution priors
    param1 ~ normal(1.5, 1);  // meanlog
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
      if (is_inf(obs_times[n]) == 0) {  // If observation time is finite
        target += -log_diff_exp(0, gamma_lcdf(obs_times[n] - ptime[n] | param1, param2));
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