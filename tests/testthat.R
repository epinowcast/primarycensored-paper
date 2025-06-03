#!/usr/bin/env Rscript

# Load required libraries
library(testthat)
library(primarycensored)
library(primarycensoredpaper)

# Run all tests
test_check("primarycensoredpaper")