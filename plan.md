# PR Plan: Implement Data Preparation targets for analysis pipeline #24

## Current Status
We are in the middle of a PR for this issue and have made significant progress. We now need to fix several issues and make improvements to the pipeline.

## Detailed Implementation Guide

### 1. Fix Pipeline Error - Upper Truncation Point Issue (HIGH PRIORITY)
**Problem**: Upper truncation point is greater than D. It is 7 and D is 5.
**Root Cause**: When calculating PMF, we're asking for values where x + swindow > D, which violates the truncation constraint.
**Solution**: In _targets.Rmd, modify the PMF calculation targets to ensure we only evaluate delays where delay + swindow <= D.

**Implementation Steps**:
1. Locate the PMF calculation sections in _targets.Rmd (analytical_pmf and numerical_pmf targets)
2. Find where `delays` are calculated
3. Modify to: `delays <- 0:min(max_delay_to_evaluate, pmax(0, D - swindow))`
4. This ensures we never evaluate delays that would exceed the truncation point

### 2. Audit and Clean R Functions (MEDIUM PRIORITY)
**Task**: Check R folder for unused functions and remove them.

**Implementation Steps**:
1. List all functions defined in R/*.R files
2. Search _targets.Rmd for usage of each function
3. Remove any functions not referenced in the pipeline
4. Ensure all remaining functions are properly documented

### 3. Verify Censoring Windows Alignment (HIGH PRIORITY)
**Task**: Ensure censoring windows in the pipeline match specifications in paper/main.qmd.

**Implementation Steps**:
1. Open paper/main.qmd and find the censoring window specifications
2. Compare with the censoring_scenarios definition in _targets.Rmd
3. Update _targets.Rmd if there are any discrepancies
4. Document the alignment in comments

### 4. Add tictoc Package (MEDIUM PRIORITY)
**Task**: Add tictoc to install_packages.R and update renv.

**Implementation Steps**:
1. Add `"tictoc"` to the packages list in scripts/install_packages.R
2. Run `task install` to install the package
3. Run `renv::snapshot()` to update renv.lock
4. Verify tictoc is available in the environment

### 5. Refactor Simulated Data Runtime Storage (MEDIUM PRIORITY)
**Task**: Store runtime in the data frame instead of as an attribute.

**Implementation Steps**:
1. In _targets.Rmd, find the simulated_data target
2. Modify to use `tic()` before simulation and `toc()` after
3. Add a `runtime` column to the resulting tibble with the elapsed time
4. Remove any attribute-based runtime storage

### 6. Verify monte_carlo_pmf Implementation (HIGH PRIORITY)
**Task**: Ensure PMF creation matches primarycensored package vignettes.

**Implementation Steps**:
1. Check primarycensored package vignettes for correct PMF creation
2. Compare with monte_carlo_pmf target in _targets.Rmd
3. Update implementation to match vignette approach if needed
4. Add validation tests if necessary

### 7. Refactor monte_carlo_pmf Runtime Storage (MEDIUM PRIORITY)
**Task**: Store runtime in the data frame instead of as an attribute.

**Implementation Steps**:
1. In _targets.Rmd, find the monte_carlo_pmf target
2. Wrap the Monte Carlo simulation with tic/toc
3. Add runtime as a column in the resulting tibble
4. Remove attribute-based storage

### 8. Update Model Fits Mapping (HIGH PRIORITY)
**Task**: Map over both sample size and scenario for all model fits.

**Implementation Steps**:
1. Locate fit_naive, fit_primarycensored, and fit_ward targets in _targets.Rmd
2. Modify each to use `cross_df()` or similar to create combinations of scenarios and sample sizes
3. Update the mapping functions to handle both parameters
4. Ensure results include both scenario and sample size identifiers

### 9. Create estimate_delay_model Function (MEDIUM PRIORITY)
**Task**: Create a reusable function for naive model fitting.

**Implementation Steps**:
1. Create `estimate_naive_delay_model()` function in R/models.R
2. Move verbose fitting code from fit_naive target into this function
3. Update fit_naive target to use the new function
4. Apply similar refactoring to other model fits if applicable

### 10. Rename all_model_fits Target (LOW PRIORITY)
**Task**: Rename to simulated_model_fits for clarity.

**Implementation Steps**:
1. In _targets.Rmd, find all references to `all_model_fits`
2. Rename to `simulated_model_fits`
3. Update any downstream targets that depend on this
4. Update documentation and comments

### 11. Add Runtime Tracking to Model Fits (MEDIUM PRIORITY)
**Task**: Track runtime (excluding compilation) for each model fit.

**Implementation Steps**:
1. For each fit target, add tic() after model compilation
2. Add toc() after fitting completes
3. Store runtime in the results tibble
4. Ensure compilation time is excluded from measurement

### 12. Replace data.frame with tibble (LOW PRIORITY)
**Task**: Use tibble throughout the codebase for consistency.

**Implementation Steps**:
1. Search for all `data.frame()` calls in _targets.Rmd
2. Replace with `tibble()` or `as_tibble()`
3. Ensure tidyverse is loaded where needed
4. Test that all targets still work correctly

## Testing Strategy

After each task:
1. Run `task render` to update _targets.R from _targets.Rmd
2. Run `task run` to test the pipeline
3. If errors occur, use `targets::tar_make(target_name)` to debug specific targets
4. Commit changes after each successful task completion

## Key Principles
- All changes must be made in _targets.Rmd, not in the generated files
- Use primarycensored package functions where possible
- Maintain compatibility with existing structure
- Test incrementally - one task at a time
- Document changes clearly in code comments
