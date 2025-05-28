# Makefile for primarycensored targets analysis

.PHONY: all render run visualize clean help

# Default target
all: render run

# Render the targets Rmarkdown document
render:
	@echo "Rendering _targets.Rmd..."
	Rscript -e "rmarkdown::render('_targets.Rmd')"

# Run the targets pipeline
run:
	@echo "Running targets pipeline..."
	Rscript -e "targets::tar_make()"

# Visualize the targets pipeline
visualize:
	@echo "Creating pipeline visualization..."
	Rscript -e "targets::tar_visnetwork()"

# Show pipeline progress
progress:
	@echo "Checking pipeline progress..."
	Rscript -e "targets::tar_progress()"

# Clean targets cache (use with caution!)
clean:
	@echo "Cleaning targets cache..."
	@echo "This will delete all computed results. Are you sure? [y/N]"
	@read ans && [ $${ans:-N} = y ] && rm -rf _targets/

# Show available commands
help:
	@echo "Available commands:"
	@echo "  make render     - Render the _targets.Rmd document"
	@echo "  make run        - Run the complete targets pipeline"
	@echo "  make visualize  - Create a visualization of the pipeline"
	@echo "  make progress   - Show pipeline progress"
	@echo "  make clean      - Clean targets cache (removes all results!)"
	@echo "  make help       - Show this help message"