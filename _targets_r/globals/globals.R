library(targets)
library(tarchetypes)
library(data.table)
library(ggplot2)
library(patchwork)
library(purrr)
library(here)
library(crew)

# Source all R functions
functions <- list.files(here("R"), full.names = TRUE, pattern = "\\.R$")
walk(functions, source)
rm("functions")

# Set up crew controller for parallel processing
controller <- crew_controller_local(
  name = "primarycensored_crew",
  workers = parallel::detectCores() - 1,  # Leave one core free
  seconds_idle = 30
)

# Configuration values
sample_sizes <- c(10, 100, 1000, 10000)
growth_rate <- 0.2  # Exponential growth rate as per manuscript
simulation_n <- 10000  # Number of observations per scenario
base_seed <- 100  # Base seed for reproducibility

# Set targets options
tar_option_set(
  packages = c("data.table", "ggplot2", "patchwork", "purrr", "here", "dplyr", 
               "tidyr", "qs2", "primarycensored", "cmdstanr"),
  format = "qs",  # Use qs format (qs2 is used via repository option)
  memory = "transient",  # Free memory after each target completes
  garbage_collection = TRUE,  # Run garbage collection
  controller = controller,  # Use crew for parallel processing
  repository = "local"  # Use qs2 backend for storage
)
