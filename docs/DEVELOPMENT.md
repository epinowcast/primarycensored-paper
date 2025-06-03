# Development Guide

Developer documentation for the primarycensored-paper repository.

## Quick Start

```bash
task restore    # Install dependencies
task test-run   # Fast pipeline test
task            # Full pipeline + manuscript
```

## Custom Configuration

### Task-based Parameter Configuration

Use the `PARAMS` variable with the `render` task for custom pipeline parameters:

```bash
# Basic custom parameters
task render -- PARAMS='simulation_n=1000'
task render -- PARAMS='test_mode=true'

# Multiple parameters (space-separated)
task render -- PARAMS='simulation_n=1000 growth_rates=c(0,0.1)'

# Then run pipeline
task run
```

### Available Parameters

- `simulation_n`: Observations per scenario (default: 10000, test: 1000)
- `sample_sizes`: Monte Carlo sample sizes (default: c(10,100,1000,10000))
- `growth_rates`: Primary event growth rates (default: c(0,0.2))
- `base_seed`: Random seed (default: 100)
- `test_mode`: Fast test mode (reduces scenarios significantly)

### Alternative Configuration Methods

**Direct YAML editing** in `_targets.Rmd`:
```yaml
params:
  simulation_n: 5000
  test_mode: true
```

**R console**:
```r
rmarkdown::render("_targets.Rmd", params = list(simulation_n = 1000))
targets::tar_make()
```

## Key Commands

### Main Workflow
- `task` - Full pipeline + manuscript rendering
- `task render` - Generate pipeline from _targets.Rmd
- `task run` - Execute targets pipeline
- `task visualize` - Interactive dependency graph
- `task progress` - Check pipeline status

### Development
- `task test-run` - Fast test mode pipeline
- `task test` - Run testthat tests
- `task lint` - Code linting
- `task coverage` - Test coverage report
- `task profile` - Performance profiling

### Package Management
- `task restore` - Install from renv.lock
- `task install -- pkg1 pkg2` - Add packages
- `task renv-update` - Update lockfile

### Manuscript
- `task manuscript` - Render PDF + HTML
- `task manuscript-pdf` - PDF only
- `task check-quarto` - Verify Quarto installation

## Repository Structure

```text
primarycensored-paper/
├── paper/           # Manuscript (main.qmd, si.qmd)
├── R/               # Analysis functions
├── _targets_r/      # Pipeline definitions
│   ├── globals/     # Shared configuration
│   └── targets/     # Individual targets
├── stan/            # Bayesian models
├── data/            # Raw/processed/results
├── figures/         # Generated plots
├── scripts/         # Utility scripts
├── Taskfile.yml     # Task definitions
└── _targets.Rmd     # Pipeline documentation
```

## Pipeline Overview

The [`targets`](https://docs.ropensci.org/targets/) pipeline includes:
- **Simulation**: Synthetic data validation
- **Parameter Recovery**: Bias assessment  
- **Case Study**: Ebola epidemic analysis
- **Figures**: Publication-ready plots

## Development Workflows

### Setup
```bash
git clone <repository-url>
cd primarycensored-paper
task restore     # Install packages
task progress    # Check status
```

### Making Changes
1. Edit functions in `/R/`
2. Update targets in `/_targets_r/targets/`  
3. Test: `task render && task run`

### Adding Components
1. Create function in `/R/`
2. Add target definition
3. Update `_targets.Rmd` docs
4. Test integration

### Performance Analysis
```bash
task profile      # Generate report
task profile-view # View results
```

## Dependencies

- **Core**: `targets`, `primarycensored`, `cmdstanr`, `ggplot2`
- **External**: Task, Quarto, Stan/cmdstan

## Common Tasks

### Adding Figures
1. Create plotting function in `/R/`
2. Add target in `/_targets_r/targets/`
3. Test with `task test-run`

### Debugging
```bash
task progress              # Check status
tar_read(target_name)      # Examine results
tar_invalidate("target")   # Force rebuild
task clean                 # Reset cache
```

## Troubleshooting

- **Missing deps**: `task restore`
- **Stale pipeline**: `task render && task run`
- **Memory issues**: Reduce workers in `_targets_r/globals/globals.R`
- **Performance**: Use `task profile`

## Performance

- Parallelisation via `crew` controller
- Caching with `qs` format
- Memory management with `memory = "transient"`
- See [PROFILING.md](PROFILING.md) for details
