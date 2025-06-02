# primarycensored-paper

[![Codecov test coverage](https://codecov.io/gh/epinowcast/primarycensored-paper/branch/main/graph/badge.svg)](https://app.codecov.io/gh/epinowcast/primarycensored-paper?branch=main)

A repository for the paper "Modelling delays with primary Event Censored Distributions", which describes methods for handling double interval censored data in epidemiological delay distribution estimation.

## Repository Structure

- `paper/`: Contains the Quarto document for the manuscript
  - `main.qmd`: Main manuscript
  - `si.qmd`: Supplementary information
  - `reference.bib`: Bibliography
- `_targets.Rmd`: Reproducible analysis pipeline (see below)
- `R/`: Analysis functions used in the targets workflow
- `data/`: Data directory for raw, processed, and results
- `figures/`: Generated figures from the analysis

## Analysis Pipeline

The analysis uses the `targets` R package for reproducibility. The pipeline is defined in `_targets.Rmd`.

### Getting Started

Install Task from https://taskfile.dev/installation/, then run:

```bash
# Complete workflow (sets up renv + installs deps + runs analysis)
task

# Or step by step:
task install   # Initialize renv and install all dependencies
task render    # Render _targets.Rmd to create pipeline
task run       # Execute the targets pipeline
```

The default `task` command automatically handles dependency setup and runs the complete analysis pipeline.

### Configuration Parameters

The analysis pipeline is parameterized for easy customization. Key parameters include:

- **`sample_sizes`**: Vector of sample sizes for Monte Carlo comparisons (default: c(10, 100, 1000, 10000))
- **`growth_rates`**: Vector of exponential growth rates for primary event distribution (default: c(0, 0.2))
- **`simulation_n`**: Number of observations per simulation scenario (default: 10000)
- **`base_seed`**: Base seed for reproducible random number generation (default: 100)

#### Changing Parameters

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
task render-custom PARAMS='simulation_n=1000'
task run

# Multiple parameters
task render-custom PARAMS='simulation_n=1000, sample_sizes=c(10,100)'
task run
```

### Available Commands

```bash
# Core workflow
task                # Complete pipeline (setup + render + run)
task install        # Setup renv and install dependencies
task render         # Render _targets.Rmd to create pipeline
task render-custom  # Render with custom parameters (see examples above)
task run            # Execute the targets pipeline
task clean          # Clean all computed results (with confirmation)

# Visualization & monitoring
task visualize # Create interactive pipeline graph
task progress  # Check pipeline progress

# Performance analysis
task profile   # Profile pipeline performance
# See PROFILING.md for detailed profiling documentation

# Manuscript rendering
task manuscript     # Render manuscript to both PDF and HTML
task manuscript-pdf # Render manuscript to PDF only
task manuscript-html # Render manuscript to HTML only
```

**Using R directly**

```r
# Render the targets document
rmarkdown::render("_targets.Rmd")

# Run the pipeline
targets::tar_make()

# Visualize the pipeline
targets::tar_visnetwork()
```

### Performance Profiling

See [docs/PROFILING.md](docs/PROFILING.md) for detailed instructions on:
- Profiling the pipeline to identify bottlenecks
- Understanding flame graphs and optimization opportunities
- Exporting pipeline visualizations

## Development

For developers working on this repository, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for:
- Detailed repository architecture and structure
- Development workflows and best practices
- Adding new analysis components
- Performance optimisation guidelines
- Troubleshooting common issues

## Manuscript Compilation

Using Task (recommended):

```bash
task manuscript     # Render to both PDF and HTML
task manuscript-pdf # PDF only
task manuscript-html # HTML only
```

Using Quarto directly:

```bash
cd paper
quarto render main.qmd --to pdf
quarto render main.qmd --to html
```

## Available Tasks

Run `task help` to see all available commands with descriptions.
