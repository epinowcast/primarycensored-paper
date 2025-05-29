#!/usr/bin/env Rscript

# Create a visualization of the pipeline
# This script generates an interactive HTML visualization

message("🔍 Creating pipeline visualization...")

if (!requireNamespace("visNetwork", quietly = TRUE)) {
  stop("The visNetwork package is required. Run: task install")
}

# Create interactive visualization
vis <- targets::tar_visnetwork()

# Save as HTML
htmlwidgets::saveWidget(
  vis, 
  "pipeline_visualization.html", 
  selfcontained = TRUE
)

message("✅ Pipeline visualization opened in browser")
message("   - HTML saved to: pipeline_visualization.html")
