#!/bin/bash
# Build Lambda Layer from shared utilities

set -e

echo "Building Lambda Layer..."

cd lambda/layers/shared-layer
zip -r ../shared-layer.zip nodejs/

echo "✓ Lambda layer built: lambda/layers/shared-layer.zip"
