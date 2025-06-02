# Implementation Plan for Issue #26: Parameter Recovery Targets

## Overview
This plan details the implementation of parameter recovery targets for comparing different methods of handling double interval censored data in the primarycensored-paper analysis pipeline.

## Current Status
- PR #40 is open with initial implementation
- CodeRabbit review shows placeholders have been replaced with actual implementations
- Need to review and potentially update based on feedback
- Test mode has been partially implemented

## Phase 0: Test Mode Implementation (Priority)

### Rationale
Before implementing all four fitting methods across all scenarios, we need a lightweight test mode to:
- Quickly validate implementation correctness
- Enable rapid iteration during development
- Support automated testing in GitHub Actions
- Reduce computational burden during development

### Test Mode Parameters
Add new parameters to `_targets.Rmd` YAML header:
```yaml
params:
  test_mode: false  # Enable/disable test mode
  test_scenarios: 2  # Number of scenarios to test (subset)
  test_samples: 100  # Reduced sample size for testing
  test_chains: 2     # Minimal chains for Stan
  test_iterations: 100  # Reduced iterations for quick runs
```

### Implementation Strategy
1. **Apply Test Mode at Fitting Stage Only**:
   - Test mode should NOT affect scenario generation or Monte Carlo sampling
   - Apply test mode logic in `fitting_grid` target to subset existing data
   - Keep full scenario exploration for data generation
   
2. **Fitting Grid Creation from Monte Carlo Samples**:
   - `fitting_grid` should be created by examining what's in `monte_carlo_samples`
   - Use `tar_group_by = c(scenario_id, sample_size)` for natural grouping
   - This allows targets to iterate over groups with `pattern = map(fitting_grid)`
   - Each fitting target receives one group of data automatically
   - **Key benefit**: Can combine simulation data with Ebola case study data
   - Create a unified fitting grid that includes both:
     - Simulated scenarios from `monte_carlo_samples`
     - Real-world Ebola data with appropriate scenario metadata
   - In test mode, filter to subset of scenarios after data exists
   - Focus on one gamma and one lognormal scenario plus one Ebola scenario
   - Include both no truncation and severe truncation cases
   
3. **Reduced Computational Load**:
   - Subset to smaller sample sizes (100) from existing Monte Carlo data
   - Fewer Stan iterations (100 vs 1000) via stan_settings
   - Minimal chains (2 vs 4) via stan_settings

### Coding Standards for This Project

1. **Shared Code in Targets**:
   - Prefer creating separate targets for shared configuration (like `stan_settings`)
   - Reduces duplication and improves maintainability
   - Examples: `stan_settings`, `compile_stan_models`

2. **Extending vs Creating**:
   - Use `c()` to extend lists: `c(existing_list, new_item = value)`
   - Use dplyr to modify dataframes: `df %>% mutate()` instead of `data.frame()`
   - Less verbose and clearer intent

3. **Current Implementation Status**:
   - **Fully Implemented**: All four fitting methods (naive, ward, primarycensored, fitdistrplus)
   - **Clean Implementation**: `fit_naive`, `fit_ward` use shared functions
   - **Needs Refactoring**: `fit_primarycensored`, `fit_primarycensored_fitdistrplus` have:
     - Hardcoded if/else statements
     - data.frame() usage instead of dplyr
     - Inline configuration instead of shared targets/functions
   
4. **Conditional Logic in Targets**:
   - Test mode logic primarily in `fitting_grid` and `stan_settings`
   - `fitting_grid` should query `monte_carlo_samples` and filter results
   - Avoid test mode logic in early pipeline stages
   - Let natural targets dependencies handle the flow

### GitHub Actions Integration
Create `.github/workflows/test-parameter-recovery.yml`:
- Triggers on PR to issue-26 branch
- Uses Taskfile commands for simplicity
- Sets test_mode: true in _targets.Rmd
- Runs `task run` to execute pipeline
- Validates all four methods complete without errors
- Reports basic convergence metrics
- Total runtime target: < 10 minutes

**Simplified workflow should:**
- Use `task install` for dependency setup
- Use `task render PARAMS='test_mode=true'` for test mode
- Use `task run` to execute the pipeline
- Avoid hand-coded R scripts in workflow file

### Benefits
- Catch errors early before full runs
- Enable CI/CD for parameter recovery
- Make development iteration faster
- Provide template for other intensive analyses

## High-Level Objectives
1. Implement four distinct fitting approaches to compare their accuracy and computational efficiency
2. Create a systematic comparison framework that aligns with the paper's methodology
3. Ensure all implementations follow the patterns established in the existing pipeline

