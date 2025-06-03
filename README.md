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

### Configuration

The analysis pipeline is parameterised and can be customised using command-line parameters:

```bash
# Run with custom parameters
task run -- sample_sizes="c(10, 100)" growth_rates="c(0.1, 0.2)" simulation_n=5000

# Or set parameters in a file and pass it
echo 'sample_sizes: c(10, 100, 1000)' > custom_params.yml
task run -- config_file=custom_params.yml
```

Available parameters:
- `sample_sizes`: Vector of sample sizes to test (default: `c(10, 100, 1000, 10000)`)
- `growth_rates`: Vector of growth rates (default: `c(0, 0.2)`)
- `simulation_n`: Number of simulations (default: `10000`)
- `base_seed`: Random seed (default: `100`)

For advanced configuration options and development workflows, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

### Available Commands

```bash
# Core workflow
task                # Complete pipeline (setup + render + run)
task install        # Setup renv and install dependencies
task render         # Render _targets.Rmd to create pipeline
task run            # Execute the targets pipeline
task clean          # Clean all computed results (with confirmation)

# Monitoring
task progress       # Check pipeline progress
task visualize      # Create interactive pipeline graph

# Testing
task test           # Run all tests
task coverage       # Generate test coverage report

# Manuscript
task manuscript     # Render manuscript to both PDF and HTML
task manuscript-pdf # Render manuscript to PDF only
task manuscript-html # Render manuscript to HTML only
```

Run `task help` to see all available commands.

## Development

For developers working on this repository, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for:
- Advanced configuration and development workflows
- Repository architecture and structure
- Performance optimisation and profiling
- Adding new analysis components
- Troubleshooting common issues
