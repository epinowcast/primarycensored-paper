#!/usr/bin/env Rscript

# Load required libraries
library(testthat)
library(here)
library(primarycensored)

# Source the R functions we want to test
source(here::here("R", "pmf_tools.R"))
source(here::here("R", "utils.R"))

# Run all tests
test_dir(here::here("tests", "testthat"))
