#!/bin/bash
echo "Installing development dependencies for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Docker Desktop if not installed
if ! command -v docker &> /dev/null; then
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    echo "After installation, start Docker Desktop and try again."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "Docker is running! ✅"

# Install other tools via Homebrew
echo "Installing development tools..."
brew install curl wget jq

echo "All dependencies are ready! ✅"
