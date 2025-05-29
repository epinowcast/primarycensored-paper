// Ward et al. latent variable model for double interval censored data
// Based on epidist-paper implementation with adaptations for our data structure

functions {
  real latent_delay_lpdf(vector y, vector mu, vector sigma,
                         vector pwindow, vector swindow,
                         array[] real obs_t, int dist_id) {
    int n = num_elements(y);
    vector[n] d = y - pwindow + swindow;
    vector[n] obs_time = to_vector(obs_t) - pwindow;
    
    if (dist_id == 1) {
      // Gamma distribution (convert mu, sigma to shape, rate)
      vector[n] shape = exp(mu);
      vector[n] rate = 1.0 ./ exp(sigma);
      return gamma_lpdf(d | shape, rate) - gamma_lcdf(obs_time | shape, rate);
    } else if (dist_id == 2) {
      // Lognormal distribution
      return lognormal_lpdf(d | mu, sigma) - lognormal_lcdf(obs_time | mu, sigma);
    } else {
      reject("Invalid distribution ID. Use 1 for gamma, 2 for lognormal.");
    }
  }
}

data {
  int<lower=1> N;                           // Total number of observations
  vector[N] Y;                              // Response variable (observed delays)
  array[N] real vreal1;                     // Observation times (D values)
  array[N] real vreal2;                     // Primary window widths  
  array[N] real vreal3;                     // Secondary window widths
  int<lower=1,upper=2> dist_id;             // 1 = gamma, 2 = lognormal
  int prior_only;                           // Should the likelihood be ignored?
}

parameters {
  real Intercept;                           // Intercept for mu
  real Intercept_sigma;                     // Intercept for sigma
  
  vector<lower=0, upper=1>[N] swindow_raw;  // Raw secondary window positions
  vector<lower=0, upper=1>[N] pwindow_raw;  // Raw primary window positions
}

transformed parameters {
  real lprior = 0;                          // Prior contributions to log posterior
  
  vector<lower=0>[N] pwindow;               // Actual primary window offsets
  vector<lower=0>[N] swindow;               // Actual secondary window offsets
  
  // Transform raw parameters to actual window offsets
  swindow = to_vector(vreal3) .* swindow_raw;
  pwindow = to_vector(vreal2) .* pwindow_raw;
  
  // Priors
  lprior += student_t_lpdf(Intercept | 3, 0, 2.5);
  lprior += student_t_lpdf(Intercept_sigma | 3, 0, 2.5);
}

model {
  // Uniform priors on latent positions
  swindow_raw ~ uniform(0, 1);
  pwindow_raw ~ uniform(0, 1);
  
  // Likelihood
  if (!prior_only) {
    vector[N] mu = rep_vector(Intercept, N);
    vector[N] sigma = exp(rep_vector(Intercept_sigma, N));
    
    target += latent_delay_lpdf(Y | mu, sigma, pwindow, swindow, vreal1, dist_id);
  }
  
  // Add priors
  target += lprior;
}

generated quantities {
  real param1;                              // Shape/meanlog parameter
  real param2;                              // Scale/sdlog parameter
  vector[N] log_lik;                        // For model comparison
  
  // Convert parameters to standard form
  if (dist_id == 1) {
    // Gamma: shape and scale
    param1 = exp(Intercept);                // shape
    param2 = exp(Intercept_sigma);          // scale
  } else if (dist_id == 2) {
    // Lognormal: meanlog and sdlog
    param1 = Intercept;                     // meanlog
    param2 = exp(Intercept_sigma);          // sdlog
  }
  
  // Calculate pointwise log-likelihood
  {
    vector[N] mu = rep_vector(Intercept, N);
    vector[N] sigma = exp(rep_vector(Intercept_sigma, N));
    vector[N] d = Y - pwindow + swindow;
    vector[N] obs_time = to_vector(vreal1) - pwindow;
    
    for (n in 1:N) {
      if (dist_id == 1) {
        real shape = exp(mu[n]);
        real rate = 1.0 / exp(sigma[n]);
        log_lik[n] = gamma_lpdf(d[n] | shape, rate) - gamma_lcdf(obs_time[n] | shape, rate);
      } else if (dist_id == 2) {
        log_lik[n] = lognormal_lpdf(d[n] | mu[n], sigma[n]) - lognormal_lcdf(obs_time[n] | mu[n], sigma[n]);
      }
    }
  }
}