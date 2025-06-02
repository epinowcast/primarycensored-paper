tar_target(
  ebola_model_fits,
  {
    # Extract the actual data from the list column
    case_data <- ebola_case_study_data$data[[1]]
    
    # Check if we have enough cases for fitting
    if (ebola_case_study_data$n_cases < 10) {
      return(data.frame(
        window_id = ebola_case_study_data$window_id,
        analysis_type = ebola_case_study_data$analysis_type,
        window_label = ebola_case_study_data$window_label,
        n_cases = ebola_case_study_data$n_cases,
        method = c("primarycensored", "naive", "ward"),
        param1_est = NA_real_,
        param1_se = NA_real_,
        param2_est = NA_real_,
        param2_se = NA_real_,
        runtime_seconds = NA_real_
      ))
    }
    
    # Calculate delays (sample date - symptom onset date)
    case_data$delay_observed <- as.numeric(case_data$sample_date - case_data$symptom_onset_date)
    
    # Set up censoring windows (assuming 1-day intervals as per case study)
    case_data$prim_cens_lower <- 0
    case_data$prim_cens_upper <- 1
    case_data$sec_cens_lower <- case_data$delay_observed
    case_data$sec_cens_upper <- case_data$delay_observed + 1
    
    # Set truncation based on analysis type
    if (ebola_case_study_data$analysis_type == "real_time") {
      obs_time <- ebola_case_study_data$end_day - ebola_case_study_data$start_day
    } else {
      obs_time <- Inf  # No truncation for retrospective
    }
    case_data$relative_obs_time <- obs_time
    
    results <- list()
    
    # Fit primarycensored model
    tictoc::tic("primarycensored")
    tryCatch({
      delay_data <- data.frame(
        delay = case_data$delay_observed,
        delay_upper = case_data$sec_cens_upper,
        n = 1,
        pwindow = 1,
        relative_obs_time = obs_time
      )
      
      stan_data <- primarycensored::pcd_as_stan_data(
        delay_data,
        dist_id = 2L,  # Gamma distribution
        primary_id = 1L,  # Uniform primary
        param_bounds = list(lower = c(0.01, 0.01), upper = c(50, 50)),
        primary_param_bounds = list(lower = numeric(0), upper = numeric(0)),
        priors = list(location = c(2, 2), scale = c(1, 1)),
        primary_priors = list(location = numeric(0), scale = numeric(0)),
        compute_log_lik = TRUE
      )
      
      fit <- do.call(compile_primarycensored_model$sample, c(
        list(data = stan_data), stan_settings
      ))
      
      param_summary <- posterior::summarise_draws(fit$draws(c("param1", "param2")))
      runtime_pc <- tictoc::toc(quiet = TRUE)
      
      results$primarycensored <- data.frame(
        param1_est = param_summary$mean[1],
        param1_se = param_summary$sd[1],
        param2_est = param_summary$mean[2],
        param2_se = param_summary$sd[2],
        runtime_seconds = runtime_pc$toc - runtime_pc$tic
      )
    }, error = function(e) {
      runtime_pc <- tictoc::toc(quiet = TRUE)
      results$primarycensored <<- data.frame(
        param1_est = NA_real_, param1_se = NA_real_,
        param2_est = NA_real_, param2_se = NA_real_,
        runtime_seconds = runtime_pc$toc - runtime_pc$tic
      )
    })
    
    # Fit naive model (simplified - just use MLE)
    tictoc::tic("naive")
    tryCatch({
      fit_gamma <- fitdistrplus::fitdist(case_data$delay_observed, "gamma")
      runtime_naive <- tictoc::toc(quiet = TRUE)
      
      results$naive <- data.frame(
        param1_est = fit_gamma$estimate["shape"],
        param1_se = fit_gamma$sd["shape"],
        param2_est = fit_gamma$estimate["rate"],  # Convert to scale later if needed
        param2_se = fit_gamma$sd["rate"],
        runtime_seconds = runtime_naive$toc - runtime_naive$tic
      )
    }, error = function(e) {
      runtime_naive <- tictoc::toc(quiet = TRUE)
      results$naive <<- data.frame(
        param1_est = NA_real_, param1_se = NA_real_,
        param2_est = NA_real_, param2_se = NA_real_,
        runtime_seconds = runtime_naive$toc - runtime_naive$tic
      )
    })
    
    # Ward model (simplified - return placeholder for now as it requires complex implementation)
    results$ward <- data.frame(
      param1_est = NA_real_, param1_se = NA_real_,
      param2_est = NA_real_, param2_se = NA_real_,
      runtime_seconds = NA_real_
    )
    
    # Combine all results
    bind_results <- dplyr::bind_rows(results, .id = "method")
    bind_results$window_id <- ebola_case_study_data$window_id
    bind_results$analysis_type <- ebola_case_study_data$analysis_type
    bind_results$window_label <- ebola_case_study_data$window_label
    bind_results$n_cases <- ebola_case_study_data$n_cases
    
    bind_results
  },
  pattern = map(ebola_case_study_data)
)