## Context from Paper (main.qmd)
- Lines 280-286: Describe parameter recovery methodology using both Bayesian and maximum likelihood approaches
- Figure 2: Shows expected parameter recovery results across different methods
- The paper emphasizes comparing bias and computational efficiency between methods

## Methods to Implement

### 1. Primary Censored Method (Our Approach)
**Purpose**: Implement the novel marginalisation approach that accounts for all censoring and truncation
**Key Features**:
- Uses analytical solutions where available (gamma, lognormal)
- Falls back to numerical integration for other distributions
- Should show unbiased parameter recovery across all scenarios

### 2. Naive Method
**Purpose**: Baseline comparison that ignores censoring and truncation
**Key Features**:
- Treats observed delays as if they were true delays
- Expected to show increasing bias with censoring width and truncation severity
- Simplest implementation, fastest runtime

### 3. Ward et al. Latent Variable Method
**Purpose**: Current best practice for comparison
**Key Features**:
- Treats primary event times as individual parameters
- Computationally intensive but statistically rigorous
- Expected similar accuracy to our method but much slower

### 4. Primary Censored with fitdistrplus
**Purpose**: Maximum likelihood estimation using our method
**Key Features**:
- Uses the fitdistrplus wrapper from primarycensored package
- Provides non-Bayesian alternative for comparison
- Should match Stan implementation results

## Implementation Strategy

### Unified Data Flow
1. Combine simulated data from `monte_carlo_samples` with Ebola case study data
2. Create a single `fitting_grid` that includes both simulation and real-world scenarios
3. Each fitting method iterates over the same unified grid
4. No need for separate simulation vs case study fitting sections
5. Results naturally aggregate into a common format for analysis

### Benefits of Unified Approach
- Single set of fitting targets handles both simulated and real data
- Consistent interface and error handling across all scenarios
- Easier to maintain and extend
- Natural comparison between simulation and real-world performance
- Simplified pipeline structure

### Key References and Resources

#### From primarycensored Package
- **Fitting with Stan vignette**: Contains example of naive model implementation
- **fitdistrplus wrapper documentation**: Shows how to use `fitdistdoublecens()`
- **Package Stan model**: Located in package installation, provides template

#### From epidist-paper
- Referenced in issue as source for Ward et al. implementation
- Should adapt their brms-like approach to simpler Stan code
- Focus on core latent variable logic without complex hierarchical structure

#### From Paper Repository
- `stan/naive_delay_model.stan`: Already implemented, needs integration
- `stan/ward_latent_model.stan`: Needs simplification and proper integration
- `R/utils.R`: Contains `estimate_naive_delay_model` function template

### Parameter Settings (from issue description)
- **Priors**: 
  - For gamma distribution: Gamma(2,1) for both shape and scale parameters
  - For lognormal distribution: 
    - meanlog (μ): Normal(1.5, 1) - centered around expected value
    - sdlog (σ): Gamma(2, 1) - positive constraint with moderate prior mass
    - Note: primarycensored package may use Normal priors internally, adjust accordingly
- **Stan settings**: 
  - 2 chains (for speed during development)
  - 1000 warmup iterations
  - 1000 sampling iterations
  - adapt_delta = 0.95
- **Convergence criteria**: R-hat < 1.01, no divergences

### Timing and Parallelization Strategy

#### Model Compilation
- **Pre-compile all Stan models** before the targets pipeline runs
- Store compiled models in a dedicated location
- Compilation time NOT included in runtime measurements
- Use `pcd_cmdstan_model()` or `cmdstan_model()` in setup phase

#### Runtime Measurement
- Start `tictoc::tic()` AFTER:
  - Data preparation
  - Model compilation
  - Any setup operations
- Measure only the actual fitting/sampling time
- Store runtime in consistent format across all methods

#### Parallelization Architecture
- **Targets level**: Each scenario runs in parallel via `pattern = map()`
- **Stan level**: Single core per fit to avoid resource contention
- **Configuration**:
  ```r
  # In each fitting function
  parallel_chains = 1  # Run chains sequentially
  chains = 2          # Minimal for development
  threads_per_chain = 1  # No within-chain parallelization
  ```

#### Resource Management
- Crew controller: `parallel::detectCores() - 1` workers
- Each worker handles one complete fit (compilation excluded)
- Memory: "transient" with garbage collection enabled
- Avoid nested parallelization (targets parallel + Stan parallel)

### Output Format
Each fitting method should return:
- Parameter estimates (param1_est, param2_est)
- Standard errors (param1_se, param2_se)
- Convergence diagnostics (for Bayesian methods)
- Log-likelihood (for model comparison)
- Runtime in seconds

## Implementation Priorities

