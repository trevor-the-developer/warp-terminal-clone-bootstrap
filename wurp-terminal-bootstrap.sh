#!/bin/bash
# wurp-terminal-bootstrap.sh
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
    echo "                        (default: wurp-terminal)"
    echo "  -d, --debug          Enable debug mode (shows module loading)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Create in current directory"
    echo "  $0 -p ~/Projects                     # Create in ~/Projects/wurp-terminal"
    echo "  $0 -p ~/Dev -n my-terminal           # Create in ~/Dev/my-terminal"
    echo "  $0 --path /opt --name wurp-clone     # Create in /opt/wurp-clone"
    echo "  $0 --debug -p ~/test -n debug-run    # Create with debug output"
    echo ""
    echo "The script will create the project structure and all necessary files."
    echo ""
    echo "Debug mode shows:"
    echo "  • Module loading progress"
    echo "  • Function availability"
    echo "  • Internal variable states"
}

# Parse arguments
PROJECT_BASE_DIR="$DEFAULT_PROJECT_LOCATION"
PROJECT_NAME="wurp-terminal"
DEBUG_MODE=false

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
        -d|--debug)
            DEBUG_MODE=true
            export DEBUG=true
            shift
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

# Debug output if enabled
if [ "$DEBUG_MODE" = true ]; then
    echo "🐛 Debug mode enabled"
    echo "DEBUG: Script directory: $SCRIPT_DIR"
    echo "DEBUG: Project base: $PROJECT_BASE_DIR"
    echo "DEBUG: Project name: $PROJECT_NAME"
    echo ""
fi

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
if [ "$DEBUG_MODE" = true ]; then
    echo "   Debug mode: enabled"
fi
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
CONFIG_FILE="$SCRIPT_DIR/wurp-terminal-bootstrap-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Please ensure wurp-terminal-bootstrap-config.json is in the same directory as this script"
    exit 1
fi

# Read configuration into variable
CONFIG=$(cat "$CONFIG_FILE" 2>/dev/null || echo "{}")

# Debug configuration loading
if [ "$DEBUG_MODE" = true ]; then
    echo "DEBUG: Configuration loaded from: $CONFIG_FILE"
    echo "DEBUG: Config size: $(echo "$CONFIG" | wc -c) characters"
    echo ""
fi

# Source the function library
FUNCTIONS_FILE="$SCRIPT_DIR/lib/wurp-terminal-bootstrap-functions.sh"
if [ -f "$FUNCTIONS_FILE" ]; then
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Loading functions from: $FUNCTIONS_FILE"
    fi
    
    # Set global variables for functions (required by modular system)
    export SCRIPT_DIR CONFIG PROJECT_BASE_DIR PROJECT_NAME
    
    # Source the modular function library
    source "$FUNCTIONS_FILE"
    
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Functions loaded successfully"
        echo ""
    fi
else
    echo "❌ Function library not found: $FUNCTIONS_FILE"
    echo "Please ensure wurp-terminal-bootstrap-functions.sh is in the lib/ directory"
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
    
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: Starting bootstrap execution..."
        echo "DEBUG: Calling execute_bootstrap_with_args('$PROJECT_BASE_DIR', '$PROJECT_NAME')"
        echo ""
    fi
    
    # Execute the bootstrap process with custom arguments
    # This function is provided by the modular system
    execute_bootstrap_with_args "$PROJECT_BASE_DIR" "$PROJECT_NAME"
    
    local exit_code=$?
    
    if [ "$DEBUG_MODE" = true ]; then
        echo ""
        echo "DEBUG: Bootstrap completed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Add signal handling for cleanup
cleanup() {
    if [ "$DEBUG_MODE" = true ]; then
        echo ""
        echo "DEBUG: Cleanup triggered by signal"
    fi
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"
