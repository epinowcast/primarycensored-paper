# PR Plan: Implement Data Preparation targets for analysis pipeline #24

## Issue Summary

This PR implements the Data Preparation section of the targets pipeline as defined in _targets.Rmd. The tasks include:

1. **Define distributions target** - gamma, lognormal, and burr distributions with mean = 5 days
2. **Define truncation_scenarios target** - none, moderate (10-day), and severe (5-day) truncation
3. **Define censoring_scenarios target** - daily, medium (2-day), and weekly (7-day) censoring patterns
4. **Create scenario_grid target** - full factorial design combining all scenarios (27 total)
5. **Implement ebola_data target** - load Sierra Leone Ebola data locally
6. **Define observation_windows target** - four 60-day windows for case study analysis

## Status Summary

PR Status: ✅ Refactoring Complete  
All refactoring tasks implemented and tested successfully.

### Final Implementation Status:
- ✅ All 27 scenarios correctly structured and working
- ✅ Proper external mapping using pattern = map() 
- ✅ Runtime measurement per scenario using tictoc
- ✅ Split Ebola data targets for better modularity
- ✅ Clean target structure following best practices
- ✅ All targets tested and functioning correctly

### Recently Completed:
- ✅ Fixed all data preparation targets in _targets.Rmd
- ✅ Used tar_simple = TRUE for simple data frame targets
- ✅ Converted scenario_list to return data frame directly instead of split list
- ✅ Fixed weekly censoring to 7 days (was incorrectly 4)
- ✅ Fixed rprimarycensored usage with proper rprimary_args structure
- ✅ Fixed library() calls - moved to globals or removed from inside targets
- ✅ Successfully tested key targets: ebola_data, scenario_list, simulated_data
- ✅ All 27 simulated_data branches completed successfully

### Current Task:
- ✅ Fixed pmf_comparison target - removed library() call and fixed parameter passing 
- ✅ Fixed runtime_comparison target - removed library() call and fixed parameter passing
- ✅ Fixed weekly censoring back to 7 days (was reverted to 4)
- ✅ Fixed truncation scenarios back to relative_obs_time (was reverted to max_delay)
- ✅ Fixed scenario_grid to use globals (simulation_n, base_seed)
- ✅ Tested all basic data frame targets successfully 
- ✅ Added parameter names to distributions target (param1_name, param2_name)
- ✅ Created analytical_pmf target using stored dist_params from distributions
- ✅ Restructured pmf_comparison to use analytical_pmf and monte_carlo_pmf targets
- ✅ Added runtime measurement using tictoc to simulated_data, monte_carlo_pmf, analytical_pmf, pmf_comparison
- ✅ Removed standalone runtime_comparison target

### Implementation Approach:
1. Split pmf_comparison into multiple targets that operate over existing scenarios
2. Add runtime recording targets that capture computation time as side effects
3. Test each change incrementally to ensure everything works
4. Pause after each step to verify functionality

### Next Steps Plan:
1. ✅ Commit current improvements (parameterization and fixes)
2. ✅ Check primarycensored vignette for multi-scenario PMF comparison approach  
3. ✅ Restructure PMF validation targets:
   - ✅ **monte_carlo_pmf**: Now maps over each scenario externally - stores runtime per scenario
   - ✅ **analytical_pmf**: Now maps over scenarios externally - stores runtime per scenario  
   - ✅ **pmf_comparison**: Removed - just visualize instead
4. ✅ Add runtime measurement using tictoc package in simulation and PMF targets
5. ✅ Simplify render task with optional customization
6. ✅ Remove standalone runtime_comparison target (integrate timing into other targets)
7. ✅ Test each change with task commands - all 27 scenarios working
8. ✅ Final commit and PR push

### Current Refactoring Tasks:
1. ✅ **ebola_data**: Split into multiple targets (ebola_data_raw, ebola_data) with tar_simple = TRUE
2. ✅ **scenario_grid**: Made this a simple target with tar_simple = TRUE  
3. ✅ **scenario_list**: Renamed to just "scenarios"
4. ✅ **monte_carlo_pmf**: Fixed to use external pattern mapping over monte_carlo_data (proper joining approach working)
5. ✅ **analytical_pmf**: Fixed variable naming and truncation constraints (properly handles swindow adjustment)
6. ✅ **numerical_pmf**: Re-added numerical PMF target (auto-selects numerical integration when needed)
7. ✅ **pmf_section**: Combined analytical and numerical PMF results in structured dataframe
8. ✅ **simple_targets**: Confirmed existing tar_simple = TRUE usage is correct in _targets.Rmd; modular targets in .R files don't use this syntax
9. ✅ **model_fits**: Current approach with bind_rows() is optimal for dynamic branching targets (tar_combine not appropriate)
10. ✅ **ebola_case_study**: Created ebola_case_study_scenarios and ebola_case_study_data targets with proper real-time vs retrospective filtering

### Summary of Key Fixes:
1. **Weekly censoring**: Fixed back to 7 days (was reverted to 4)
2. **Truncation scenarios**: Fixed back to relative_obs_time (was reverted to max_delay) 
3. **Parameter passing**: Fixed dprimarycensored calls to use direct parameters instead of dist_params
4. **Library calls**: Removed from runtime_comparison and pmf_comparison targets
5. **Scenario grid**: Fixed to use global variables (simulation_n, base_seed)
6. **Code duplication reduction**: Added parameter names to distributions data frame and used do.call() for dynamic parameter passing
7. **Parameterized configuration**: Made _targets.Rmd parametrized with sample_sizes, growth_rate, simulation_n, and base_seed in YAML header
8. **Documentation and workflows**: Added comprehensive docs in README, DEVELOPMENT.md, and _targets.Rmd for parameter customization
9. **Task automation**: Added render-custom task for easy parameter overrides during development and testing
10. **Comprehensive testing**: All 36 targets working correctly together

## Key Notes

- Use primarycensored package functions where possible
- Maintain compatibility with _targets.Rmd structure
- Ensure alignment with main.qmd methods section
- Limit code duplication through modular design
