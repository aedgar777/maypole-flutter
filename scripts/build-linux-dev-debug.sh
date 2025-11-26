#!/bin/bash
set -e

# Script to build Linux application for Development environment (Debug mode)
echo "========================================"
echo "Building Linux app for Development (Debug)"
echo "========================================"

# Switch to development environment
./scripts/switch-to-dev.sh

# Validate environment variables
./scripts/validate-env.sh

# Build Linux debug
echo "Building Linux debug application..."
flutter build linux --debug

echo "Build complete! Output at: build/linux/x64/debug/bundle"
