# Main Paper Figures Plan

## Figure 1: Numerical Validation Results

A single figure demonstrating the accuracy and computational efficiency of our approach with three panels:

- **Panel A**: PMF Comparison
  - Line plot comparing true delay time PMFs for all three distributions (gamma, lognormal, Burr)
  - X-axis: delay time in days
  - Y-axis: probability
  - Show analytical solution (where available), numerical solution, and Monte Carlo results (sample size = 10000)
  - Add small inset plots highlighting key features (e.g., impact of censoring window width)

- **Panel B**: Accuracy Metrics
  - Bar plot showing total variation distance between computed PMFs and Monte Carlo simulations
  - X-axis: distribution type
  - Y-axis: total variation distance (log scale)
  - Group bars by method (analytical vs numerical)
  - Show performance across different truncation scenarios (none, moderate, severe)

- **Panel C**: Computational Efficiency
  - Bar plot showing computation time (log scale)
  - X-axis: sample size (10, 100, 1000, 10000)
  - Y-axis: computation time in milliseconds (log scale)
  - Group bars by method (Monte Carlo, analytical, numerical)
  - Include annotations showing speed improvement factors

## Figure 2: Parameter Recovery Results

A single figure demonstrating parameter recovery performance with three panels:

- **Panel A**: Gamma Distribution Parameter Recovery
  - Violin plots showing posterior distributions of shape and scale parameters
  - X-axis: grouped by parameter and truncation scenario
  - Y-axis: parameter value
  - Show PC method vs naive method
  - Add horizontal lines for true parameter values
  - Include small annotations with bias percentages

- **Panel B**: Method Comparison Across Distributions
  - Dot plot with uncertainty intervals showing parameter recovery for all three distributions
  - X-axis: parameter (scaled to make comparable across distributions)
  - Y-axis: relative bias (%)
  - Color points by method (PC-Stan, PC-fitdistrplus, naive-Stan, naive-fitdistrplus)
  - Include dashed line at zero (no bias)
  - Add facets for truncation scenarios

- **Panel C**: Effect of Censoring Window Width
  - Line plot showing bias as function of censoring window width
  - X-axis: window width (1-4 days)
  - Y-axis: relative parameter bias (%)
  - Separate lines for PC and naive methods
  - Small facets for each distribution
  - Include uncertainty bands

## Figure 3: Case Study Results

A single figure showcasing the Ebola case study results with three panels:

- **Panel A**: Parameter Estimates Across Time Periods
  - Scatter plot showing gamma shape vs scale parameter estimates
  - X-axis: shape parameter
  - Y-axis: scale parameter
  - Points for each method (PC, Ward et al., naive)
  - Connect points from same time period with dashed lines
  - Include ellipses showing 95% credible regions
  - Split into real-time (left) and retrospective (right) analyses

- **Panel B**: Mean Delay Estimates
  - Line plot showing estimated mean delay (k*θ) over time
  - X-axis: observation period
  - Y-axis: mean delay (days)
  - Separate lines for each method
  - Include 95% credible intervals as ribbons
  - Compare real-time vs retrospective estimates

- **Panel C**: Computational Performance
  - Bar plot comparing effective samples per second
  - X-axis: observation period
  - Y-axis: ESS/second (log scale)
  - Group bars by method (PC vs Ward et al.)
  - Include annotations showing speedup factors
  - Add small inset showing scaling with dataset size