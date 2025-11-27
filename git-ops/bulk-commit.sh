#!/bin/bash

# ==============================================================================
# Script Name: bulk-commit.sh
# Description: Automates git commit across all microservices.
# Usage: ./bulk-commit.sh [commit_message]
#        If no message is provided, defaults to "fix: pom.xml"
# ==============================================================================

# Default commit message
DEFAULT_MSG="fix: pom.xml"
COMMIT_MSG="${1:-$DEFAULT_MSG}"

# List of microservices to process
SERVICES=(
    "api-gateway"
    "cloud-config"
    "favourite-service"
    "order-service"
    "payment-service"
    "product-service"
    "service-discovery"
    "shipping-service"
    "user-service"
)

# Determine the project root directory
# Assuming this script is located in PROYECTO FINAL/Scripts/git-ops/
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "=================================================="
echo "Bulk Commit Tool"
echo "Project Root: $PROJECT_ROOT"
echo "Commit Message: \"$COMMIT_MSG\""
echo "=================================================="

for SERVICE in "${SERVICES[@]}"; do
    SERVICE_PATH="$PROJECT_ROOT/$SERVICE"
    
    if [ -d "$SERVICE_PATH" ]; then
        echo "Processing $SERVICE..."
        
        # Check if the directory is a git repository
        if [ -d "$SERVICE_PATH/.git" ]; then
            # Check for changes (staged or unstaged)
            if [[ -n $(git -C "$SERVICE_PATH" status --porcelain) ]]; then
                echo "  -> Changes detected. Committing..."
                git -C "$SERVICE_PATH" add .
                git -C "$SERVICE_PATH" commit -m "$COMMIT_MSG"
                echo "  -> Changes committed."
            else
                echo "  -> No new changes to commit."
            fi

            # Always try to push to handle pending commits
            echo "  -> Checking for pending commits to push..."
            git -C "$SERVICE_PATH" push
        else
            echo "  -> Warning: $SERVICE is not a git repository."
        fi
    else
        echo "  -> Error: Directory $SERVICE not found."
    fi
    echo "--------------------------------------------------"
done

echo "Bulk commit process completed."
