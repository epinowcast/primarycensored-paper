#!/usr/bin/env Rscript

# Check if Quarto is installed
# This script verifies Quarto installation and version

if (!system("command -v quarto", ignore.stderr = TRUE, ignore.stdout = TRUE)) {
  message("✅ Quarto is installed: ", system("quarto --version", intern = TRUE))
} else {
  message("❌ Quarto is not installed")
  message("📥 Please install Quarto from: https://quarto.org/docs/get-started/")
  message("   Or use: brew install quarto (macOS)")
  quit(status = 1)
}