### Phase 1: Test Infrastructure (Week 1)
1. **Add test mode parameters** to `_targets.Rmd`
2. **Create model compilation target**:
   - Compile all Stan models once
   - Store paths for reuse
   - Skip if already compiled
3. **Implement scenario subsetting** for test mode
4. **Set up timing infrastructure** with tictoc

### Phase 2: Core Implementation (Week 2)
1. **fit_naive target** (simplest to start):
   - Update naive_delay_model.stan with correct priors
   - Implement full Stan integration
   - Test with both gamma and lognormal
   - Validate timing excludes compilation

2. **fit_primarycensored target**:
   - Study primarycensored vignette implementation
   - Use package's Stan interface
   - Handle both distributions
   - Compare results with naive for validation

### Phase 3: Advanced Methods (Week 3)
3. **fit_primarycensored_fitdistrplus target**:
   - Implement MLE version for comparison
   - Use fitdistdoublecens wrapper
   - Ensure output format matches Stan versions

4. **fit_ward target**:
   - Simplify current Stan model
   - Remove brms-specific features
   - Focus on core latent variable logic
   - May need most debugging time

### Phase 4: Integration & Testing (Week 4)
5. **combine_model_fits target**:
   - Aggregate all results
   - Add convergence summaries
   - Create comparison metrics

6. **GitHub Actions workflow**:
   - Test mode CI pipeline
   - Automated validation
   - Performance benchmarks

## Quality Assurance

### Testing Strategy
- Verify each method independently with known data
- Compare results between Bayesian and MLE versions
- Check convergence diagnostics for all Stan models
- Validate against expected patterns from paper

### Performance Considerations
- Use pattern mapping for parallel execution
- Pre-sample data to avoid redundant generation
- Consider memory usage with large datasets
- Monitor Stan compilation time

## Documentation Requirements
- Update _targets.Rmd with new target descriptions
- Document any deviations from original plan
- Include references to source materials
- Add inline comments for complex logic

## Detailed Implementation Guidance

### Stan Model Adaptations

#### Naive Model Updates
- Current model in `stan/naive_delay_model.stan` needs prior updates for lognormal
- Change line with lognormal priors to use Normal(1.5, 1) for meanlog
- Ensure sdlog uses Gamma(2, 1) prior

#### Ward Model Simplification
- Remove brms-specific complexity from current implementation
- Focus on core latent variable logic
- Adapt priors to match our specifications
- Ensure parameter extraction matches our expected format

#### Primary Censored Stan Implementation
- Use primarycensored package's Stan functions
- Reference the "fitting with Stan" vignette from primarycensored
- Implement using `pcd_cmdstan_model()` and `pcd_fit()`
- Handle both gamma and lognormal distributions

### Data Preparation Patterns

#### From monte_carlo_samples
- Filter by scenario_id and sample_size
- Extract delay_observed, primary_width, secondary_width
- Handle truncation information (obs_time)
- Prepare distribution identifiers

#### Stan Data Format
- Naive model: Simple vector of delays
- Ward model: Complex structure with windows and observation times
- Primary censored: Follow package's expected format

### Integration with Existing Pipeline

#### Pattern Mapping
- Use `pattern = map(fitting_grid)` for parallel execution
- Each fit receives one scenario/sample_size combination
- Results aggregated automatically by targets

#### Error Handling
- Check for empty data before fitting
- Return NA-filled results on failure
- Log convergence issues but don't stop pipeline

## Next Steps
1. Review existing Stan models and identify necessary modifications
2. Study primarycensored package vignettes for implementation details
3. Examine epidist-paper for Ward et al. approach insights
4. Begin with fit_primarycensored as it's most straightforward
5. Iterate on each implementation based on initial results

## Success Criteria
- All four methods successfully fit to simulated data
- Results match expected patterns from paper Figure 2
- Computational efficiency follows expected ordering
- Code is clean, documented, and follows project conventions

## Key Implementation Decisions

### Model Compilation Strategy
- Pre-compile all Stan models in a setup target
- Store compiled model paths for reuse across fits
- Separate compilation from fitting time completely

### Parallelization Balance
- Let targets handle parallelization across scenarios
- Run Stan with sequential chains to avoid resource contention
- One core per fit for predictable performance

### Test Mode Design
- Subset to 2 scenarios (1 gamma, 1 lognormal)
- Include extreme cases (no truncation vs severe)
- Reduce iterations but maintain convergence ability
- Enable quick CI/CD validation

### Prior Specifications
- Gamma: Standard Gamma(2,1) for both parameters
- Lognormal: Normal(1.5, 1) for meanlog, Gamma(2, 1) for sdlog
- Adjust if primarycensored package has constraints

## Implementation Checklist

