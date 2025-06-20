% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fit-utils.R
\name{prepare_shared_model_inputs}
\alias{prepare_shared_model_inputs}
\title{Prepare shared data and configuration for primarycensored-framework models}
\usage{
prepare_shared_model_inputs(sampled_data, fitting_grid, dist_info)
}
\arguments{
\item{sampled_data}{Data frame with delay observations and censoring windows}

\item{fitting_grid}{Single row from fitting grid with truncation info}

\item{dist_info}{List with distribution and growth_rate from
extract_distribution_info()}
}
\value{
List containing delay_data and config
}
\description{
Prepares delay data and configuration settings used by both primarycensored
and naive models to ensure consistency.
}
