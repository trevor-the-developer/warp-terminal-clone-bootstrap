#!/bin/bash
# warp-terminal-bootstrap.sh
# Modular bootstrap script for Warp Terminal Clone

set -euo pipefail

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default project location (where script is executed from)
DEFAULT_PROJECT_LOCATION="$(pwd)"

# Parse command line arguments
show_help() {
    echo "🚀 Warp Terminal Clone - Bootstrap Script"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --path <path>     Specify base directory for project creation"
    echo "                        (default: current directory)"
    echo "  -n, --name <name>     Specify project folder name"
    echo "                        (default: warp-terminal)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Create in current directory"
    echo "  $0 -p ~/Projects                     # Create in ~/Projects/warp-terminal"
    echo "  $0 -p ~/Dev -n my-terminal           # Create in ~/Dev/my-terminal"
    echo "  $0 --path /opt --name warp-clone     # Create in /opt/warp-clone"
    echo ""
    echo "The script will create the project structure and all necessary files."
}

# Parse arguments
PROJECT_BASE_DIR="$DEFAULT_PROJECT_LOCATION"
PROJECT_NAME="warp-terminal"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            PROJECT_BASE_DIR="$2"
            shift 2
            ;;
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate and expand the base directory
if [ ! -d "$PROJECT_BASE_DIR" ]; then
    echo "❌ Base directory does not exist: $PROJECT_BASE_DIR"
    echo "Please create the directory first or choose an existing one."
    exit 1
fi

# Convert to absolute path
PROJECT_BASE_DIR="$(cd "$PROJECT_BASE_DIR" && pwd)"

echo "🎯 Bootstrap Configuration:"
echo "   Base directory: $PROJECT_BASE_DIR"
echo "   Project name: $PROJECT_NAME"
echo "   Full project path: $PROJECT_BASE_DIR/$PROJECT_NAME"
echo ""

# Check if project directory already exists
if [ -d "$PROJECT_BASE_DIR/$PROJECT_NAME" ]; then
    echo "⚠️  Project directory already exists: $PROJECT_BASE_DIR/$PROJECT_NAME"
    read -p "Do you want to continue and overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
    echo "🔄 Continuing with overwrite..."
    echo ""
fi

# Load configuration from JSON
CONFIG_FILE="$SCRIPT_DIR/warp-terminal-bootstrap-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Please ensure warp-terminal-bootstrap-config.json is in the same directory as this script"
    exit 1
fi

# Read configuration into variable
CONFIG=$(cat "$CONFIG_FILE" 2>/dev/null || echo "{}")

# Source the function library
FUNCTIONS_FILE="$SCRIPT_DIR/lib/warp-terminal-bootstrap-functions.sh"
if [ -f "$FUNCTIONS_FILE" ]; then
    # Set global variables for functions
    export SCRIPT_DIR CONFIG PROJECT_BASE_DIR PROJECT_NAME
    source "$FUNCTIONS_FILE"
else
    echo "❌ Function library not found: $FUNCTIONS_FILE"
    echo "Please ensure warp-terminal-bootstrap-functions.sh is in the lib/ directory"
    echo "Expected location: $FUNCTIONS_FILE"
    exit 1
fi

# Main execution
main() {
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "❌ jq is required but not installed."
        echo "Install with: sudo apt install jq (Ubuntu) or brew install jq (macOS)"
        exit 1
    fi
    
    # Execute the bootstrap process with custom arguments
    execute_bootstrap_with_args "$PROJECT_BASE_DIR" "$PROJECT_NAME"
}

# Run main function
main "$@"