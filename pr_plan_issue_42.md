# PR Plan for Issue #42: Review and validate naive model implementation

## Issue Summary
As part of PR #40, we need to review the naive model implementation to ensure it serves as a proper baseline comparison. The naive model should correctly ignore censoring and truncation, demonstrating the impact of not accounting for these factors in epidemiological delay distribution estimation.

## Key Requirements (Based on User Feedback)
- **No duplicate code** between naive and primarycensored Stan models
- **Identical prior settings** in and out of models (no hard-coded priors in naive model)
- **Shared framework** with primarycensored but simpler likelihood
- **Proper validation** with parameter recovery tests
- **Lint before PR**

## Acceptance Criteria
- [x] Naive model correctly ignores censoring/truncation
- [x] Parameter recovery works on uncensored data
- [x] Stan model is mathematically sound
- [x] Tests demonstrate expected behaviour and limitations
- [x] Documentation clearly explains the naive approach and its limitations
- [x] NO duplicate code between models
- [x] ALL prior settings are shared and consistent

## Current Issues Identified - RESOLVED ✅
1. **Hard-coded priors in naive Stan model** - ✅ FIXED: Priors now passed as data via `prior_location[]` and `prior_scale[]`
2. **Duplicate primary distribution parameter code** - ✅ FIXED: Extracted to `get_shared_primary_prior_settings()` and `prepare_shared_model_inputs()`
3. **Inconsistent prior mechanism** - ✅ FIXED: Naive model now uses same data-driven prior approach as primarycensored
4. **Limited prior types** - ✅ FIXED: Naive model supports same gamma/normal priors as configured
5. **Incomplete framework sharing** - ✅ FIXED: Both models now use same data prep and prior configuration

## Key Findings from primarycensored Model
- **All priors passed as data**: `prior_location[]`, `prior_scale[]`, `primary_prior_location[]`, `primary_prior_scale[]`
- **All priors are normal distributions**: `params[i] ~ normal(prior_location[i], prior_scale[i])`
- **Accessed via**: `primarycensored::pcd_cmdstan_model()`
- **Complex likelihood**: Uses `primarycensored_lpmf()` with interval censoring vs naive PDF

## Action Plan
1. Read and understand primarycensored Stan model structure
2. Eliminate all duplicate code between naive and primarycensored
3. Ensure naive Stan model receives priors as data (not hard-coded)
4. Extract ALL shared code into utility functions
5. Test using targets framework
6. Comprehensive review and validation
7. Lint before PR

## Files Needing Review/Changes
- `/stan/naive_delay_model.stan` - eliminate hard-coded priors
- `/R/fit.R` - remove duplicate primary distribution code
- `/R/utils.R` - extract more shared functions
- `/tests/testthat/test-fit-functions.R` - ensure tests are comprehensive
- `/_targets.Rmd` - test integration