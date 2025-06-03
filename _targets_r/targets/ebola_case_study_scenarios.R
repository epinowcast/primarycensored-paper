tar_target(ebola_case_study_scenarios, {
  data.frame(
    analysis_type = c("real_time", "retrospective"),
    description = c("Filter LHS on onset date, RHS on sample date", "Filter both LHS and RHS on onset date")
  )
})