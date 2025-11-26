#!/bin/bash
set -e

# Script to build Linux application for Development environment (Release mode)
echo "========================================"
echo "Building Linux app for Development (Release)"
echo "========================================"

# Switch to development environment
./scripts/switch-to-dev.sh

# Validate environment variables
./scripts/validate-env.sh

# Build Linux release
echo "Building Linux release application..."
flutter build linux --release

echo "Build complete! Output at: build/linux/x64/release/bundle"
