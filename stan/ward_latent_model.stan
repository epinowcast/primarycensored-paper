// Simplified Ward et al. latent variable model for double interval censored data
// Treats primary event times as latent parameters to be estimated

data {
  int<lower=1> N;                           // Number of observations
  vector[N] Y;                              // Observed delays
  array[N] real obs_times;                  // Observation times (for truncation)
  array[N] real pwindow_widths;             // Primary window widths
  array[N] real swindow_widths;             // Secondary window widths
  int<lower=1,upper=2> dist_id;             // 1 = lognormal, 2 = gamma (matches primarycensored)
  int prior_only;                           // Should the likelihood be ignored?

  // primarycensored-style bounds and priors system
  int<lower=0> n_params;                    // Number of distribution parameters (always 2)
  vector[n_params] param_lower_bounds;      // Lower bounds for parameters
  vector[n_params] param_upper_bounds;      // Upper bounds for parameters
  vector[n_params] prior_location;          // Prior location parameters
  vector[n_params] prior_scale;             // Prior scale parameters
}

parameters {
  // Use primarycensored-style flexible bounds system
  vector<lower=param_lower_bounds, upper=param_upper_bounds>[n_params] params;

  vector<lower=0, upper=1>[N] ptime_raw;    // Raw primary event times (0-1)
  vector<lower=0, upper=1>[N] stime_raw;    // Raw secondary event times (0-1)
}

transformed parameters {
  // Extract individual parameters for readability
  real param1 = params[1];  // meanlog (lognormal) or shape (gamma)
  real param2 = params[2];  // sdlog (lognormal) or scale (gamma)

  vector[N] ptime;                          // Actual primary event times
  vector[N] stime;                          // Actual secondary event times
  vector[N] delay;                          // True delays (stime - ptime)

  // Transform raw parameters to actual event times within censoring windows
  ptime = to_vector(pwindow_widths) .* ptime_raw;   // Primary times within [0, pwindow]
  stime = ptime + Y + to_vector(swindow_widths) .* stime_raw;  // Secondary times within [delay, delay + swindow]
  delay = stime - ptime;                    // True delays
}

model {
  // Use primarycensored-style consistent normal priors for all parameters
  for (i in 1:n_params) {
    params[i] ~ normal(prior_location[i], prior_scale[i]);
  }

  // Uniform priors on latent event times
  ptime_raw ~ uniform(0, 1);
  stime_raw ~ uniform(0, 1);

  // Likelihood - only if not prior_only
  if (!prior_only) {
    if (dist_id == 1) {
      // Lognormal distribution
      delay ~ lognormal(param1, param2);
    } else if (dist_id == 2) {
      // Gamma distribution (convert scale to rate: rate = 1/scale)
      delay ~ gamma(param1, 1.0 / param2);
    }

    // Truncation constraint
    for (n in 1:N) {
      if (dist_id == 1) {
        // Lognormal distribution truncation
        target += -lognormal_lcdf(obs_times[n] - ptime[n] | param1, param2);
      } else if (dist_id == 2) {
        // Gamma distribution truncation
        target += -gamma_lcdf(obs_times[n] - ptime[n] | param1, 1.0 / param2);
      }
    }
  }
}

generated quantities {
  vector[N] log_lik;  // For model comparison

  for (n in 1:N) {
    if (dist_id == 1) {
      log_lik[n] = lognormal_lpdf(delay[n] | param1, param2);
    } else {
      log_lik[n] = gamma_lpdf(delay[n] | param1, 1.0 / param2);
    }
  }
}
