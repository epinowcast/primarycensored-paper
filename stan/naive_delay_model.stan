// Naive delay model that ignores censoring and truncation
// Treats observed censored delays as if they were true delays

data {
  int<lower=0> N;                    // Number of observations
  vector<lower=0>[N] delay_observed; // Observed (censored) delays
  int<lower=1,upper=2> dist_id;      // 1 = gamma, 2 = lognormal
}

parameters {
  real<lower=0> param1;  // shape (gamma) or meanlog (lognormal)
  real<lower=0> param2;  // rate (gamma) or sdlog (lognormal)
}

model {
  // Weakly informative priors
  param1 ~ gamma(2, 1);
  param2 ~ gamma(2, 1);
  
  // Likelihood - treating censored delays as true delays
  if (dist_id == 1) {
    // Gamma distribution
    delay_observed ~ gamma(param1, param2);
  } else if (dist_id == 2) {
    // Lognormal distribution
    delay_observed ~ lognormal(param1, param2);
  }
}

generated quantities {
  vector[N] log_lik;  // For model comparison
  
  for (n in 1:N) {
    if (dist_id == 1) {
      log_lik[n] = gamma_lpdf(delay_observed[n] | param1, param2);
    } else {
      log_lik[n] = lognormal_lpdf(delay_observed[n] | param1, param2);
    }
  }
}
