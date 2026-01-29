#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

MODE="${1:-debug}"

case "$MODE" in
    debug)
        echo "Building debug..."
        swift build
        echo ""
        echo "Binary: $(swift build --show-bin-path)/WardleyMapsApp"
        ;;
    release)
        echo "Building release..."
        swift build -c release
        echo ""
        echo "Binary: $(swift build -c release --show-bin-path)/WardleyMapsApp"
        ;;
    test)
        echo "Running tests..."
        swift test
        ;;
    run)
        echo "Building and running..."
        swift build
        "$(swift build --show-bin-path)/WardleyMapsApp"
        ;;
    clean)
        echo "Cleaning..."
        swift package clean
        ;;
    *)
        echo "Usage: $0 {debug|release|test|run|clean}"
        exit 1
        ;;
esac
