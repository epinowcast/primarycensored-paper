# primarycensored Analysis Pipeline

This directory contains a reproducible analysis pipeline for the primarycensored paper using the `targets` R package.

## Structure

- `_targets.Rmd`: Main analysis pipeline document
- `R/`: Custom R functions used in the analysis
  - `utils.R`: Utility functions
  - `simulate.R`: Data simulation functions
  - `models.R`: Model fitting functions
  - `plotting.R`: Visualization functions
  - `analysis.R`: Analysis helper functions
- `data/`: Data directory
  - `raw/`: Raw input data
  - `processed/`: Processed data
  - `results/`: Analysis results
- `figures/`: Generated figures
- `run_analysis.R`: R script to run the analysis
- `Taskfile.yml`: Task runner configuration for running the analysis

## Requirements

Install required R packages:

```r
install.packages(c(
  "targets",
  "tarchetypes", 
  "data.table",
  "ggplot2",
  "purrr",
  "here",
  "rmarkdown"
))
```

## Running the Analysis

There are three ways to run the analysis:

### Option 1: Using Task (recommended)

First install Task from https://taskfile.dev/installation/

```bash
# Run complete pipeline
task

# Individual steps
task render      # Render _targets.Rmd
task run         # Run pipeline
task visualize   # Create visualization
task progress    # Check progress
task help        # Show available commands
```

### Option 2: Using the R script

```bash
# Run the complete pipeline
Rscript run_analysis.R run

# Just render the document
Rscript run_analysis.R render

# Visualize the pipeline
Rscript run_analysis.R visualize

# Check progress
Rscript run_analysis.R progress
```

### Option 3: Using R directly

```r
# Render the targets document
rmarkdown::render("_targets.Rmd")

# Run the pipeline
targets::tar_make()

# Visualize the pipeline
targets::tar_visnetwork()
```

## Analysis Steps

The pipeline includes:

1. **Data Preparation**: Load and prepare data for analysis
2. **Simulation Studies**: Generate simulated datasets under different scenarios
3. **Model Fitting**: Fit primarycensored and comparison models
4. **Model Evaluation**: Calculate performance metrics and diagnostics
5. **Visualization**: Create plots comparing methods
6. **Results Summary**: Compile and save results

## Output

- Results are saved to `data/results/`
- Figures are saved to `figures/`
- The targets cache is stored in `_targets/`

## Extending the Analysis

To add new analyses:

1. Add new functions to the appropriate R file
2. Add new targets to `_targets.Rmd`
3. Re-render the document: `rmarkdown::render("_targets.Rmd")`
4. Run the updated pipeline: `targets::tar_make()`