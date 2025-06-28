#!/bin/bash
# Safe Docker cleanup script with error handling and user confirmation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to confirm action
confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    print_color $RED "Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_color $RED "Error: Docker daemon is not running"
    exit 1
fi

# Count containers and images
CONTAINER_COUNT=$(docker ps -a -q | wc -l | tr -d ' ')
IMAGE_COUNT=$(docker images -q | wc -l | tr -d ' ')
RUNNING_COUNT=$(docker ps -q | wc -l | tr -d ' ')

# Display current Docker status
print_color $YELLOW "=== Docker Cleanup Script ==="
echo "Containers: $CONTAINER_COUNT total ($RUNNING_COUNT running)"
echo "Images: $IMAGE_COUNT total"
echo

# Exit if nothing to clean
if [ "$CONTAINER_COUNT" -eq 0 ] && [ "$IMAGE_COUNT" -eq 0 ]; then
    print_color $GREEN "Nothing to clean up!"
    exit 0
fi

# Warn about running containers
if [ "$RUNNING_COUNT" -gt 0 ]; then
    print_color $YELLOW "Warning: There are $RUNNING_COUNT running containers"
fi

# Get confirmation
if ! confirm "This will DELETE ALL containers and images. Continue?"; then
    print_color $YELLOW "Cleanup cancelled"
    exit 0
fi

# Stop running containers first
if [ "$RUNNING_COUNT" -gt 0 ]; then
    print_color $YELLOW "Stopping running containers..."
    docker stop $(docker ps -q) || true
fi

# Remove all containers
if [ "$CONTAINER_COUNT" -gt 0 ]; then
    print_color $YELLOW "Removing containers..."
    docker rm -f $(docker ps -a -q) || true
    print_color $GREEN "✓ Containers removed"
fi

# Remove all images
if [ "$IMAGE_COUNT" -gt 0 ]; then
    print_color $YELLOW "Removing images..."
    docker rmi -f $(docker images -q) 2>/dev/null || true
    print_color $GREEN "✓ Images removed"
fi

# Optional: Clean up volumes and networks
if confirm "Also clean up volumes and custom networks?"; then
    print_color $YELLOW "Removing volumes..."
    docker volume prune -f || true
    
    print_color $YELLOW "Removing custom networks..."
    docker network prune -f || true
    
    print_color $GREEN "✓ Volumes and networks cleaned"
fi

# Show final status
print_color $GREEN "\n=== Cleanup Complete ==="
docker system df