#!/bin/bash
set -e

# Script to build Linux application for Production environment (Release mode)
echo "========================================"
echo "Building Linux app for Production (Release)"
echo "========================================"

# Switch to production environment
./scripts/switch-to-prod.sh

# Validate environment variables
./scripts/validate-env.sh

# Build Linux release
echo "Building Linux release application..."
flutter build linux --release

echo "Build complete! Output at: build/linux/x64/release/bundle"
