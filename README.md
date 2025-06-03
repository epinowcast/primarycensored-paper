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
- `scripts/`: R scripts for task automation and development
- `data/`: Data directory for raw, processed, and results
- `figures/`: Generated figures from the analysis

## Analysis Pipeline

The analysis uses the `targets` R package for reproducibility. The pipeline is defined in `_targets.Rmd`.

### Getting Started

Install Task from https://taskfile.dev/installation/, then run:

```bash
# Complete workflow (sets up dependencies + runs analysis + renders manuscript)
task

# Or step by step:
task restore    # Restore R packages from lockfile
task render     # Render _targets.Rmd to create pipeline
task run        # Execute the targets pipeline
task manuscript # Render manuscript to PDF and HTML
```

The default `task` command automatically handles the complete analysis pipeline.
Run `task help` to see all available commands.

For configuration options and development workflows, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

