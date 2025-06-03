# Development Guide

This document provides comprehensive information for developers working on the primarycensored-paper repository.

## Pipeline Configuration

The analysis pipeline is fully parameterized to enable easy customization and testing. Parameters are defined in the YAML header of `_targets.Rmd` and can be modified for different analysis scenarios.

### Key Parameters

- **`sample_sizes`**: Vector of sample sizes for Monte Carlo comparisons
  - Default: `c(10, 100, 1000, 10000)`
  - Use smaller values for faster development/testing
  - Use larger values for production analyses

- **`growth_rates`**: Vector of exponential growth rates for primary event distribution
  - Default: `c(0, 0.2)` (uniform and exponential growth as per manuscript)
  - Range: 0.1-0.5 typical for epidemiological applications

- **`simulation_n`**: Number of observations per simulation scenario
  - Default: `10000` (production quality)
  - Reduce to `1000` or less for development/testing
  - Increase for higher precision analyses

- **`base_seed`**: Base seed for reproducible random number generation
  - Default: `100`
  - Change to generate different random sequences while maintaining reproducibility

### Advanced Parameter Configuration

**Method 1: Edit YAML header** in `_targets.Rmd`:
```yaml
params:
  sample_sizes: !r c(10, 100, 1000, 10000)
  growth_rates: !r c(0, 0.2)
  simulation_n: 5000  # Changed from default 10000
  base_seed: 100
```

**Method 2: Using R directly**:
```r
# Render with custom parameters
rmarkdown::render("_targets.Rmd", params = list(
  simulation_n = 5000,
  growth_rates = c(0, 0.1)
))

# Then run the pipeline
targets::tar_make()
```

**Method 3: Quick test runs**:
```bash
# Small test run (faster)
task test-run

# Custom parameters (development only)
# Note: render-custom task removed in current Taskfile
# Use Method 1 or 2 for custom parameters
```

### Development Workflows

**Quick testing during development:**
```bash
# Fast test mode
task test-run  # Runs pipeline in test mode with reduced scenarios
```

**Sensitivity analysis:**
```bash
# Edit _targets.Rmd parameters, then:
task render && task run
```

**Production runs:**
```bash
# Use defaults for final analyses
task render
task run
```

## Repository Architecture

### Core Structure

```text
primarycensored-paper/
├── paper/                  # Manuscript files
│   ├── main.qmd           # Main manuscript (Quarto)
│   ├── si.qmd             # Supplementary information
│   ├── reference.bib      # Bibliography
│   └── plos2015.bst       # Bibliography style
│
├── R/                     # Analysis functions
│   ├── analysis.R         # Core analysis functions
│   ├── models.R           # Statistical model definitions
│   ├── plotting.R         # Visualisation functions
│   ├── simulate.R         # Data simulation functions
│   └── utils.R            # Utility functions
│
├── _targets_r/            # Targets pipeline definitions
│   ├── globals/           # Global configuration
│   │   └── globals.R      # Shared variables and settings
│   └── targets/           # Individual target definitions
│       ├── analysis_summary.R
│       ├── censoring_scenarios.R
│       ├── distributions.R
│       ├── ebola_*.R      # Ebola case study targets
│       ├── figure*.R      # Figure generation targets
│       ├── fit_*.R        # Model fitting targets
│       └── ...            # Additional analysis targets
│
├── stan/                  # Stan models
│   └── naive_delay_model.stan
│
├── data/                  # Data directories
│   ├── raw/               # Raw input data
│   ├── processed/         # Processed data
│   └── results/           # Analysis results
│
├── figures/               # Generated figures
├── scripts/               # Utility scripts
│   ├── check_quarto.R     # Quarto installation check
│   ├── install_packages.R # Package installation
│   ├── profile_pipeline.R # Performance profiling
│   ├── setup_renv.R       # renv initialisation
│   ├── view_profile.R     # Profile visualisation
│   └── visualize_pipeline.R # Pipeline graph
│
├── docs/                  # Documentation
│   ├── README.md          # Documentation index
│   ├── DEVELOPMENT.md     # This file - comprehensive developer guide
│   └── PROFILING.md       # Performance analysis guide
│
├── _targets.R             # Main targets configuration
├── _targets.Rmd           # Literate pipeline documentation
├── _targets.md            # Rendered pipeline documentation
├── Taskfile.yml           # Task runner configuration
├── CLAUDE.md              # AI assistant instructions
└── renv.lock              # Package dependency lock file
```

