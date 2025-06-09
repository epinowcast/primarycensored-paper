# PR Plan for Issue #52: Ebola case study data format issue

## Issue Summary

The Ebola case study data in the pipeline is still in date format and has not been properly transformed into delay observations that can be fitted by the delay distribution models. This prevents the Ebola case study from running correctly.

## Acceptance Criteria

1. Transform Ebola date data into numeric delay format required by fitting methods
2. Create columns: `delay_observed`, `prim_cens_lower`, `prim_cens_upper`, `sec_cens_lower`, `sec_cens_upper`, `relative_obs_time`
3. Ensure transformation accounts for:
   - Right truncation due to study end date
   - Appropriate censoring windows based on Sierra Leone data collection methodology
   - Handling of missing or invalid dates
   - Consistent column naming with simulation data format
4. Create a new target that summarises the data in each window of the ebola data (number of observations, mean observed delay, etc.)
5. Ensure the Ebola case study can run successfully in the pipeline

## Implementation Approach

1. First examine the raw Ebola data format to understand the structure ✓
2. Create a data processing function to transform dates to delays
3. Add new target `ebola_delay_data` after `ebola_case_study_data` to transform dates to numeric delays
4. Add new target `ebola_data_summary` to create metadata summaries for each window
5. Update `fitting_grid` to use the transformed `ebola_delay_data` instead of raw case study data
6. Write tests to validate the transformation

## Files to Modify/Create

### Files to examine:
- `data/raw/ebola_sierra_leone_2014_2016.csv` - Check raw data format ✓
- `_targets.Rmd` - Current Ebola case study target definitions ✓
- `R/create_fitting_grid.R` - How Ebola data is integrated into fitting grid ✓

### Files likely to modify:
- `_targets.Rmd` - Add two new targets after ebola_case_study_data target (around line 503):
  - `ebola_delay_data` - Transform dates to delays with censoring columns
  - `ebola_data_summary` - Create summary statistics for each window
- `R/utils.R` - Add functions:
  - `transform_ebola_to_delays()` - Convert dates to delay format
  - `summarise_ebola_windows()` - Create summary statistics
- `R/create_fitting_grid.R` - Update to use `ebola_delay_data` instead of `ebola_case_study_data`

### Files to create:
- `tests/testthat/test-ebola-data-transformation.R` - Tests for new functions

## Context Discovered

### Current Data Flow:
1. Raw CSV → `ebola_data_raw` target (dates as strings)
2. `ebola_data` target → Clean dates, filter invalid records
3. `ebola_case_study_data` → Split into 4 windows × 2 analysis types = 8 datasets
4. `fitting_grid` → Combines with simulation data **BUT MISSING DELAY TRANSFORMATION**

### Key Finding:
- The pipeline processes dates but never creates the required delay columns
- Sample date - symptom onset date = delay
- Need to add censoring windows based on daily reporting assumption
- Need to calculate relative observation time for truncation

## Testing Strategy

1. Unit tests for data transformation functions:
   - Test delay calculation from dates
   - Test censoring window assignment
   - Test handling of missing/invalid dates
   - Test truncation time calculation

2. Integration tests:
   - Verify transformed data format matches expected structure
   - Ensure fitting methods can use the transformed data
   - Check pipeline runs successfully with Ebola data

3. Data validation:
   - Verify delay values are reasonable (non-negative, within expected range)
   - Check censoring windows are properly bounded
   - Ensure no data is lost in transformation

## Potential Edge Cases

1. Missing onset or report dates
2. Negative delays (report before onset)
3. Dates outside the study period
4. Different date formats in the raw data
5. Handling of exact date matching vs. interval censoring
6. Study end date determination for truncation

## Data Transformation Logic

### Transform to Delays Function
```r
transform_ebola_to_delays <- function(case_study_row) {
  # Extract the data frame and window end day from the row
  ebola_data <- case_study_row$data[[1]]
  window_end_day <- case_study_row$end_day
  
  # Calculate window end date (days since start of outbreak)
  outbreak_start <- min(ebola_data$symptom_onset_date, na.rm = TRUE)
  window_end_date <- outbreak_start + window_end_day
  
  ebola_data |>
    mutate(
      # Calculate delay from symptom onset to sample test
      delay_observed = as.numeric(sample_date - symptom_onset_date),
      # Primary event (onset) censoring - assuming daily reporting
      prim_cens_lower = 0,
      prim_cens_upper = 1,
      # Secondary event (sample) censoring - assuming daily reporting
      sec_cens_lower = delay_observed,
      sec_cens_upper = delay_observed + 1,
      # Observation time for truncation (time from onset to window end)
      relative_obs_time = as.numeric(window_end_date - symptom_onset_date)
    ) |>
    select(-symptom_onset_date, -sample_date)  # Remove date columns
}
```

### Summary Statistics Function
```r
summarise_ebola_windows <- function(ebola_delay_data) {
  ebola_delay_data |>
    group_by(window_id, analysis_type) |>
    summarise(
      n_observations = n(),
      mean_delay = mean(delay_observed),
      median_delay = median(delay_observed),
      sd_delay = sd(delay_observed),
      min_delay = min(delay_observed),
      max_delay = max(delay_observed),
      mean_relative_obs_time = mean(relative_obs_time),
      .groups = "drop"
    )
}
```

## Final Plan Review

### Confirmed Implementation Steps:
1. ✓ Create `transform_ebola_to_delays()` function in R/utils.R
2. ✓ Create `summarise_ebola_windows()` function in R/utils.R  
3. ✓ Add `ebola_delay_data` target in _targets.Rmd after `ebola_case_study_data`
4. ✓ Add `ebola_data_summary` target in _targets.Rmd
5. ✓ Update `fitting_grid` in R/create_fitting_grid.R to use `ebola_delay_data`
6. ✓ Write comprehensive tests for both functions

### Key Design Decisions:
- Use daily censoring (1 day windows) based on typical epidemiological reporting
- Calculate truncation relative to each analysis window end
- Preserve all metadata from ebola_case_study_data
- Remove date columns after transformation to match simulation data format