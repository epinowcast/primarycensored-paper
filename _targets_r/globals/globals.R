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

# Load configuration from JSON (saved by save-config chunk)
config <- jsonlite::read_json("_targets_r/globals/config.json")
sample_sizes <- unlist(config$sample_sizes)
growth_rates <- unlist(config$growth_rates)
simulation_n <- unlist(config$simulation_n)
base_seed <- unlist(config$base_seed)
test_mode <- unlist(config$test_mode)


# Set targets options
tar_option_set(
  packages = c("data.table", "ggplot2", "patchwork", "purrr", "here", "dplyr",
               "tidyr", "qs2", "primarycensored", "cmdstanr", "tictoc", "posterior"),
  format = "qs",  # Use qs format (qs2 is used via repository option)
  memory = "transient",  # Free memory after each target completes
  garbage_collection = TRUE,  # Run garbage collection
  controller = controller,  # Use crew for parallel processing
  repository = "local",  # Use qs2 backend for storage
  error = "continue"  # Continue pipeline when targets fail
)