## Workflow Components

### 1. Task Runner (Taskfile.yml)

The project uses [Task](https://taskfile.dev/) as the primary workflow orchestrator.
Key features:
- Dependency management between tasks
- Cross-platform compatibility
- Integration with R/renv ecosystem

**Essential Tasks:**
- `task` or `task default`: Complete workflow (run + manuscript)
- `task install`: Setup environment and dependencies
- `task render`: Generate pipeline from `_targets.Rmd`
- `task run`: Execute the targets pipeline
- `task manuscript`: Render manuscript to PDF/HTML
- `task test`: Run all tests using testthat
- `task coverage`: Generate test coverage report
- `task test-run`: Run pipeline in test mode (fast, reduced scenarios)

**Development and Maintenance Tasks:**
- `task clean`: Clean all computed results (with confirmation)
- `task progress`: Check pipeline progress
- `task visualize`: Create interactive pipeline graph
- `task profile`: Profile pipeline performance
- `task profile-view`: View previously saved profiling results
- `task renv-update`: Update renv lockfile with current package versions
- `task help`: Show all available commands

### 2. Targets Pipeline (_targets.R + _targets.Rmd)

The analysis pipeline uses the [`targets`](https://docs.ropensci.org/targets/) package for:
- Reproducible computational workflows
- Automatic dependency tracking
- Efficient caching and parallelisation
- Literate programming integration

**Pipeline Structure:**
- **Simulation**: Generate synthetic datasets for validation
- **Numerical Validation**: Compare analytical vs Monte Carlo solutions
- **Parameter Recovery**: Assess bias across censoring scenarios
- **Case Study**: Apply methods to Ebola epidemic data
- **Visualisation**: Generate publication figures

### 3. Package Management (renv)

Dependencies are managed using [`renv`](https://rstudio.github.io/renv/) for:
- Reproducible package environments
- Version locking across collaborators
- Isolated project dependencies

**Important Notes:**
- The `renv-update` task only snapshots development dependencies (`lintr`, `covr`)
- This prevents the lockfile from being stripped of runtime dependencies
- For full dependency updates, use `renv::snapshot()` directly in R
- Current lockfile contains 27 packages (basic set) vs 100+ needed for full pipeline

## Development Workflows

### Setting Up Development Environment

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd primarycensored-paper
   task install  # Initialises renv and installs dependencies
   ```

2. **Verify setup**:
   ```bash
   task progress  # Check pipeline status
   task visualize # Generate dependency graph
   ```

### Making Changes

1. **Modify analysis functions** in `/R/`
2. **Update pipeline targets** in `/_targets_r/targets/`
3. **Test changes**:
   ```bash
   task render  # Update pipeline definition
   task run     # Execute modified pipeline
   ```

### Adding New Analysis Components

1. **Create function** in appropriate `/R/` file
2. **Add target definition** in `/_targets_r/targets/`
3. **Update `_targets.Rmd`** to document the new component
4. **Test integration**:
   ```bash
   task render && task run
   ```

### Performance Optimisation

1. **Profile pipeline**:
   ```bash
   task profile     # Generate performance report
   task profile-view # View results
   ```

2. **Identify bottlenecks** using flame graphs
3. **Optimise code** and re-profile
4. **Use parallelisation** via `tar_option_set(controller = ...)`

### Quality Assurance

1. **Code style**: Follow R conventions in `CLAUDE.md`
2. **Documentation**: Update relevant `.md` files
3. **Testing**: Verify pipeline execution end-to-end
4. **Reproducibility**: Test on clean environment

## Key Dependencies

### Core R Packages
- `targets`, `tarchetypes`: Workflow management
- `data.table`, `dplyr`: Data manipulation
- `ggplot2`, `patchwork`: Visualisation
- `cmdstanr`: Bayesian analysis interface
- `primarycensored`: Core statistical methods

### Development Tools
- `renv`: Package management
- `here`: Path management
- `crew`: Parallel processing
- `qs`: High-performance serialisation

### External Dependencies
- **Task**: Workflow orchestration
- **Quarto**: Document rendering
- **Stan/cmdstan**: Bayesian computation

## Current Taskfile Setup

The project has been updated with a comprehensive Taskfile that includes:

### Core Workflow Tasks
- `default`: Runs the complete pipeline and renders manuscript
- `install`: Sets up renv and installs all dependencies  
- `render`: Renders `_targets.Rmd` with optional test mode parameter
- `run`: Executes the targets pipeline
- `clean`: Interactive cleanup of targets cache

### Testing and Quality Assurance
- `test`: Runs all tests using devtools::test()
- `coverage`: Generates test coverage report via covr::report()
- `coverage-console`: Shows test coverage in console
- `test-run`: Runs pipeline in test mode for fast iteration

### Documentation and Manuscript
- `manuscript`: Renders to both PDF and HTML
- `manuscript-pdf`: PDF output only
- `manuscript-html`: HTML output only
- `check-quarto`: Verifies Quarto installation

### Development Tools
- `visualize`: Creates interactive pipeline dependency graph
- `progress`: Shows pipeline execution progress
- `profile`: Profiles pipeline performance
- `profile-view`: Views saved profiling results
- `renv-update`: Updates lockfile (limited to dev dependencies)

## Common Development Tasks

### Adding a New Figure
1. Create plotting function in appropriate `/R/` file
2. Add target in `/_targets_r/targets/figure_new.R`
3. Update save targets to include new figure
4. Document in `_targets.Rmd`
5. Test with `task test-run`

### Implementing New Statistical Method
1. Add method function to relevant `/R/` file
2. Create simulation targets in `/_targets_r/targets/`
3. Add validation comparisons
4. Include in parameter recovery analysis
5. Update documentation

### Testing and Debugging
1. **Quick testing**: Use `task test-run` for fast iteration
2. **Check pipeline status**: `task progress`
3. **Examine targets**: Use R console with `tar_read(target_name)`
4. **Debug interactively**: `tar_load(target_name)`
5. **Clean problematic targets**: `tar_invalidate(c("target1", "target2"))`
6. **Full cleanup**: `task clean` (interactive confirmation)

## Integration Points

### With External Packages
- Pipeline integrates with `primarycensored` R package
- Stan models compiled via `cmdstanr`
- Manuscript references results via `targets::tar_read()`

### With CI/CD
- Taskfile provides standardised entry points
- renv ensures consistent environments
- Pipeline caching reduces computation time

## Performance Considerations

### Parallelisation
- Configured via `crew` controller in `_targets_r/globals/globals.R`
- Automatic target-level parallelisation
- Memory management through transient storage

### Caching Strategy
- Uses `qs` format for efficient serialisation
- Targets automatically cache expensive computations
- Smart invalidation based on code/data changes

### Resource Management
- Memory-intensive targets use `memory = "transient"`
- Garbage collection enabled between targets
- Parallel workers respect system resources

### Performance Profiling

The project includes comprehensive performance analysis tools:

**Basic profiling:**
```bash
task profile      # Generate performance report
task profile-view # View results in browser
```

**Understanding results:**
- Flame graphs show time spent in each function
- Bottlenecks appear as wide segments
- Focus optimisation on heaviest functions
- See [docs/PROFILING.md](PROFILING.md) for detailed guidance

## Troubleshooting

### Common Issues
1. **Missing dependencies**: Run `task install`
2. **Stale pipeline**: Run `task render` then `task run`
3. **Memory issues**: Reduce parallel workers in `_targets_r/globals/globals.R`
4. **Stan compilation**: Check cmdstan installation
5. **renv lockfile issues**: Current lockfile may have limited dependencies (27 vs 100+)

### Testing Issues
1. **Test failures**: Check `task test` output for specific errors
2. **Coverage problems**: Use `task coverage-console` for quick check
3. **Linting errors**: Functions from `utils.R` may need explicit assignment

### Performance Issues
1. Use `task profile` to identify bottlenecks
2. Check target granularity (too fine/coarse)
3. Review memory usage patterns
4. Consider computational vs I/O bound operations
5. Use `task test-run` for faster iteration during development

### Reproducibility Issues
1. **renv lockfile**: May need manual `renv::snapshot()` for full dependencies
2. **System dependencies**: Check cmdstan, Quarto installations
3. **Random seeds**: Ensure deterministic seeds in pipeline
4. **Cross-platform**: Test on different operating systems

## Contributing Guidelines

1. **Fork and branch** for feature development
2. **Follow existing patterns** in code organisation
3. **Update documentation** for user-facing changes
4. **Test thoroughly**: Use `task test` and `task test-run`
5. **Check coverage**: Run `task coverage` before submitting
6. **Use UK English** in all documentation
7. **Follow line length limits** (80 characters)
8. **Update renv**: Consider dependency impacts before updating lockfile
9. **Profile performance**: Use `task profile` for performance-sensitive changes
