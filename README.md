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

### Requirements

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

### Running the Analysis

**Option 1: Using Task (recommended)**

First install Task from https://taskfile.dev/installation/

```bash
task           # Run complete pipeline
task render    # Render _targets.Rmd
task run       # Run targets pipeline
task visualize # Create pipeline visualization
task progress  # Check progress
```

**Option 2: Using R directly**

```r
# Render the targets document
rmarkdown::render("_targets.Rmd")

# Run the pipeline
targets::tar_make()

# Visualize the pipeline
targets::tar_visnetwork()
```

## Paper Compilation

To compile the paper:

```bash
quarto render paper/main.qmd --to pdf
```
