# Performance Profiling Guide

This guide explains how to profile and optimize the targets pipeline performance.

## Quick Start

```bash
# Profile the pipeline
task profile

# View saved profiling results
task profile-view

# Visualize the pipeline structure
task visualize

# Save pipeline visualization as PNG
task visualize-png
```

## Profiling the Pipeline

The `task profile` command runs the entire pipeline with profiling enabled to identify performance bottlenecks.

### What it does:
1. Runs the pipeline with profiling enabled (crew parallelization disabled for accurate measurements)
2. Opens an interactive flame graph in your browser
3. Saves results to `profile_results.rds` for later viewing
4. Generates `profile_report.html` for sharing

### Understanding the Results

The profvis flame graph shows:
- **Width**: Time spent in each function (wider = more time)
- **Height**: Call stack depth
- **Colors**: Different types of operations
  - Blue: Regular R code
  - Yellow: Memory allocation
  - Red: Garbage collection

### Common Bottlenecks to Look For:
1. **Data I/O**: Look for wide bars in read/write operations
2. **Model Fitting**: Statistical computations often dominate runtime
3. **Memory Issues**: Frequent garbage collection (red bars) indicates memory pressure
4. **Inefficient Loops**: Repeated function calls that could be vectorized

## Pipeline Visualization

The `task visualize` command creates an interactive network graph of your pipeline.

### Understanding the Visualization:
- **Green nodes**: Up-to-date targets
- **Blue nodes**: Targets that need to be rebuilt
- **Red nodes**: Failed targets
- **Edges**: Dependencies between targets
- **Branching**: Dynamic branching patterns are shown as grouped nodes

### Saving Visualizations:
- `task visualize`: Creates interactive HTML
- `task visualize-png`: Converts to static PNG image

## Optimization Tips

Based on profiling results, consider:

1. **Use transient memory**: Already configured in this pipeline
2. **Enable crew parallelization**: Already configured for normal runs
3. **Optimize data formats**: We use `qs2` for efficient serialization
4. **Reduce target granularity**: Combine small targets to reduce overhead
5. **Cache expensive computations**: Use `tar_cue()` for smart invalidation

## Files Generated

- `profile_results.rds`: Raw profiling data
- `profile_report.html`: Standalone HTML report
- `pipeline_visualization.html`: Interactive pipeline graph
- `pipeline_visualization.png`: Static pipeline image

All these files are gitignored and not tracked in version control.