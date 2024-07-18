#!/usr/bin/env bash
set -Eeuo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 --platform=python|taipy"
    exit 1
}

# Parse command line arguments
for i in "$@"; do
    case $i in
    --platform=*)
        PLATFORM="${i#*=}"
        shift
        ;;
    *)
        usage
        ;;
    esac
done

# Check if PLATFORM is set
if [ -z "$PLATFORM" ]; then
    usage
fi

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_NAME" ]; then
    mkdir "$PROJECT_NAME"
    echo "Created directory: $PROJECT_NAME"
fi

# Execute scripts based on platform
if [ "$PLATFORM" == "python" ] || [ "$PLATFORM" == "taipy" ]; then
    ./python.sh
    echo "Executed python.sh"
    if [ "$PLATFORM" == "taipy" ]; then
        ./taipy.sh
        echo "Executed taipy.sh"
    fi
fi

echo "Initialization complete for platform: $PLATFORM"