### Immediate Actions
- [ ] Add test mode parameters to _targets.Rmd
- [ ] Create Stan model compilation target
- [ ] Update naive_delay_model.stan priors for lognormal

### Core Development
- [ ] Implement fit_naive with proper Stan integration
- [ ] Implement fit_primarycensored using package functions
- [ ] Implement fit_primarycensored_fitdistrplus for MLE
- [ ] Simplify and implement fit_ward

### Integration & Testing
- [ ] Create combine_model_fits aggregation
- [ ] Add convergence diagnostics extraction
- [ ] Set up GitHub Actions test workflow
- [ ] Document all implementation decisions

### Validation
- [ ] Verify parameter recovery matches expectations
- [ ] Check computational efficiency ordering
- [ ] Ensure reproducibility across runs
- [ ] Test with both full and test modes

## Current PR Status Review

Based on CodeRabbit's review of PR #40 and @seabbs' comments, the following needs to be addressed:

### Key Changes Required from @seabbs Review

1. **Test Mode Implementation**
   - Remove test mode logic from scenario_grid and sample_size_grid
   - Apply test mode ONLY in fitting_grid target
   - Use tar_group_by to create grouped dataframe

2. **Stan Model Compilation**
   - Split into 3 separate targets (naive, ward, primarycensored)
   - Precompile primarycensored cmdstan model

3. **Unified Fitting Grid with tar_group_by**
   - Create grouped dataframe containing all simulated datasets
   - Include Ebola case study data in the same grid
   - Map across id key to get dataset for each fit
   - This allows fitting all datasets (simulated + real) in one pass
   
   Example structure:
   ```r
   tar_group_by(
     fitting_grid,
     {
       # Combine simulated data with Ebola data
       bind_rows(
         monte_carlo_samples %>% 
           mutate(data_type = "simulation"),
         ebola_case_study_data %>% 
           mutate(data_type = "real_world")
       ) %>%
       # Apply test mode filtering here
       filter(if (test_mode) {
         (data_type == "simulation" & scenario_id %in% c("gamma_scenario", "lognormal_scenario")) |
         (data_type == "real_world" & row_number() <= 1)
       } else TRUE)
     },
     scenario_id, sample_size  # Group by these variables
   )
   ```

4. **Code Quality Improvements**
   - Create wrapper functions for model fitting (testability/brevity)
     ```r
     # Example wrapper function
     fit_primarycensored_stan <- function(data, distribution, growth_rate, stan_settings) {
       # All logic encapsulated here
       # Easy to test and document
     }
     ```
   - Use dplyr tools instead of rebuilding dataframes
     ```r
     # Instead of: data.frame(delay = sampled_data$delay_observed, ...)
     # Use: sampled_data %>% mutate(delay = delay_observed)
     ```
   - Replace hardcoded values with getter functions
     ```r
     get_start_values <- function(distribution) {
       switch(distribution,
         gamma = list(shape = 2, scale = 2),
         lognormal = list(meanlog = 1.5, sdlog = 1)
       )
     }
     ```
   - Use distribution names directly (avoid if/else conditionals)
   - Verify primarycensored prior setting approach

### Implementation Priority

1. **Immediate** - Create proper tar_group_by fitting grid
2. **High** - Split Stan compilation targets
3. **High** - Create wrapper functions for fitting
4. **Medium** - Clean up conditionals and hardcoding
5. **Medium** - Use dplyr for dataframe operations

### Next Steps for PR Update
1. Implement tar_group_by for fitting_grid combining all data sources
2. Split compile_stan_models into 3 targets
3. Create wrapper functions in R/utils.R for each fitting method
4. Replace all hardcoded values with appropriate getter functions
5. Test the updated pipeline with test_mode enabled

### Simplified GitHub Actions Workflow
Replace the current complex workflow with:

```yaml
name: Test Parameter Recovery

on:
  pull_request:
    branches: [issue-26-implement-pmf-tools]
  workflow_dispatch:

jobs:
  test-parameter-recovery:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    steps:
    - uses: actions/checkout@v4
    
    - uses: r-lib/actions/setup-r@v2
      with:
        r-version: '4.5.0'
        
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
        
    - name: Install CmdStan
      uses: epinowcast/actions/install-cmdstan@v1
      with:
        cmdstan-version: '2.36.0'
        
    - name: Install dependencies
      run: task install
      
    - name: Run test pipeline
      run: task render PARAMS='test_mode=true' && task run
      
    - name: Check results
      run: Rscript -e "targets::tar_exist('simulated_model_fits') || stop('Pipeline failed')"
      
    - name: Upload artifacts
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: _targets/
        retention-days: 7
```