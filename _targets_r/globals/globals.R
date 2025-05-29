library(targets)
library(tarchetypes)
library(data.table)
library(ggplot2)
library(patchwork)
library(purrr)
library(here)

# Source all R functions
functions <- list.files(here("R"), full.names = TRUE, pattern = "\\.R$")
walk(functions, source)
rm("functions")

# Set targets options
tar_option_set(
  packages = c("data.table", "ggplot2", "patchwork", "purrr", "here", "dplyr", 
               "tidyr", "qs2", "primarycensored", "cmdstanr"),
  format = "qs2"
)
