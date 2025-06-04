// Naive delay model that ignores censoring and truncation
// Treats observed censored delays as if they were true delays
// Uses same priors as primarycensored for fair comparison

data {
  int<lower=0> N;                    // Number of observations
  vector<lower=0>[N] delay_observed; // Observed (censored) delays
  int<lower=1,upper=2> dist_id;      // 1 = lognormal, 2 = gamma (matches primarycensored)
}

parameters {
  real param1;              // shape (gamma, >0) or meanlog (lognormal, any real)
  real<lower=0> param2;     // scale (gamma, >0) or sdlog (lognormal, >0)
}

model {
  // Priors matching primarycensored for fair comparison
  if (dist_id == 1) {
    // Lognormal distribution priors (same as primarycensored)
    param1 ~ normal(1.5, 1);  // meanlog: normal(1.5, 1)
    param2 ~ gamma(2, 1);     // sdlog: gamma(2, 1)
  } else if (dist_id == 2) {
    // Gamma distribution priors (same as primarycensored)
    if (param1 <= 0) reject("param1 must be positive for gamma distribution");
    param1 ~ gamma(2, 1);  // shape: gamma(2, 1)
    param2 ~ gamma(2, 1);  // scale: gamma(2, 1)
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
