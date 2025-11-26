#!/bin/bash
set -e

# Script to build Linux application for Production environment (Debug mode)
echo "========================================"
echo "Building Linux app for Production (Debug)"
echo "========================================"

# Switch to production environment
./scripts/switch-to-prod.sh

# Validate environment variables
./scripts/validate-env.sh

# Build Linux debug
echo "Building Linux debug application..."
flutter build linux --debug

echo "Build complete! Output at: build/linux/x64/debug/bundle"
