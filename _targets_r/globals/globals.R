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

# Configuration values from parameters (with fallbacks for direct targets execution)
sample_sizes <- if(exists("params")) params$sample_sizes else c(10, 100, 1000, 10000)
growth_rate <- if(exists("params")) params$growth_rate else 0.2  # Exponential growth rate as per manuscript
simulation_n <- if(exists("params")) params$simulation_n else 10000  # Number of observations per scenario
base_seed <- if(exists("params")) params$base_seed else 100  # Base seed for reproducibility

# Set targets options
tar_option_set(
  packages = c("data.table", "ggplot2", "patchwork", "purrr", "here", "dplyr", 
               "tidyr", "qs2", "primarycensored", "cmdstanr", "tictoc"),
  format = "qs",  # Use qs format (qs2 is used via repository option)
  memory = "transient",  # Free memory after each target completes
  garbage_collection = TRUE,  # Run garbage collection
  controller = controller,  # Use crew for parallel processing
  repository = "local"  # Use qs2 backend for storage
)
