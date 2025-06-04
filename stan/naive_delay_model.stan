// Naive delay model that ignores censoring and truncation
// Treats observed censored delays as if they were true delays
// Uses same priors as primarycensored for fair comparison

data {
  int<lower=0> N;                    // Number of observations
  vector<lower=0>[N] delay_observed; // Observed (censored) delays
  int<lower=1,upper=2> dist_id;      // 1 = lognormal, 2 = gamma (matches primarycensored)
  
  // Prior parameters (passed as data for consistency with primarycensored)
  int<lower=0> n_params;             // Number of distribution parameters (always 2)
  vector[n_params] prior_location;   // Prior location parameters
  vector[n_params] prior_scale;      // Prior scale parameters
}

parameters {
  real param1;              // shape (gamma, >0) or meanlog (lognormal, any real)
  real<lower=0> param2;     // scale (gamma, >0) or sdlog (lognormal, >0)
}

model {
  // Priors using data-specified parameters matching primarycensored framework
  if (dist_id == 1) {
    // Lognormal distribution priors
    param1 ~ normal(prior_location[1], prior_scale[1]);  // meanlog
    param2 ~ gamma(prior_location[2], prior_scale[2]);   // sdlog  
  } else if (dist_id == 2) {
    // Gamma distribution priors
    if (param1 <= 0) reject("param1 must be positive for gamma distribution");
    param1 ~ gamma(prior_location[1], prior_scale[1]);   // shape
    param2 ~ gamma(prior_location[2], prior_scale[2]);   // scale
  }
  
  // Likelihood - treating censored delays as true delays
  if (dist_id == 1) {
    // Lognormal distribution
    delay_observed ~ lognormal(param1, param2);
  } else if (dist_id == 2) {
    // Gamma distribution
    delay_observed ~ gamma(param1, param2);
  }
}

generated quantities {
  vector[N] log_lik;  // For model comparison
  
  for (n in 1:N) {
    if (dist_id == 1) {
      log_lik[n] = lognormal_lpdf(delay_observed[n] | param1, param2);
    } else {
      log_lik[n] = gamma_lpdf(delay_observed[n] | param1, param2);
    }
  }
}
