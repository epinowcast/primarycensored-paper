# Development Guide

This document provides comprehensive information for developers working on the primarycensored-paper repository.

## Repository Architecture

### Core Structure

```
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
- `task` or `task default`: Complete workflow
- `task install`: Setup environment and dependencies
- `task render`: Generate pipeline from `_targets.Rmd`
- `task run`: Execute the targets pipeline
- `task manuscript`: Render manuscript to PDF/HTML

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

## Common Development Tasks

### Adding a New Figure
1. Create plotting function in `/R/plotting.R`
2. Add target in `/_targets_r/targets/figure_new.R`
3. Update save targets to include new figure
4. Document in `_targets.Rmd`

### Implementing New Statistical Method
1. Add method function to `/R/models.R`
2. Create simulation targets in `/_targets_r/targets/`
3. Add validation comparisons
4. Include in parameter recovery analysis

### Debugging Pipeline Issues
1. Check target status: `task progress`
2. Examine specific target: `tar_read(target_name)`
3. Debug interactively: `tar_load(target_name)`
4. Clean problematic targets: `tar_invalidate(c("target1", "target2"))`

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

## Troubleshooting

### Common Issues
1. **Missing dependencies**: Run `task install`
2. **Stale pipeline**: Run `task render` then `task run`
3. **Memory issues**: Reduce parallel workers in globals
4. **Stan compilation**: Check cmdstan installation

### Performance Issues
1. Use `task profile` to identify bottlenecks
2. Check target granularity (too fine/coarse)
3. Review memory usage patterns
4. Consider computational vs I/O bound operations

### Reproducibility Issues
1. Verify renv lockfile is current
2. Check for system-specific dependencies
3. Ensure deterministic random seeds
4. Validate cross-platform compatibility

## Contributing Guidelines

1. **Fork and branch** for feature development
2. **Follow existing patterns** in code organisation
3. **Update documentation** for user-facing changes
4. **Test thoroughly** before submitting PR
5. **Use UK English** in all documentation
6. **Follow line length limits** (80 characters)
