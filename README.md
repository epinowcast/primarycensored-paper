# primarycensored-paper

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

Install dependencies using the Task runner:

```bash
# Install Task from https://taskfile.dev/installation/
# Then run:
task install
```

This will install all required R packages using renv for reproducible dependency management.

### Running the Analysis

```bash
# Core workflow
task           # Run complete pipeline (render + run)
task render    # Render _targets.Rmd to create pipeline
task run       # Execute the targets pipeline
task clean     # Clean all computed results (with confirmation)

# Visualization & monitoring
task visualize # Create interactive pipeline graph
task progress  # Check pipeline progress

# Performance analysis
task profile   # Profile pipeline performance
# See PROFILING.md for detailed profiling documentation
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

See [PROFILING.md](PROFILING.md) for detailed instructions on:
- Profiling the pipeline to identify bottlenecks
- Understanding flame graphs and optimization opportunities
- Exporting pipeline visualizations

## Paper Compilation

To compile the paper:

```bash
quarto render paper/main.qmd --to pdf
```

## Available Tasks

Run `task help` to see all available commands with descriptions.
