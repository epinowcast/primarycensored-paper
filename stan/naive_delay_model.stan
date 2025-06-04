// Naive delay model that ignores censoring and truncation
// Treats observed censored delays as if they were true delays
// Uses same structure and priors as primarycensored for fair comparison

data {
  int<lower=0> N;                               // Number of observations
  vector<lower=0>[N] delay_observed;            // Observed (censored) delays
  int<lower=1,upper=2> dist_id;                 // 1 = lognormal, 2 = gamma (matches primarycensored)
  
  // primarycensored-style bounds and priors system
  int<lower=0> n_params;                        // Number of distribution parameters (always 2)
  vector[n_params] param_lower_bounds;          // Lower bounds for parameters
  vector[n_params] param_upper_bounds;          // Upper bounds for parameters
  vector[n_params] prior_location;              // Prior location parameters
  vector[n_params] prior_scale;                 // Prior scale parameters
}

parameters {
  // Use primarycensored-style flexible bounds system
  vector<lower=param_lower_bounds, upper=param_upper_bounds>[n_params] params;
}

transformed parameters {
  // Extract individual parameters for readability
  real param1 = params[1];  // shape (gamma) or meanlog (lognormal)
  real param2 = params[2];  // scale (gamma) or sdlog (lognormal)
}

model {
  // Use primarycensored-style consistent normal priors for all parameters
  for (i in 1:n_params) {
    params[i] ~ normal(prior_location[i], prior_scale[i]);
  }
  
  // Likelihood - treating censored delays as true delays
  if (dist_id == 1) {
    // Lognormal distribution
    delay_observed ~ lognormal(param1, param2);
  } else if (dist_id == 2) {
    // Gamma distribution (convert scale to rate: rate = 1/scale)
    delay_observed ~ gamma(param1, 1.0 / param2);
  }
}

generated quantities {
  vector[N] log_lik;  // For model comparison
  
  for (n in 1:N) {
    if (dist_id == 1) {
      log_lik[n] = lognormal_lpdf(delay_observed[n] | param1, param2);
    } else {
      log_lik[n] = gamma_lpdf(delay_observed[n] | param1, 1.0 / param2);
    }
  }
}
