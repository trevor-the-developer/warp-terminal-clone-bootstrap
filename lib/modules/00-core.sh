#!/bin/bash
# scripts/lib/modules/00-core.sh
# Core utilities module for Wurp Terminal Bootstrap
# This module provides fundamental functions used by all other modules

# ========================================
# CONFIGURATION FUNCTIONS
# ========================================

# Get config value using jq
get_config() {
    local path=$1
    echo "$CONFIG" | jq -r "$path // empty" 2>/dev/null
}

# Get config array
get_config_array() {
    local path=$1
    echo "$CONFIG" | jq -r "$path[]? // empty" 2>/dev/null
}

# Expand variables in path (handles $HOME and ~ expansion)
expand_path() {
    local path=$1
    # Handle $HOME expansion properly
    path="${path/\$HOME/$HOME}"
    # Handle ~ expansion
    path="${path/#\~/$HOME}"
    echo "$path"
}

# ========================================
# OUTPUT AND MESSAGING FUNCTIONS
# ========================================

# Print colored output
print_color() {
    local color_name=$1
    local message=$2
    local color_code=$(get_config ".status.colors.$color_name")
    local nc=$(get_config ".status.colors.nc")

    # Fallback colors if config fails
    case $color_name in
        "red") color_code="${color_code:-\033[0;31m}" ;;
        "green") color_code="${color_code:-\033[0;32m}" ;;
        "yellow") color_code="${color_code:-\033[1;33m}" ;;
        "blue") color_code="${color_code:-\033[0;34m}" ;;
        "cyan") color_code="${color_code:-\033[0;36m}" ;;
        *) color_code="" ;;
    esac
    nc="${nc:-\033[0m}"

    echo -e "${color_code}${message}${nc}"
}

# Print status with emoji
print_status() {
    local status=$1
    local message=$2
    local emoji=$(get_config ".status.emojis.$status")

    case $status in
        "success") print_color "green" "${emoji:-✅} $message" ;;
        "error") print_color "red" "${emoji:-❌} $message" ;;
        "warning") print_color "yellow" "${emoji:-⚠️} $message" ;;
        "info") print_color "cyan" "${emoji:-ℹ️} $message" ;;
        "working") print_color "yellow" "${emoji:-🔨} $message" ;;
        "folder") print_color "blue" "${emoji:-📁} $message" ;;
        "file") print_color "green" "${emoji:-📝} $message" ;;
        "computer") print_color "cyan" "${emoji:-💻} $message" ;;
        "gear") print_color "yellow" "${emoji:-⚙️} $message" ;;
        "wrench") print_color "yellow" "${emoji:-🔧} $message" ;;
        "book") print_color "blue" "${emoji:-📖} $message" ;;
        "rocket") print_color "cyan" "${emoji:-🚀} $message" ;;
        "party") print_color "green" "${emoji:-🎉} $message" ;;
        "target") print_color "cyan" "${emoji:-🎯} $message" ;;
        *) echo "$message" ;;
    esac
}

# ========================================
# VALIDATION FUNCTIONS
# ========================================

# Validate that required tools are available
validate_core_dependencies() {
    local missing_tools=()

    # Check for essential tools
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    command -v cat >/dev/null 2>&1 || missing_tools+=("cat")
    command -v mkdir >/dev/null 2>&1 || missing_tools+=("mkdir")

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_status "error" "Missing core tools: ${missing_tools[*]}"
        return 1
    fi

    return 0
}

# Validate that CONFIG is properly loaded
validate_config() {
    if [ -z "$CONFIG" ]; then
        print_status "error" "CONFIG variable is not set"
        return 1
    fi

    if ! echo "$CONFIG" | jq empty 2>/dev/null; then
        print_status "error" "CONFIG contains invalid JSON"
        return 1
    fi

    return 0
}

# ========================================
# UTILITY FUNCTIONS
# ========================================

# Check if we're running in debug mode
is_debug_mode() {
    [[ "${DEBUG:-}" == "true" || "${DEBUG:-}" == "1" ]]
}

# Debug print - only shows if debug mode is enabled
debug_print() {
    if is_debug_mode; then
        print_color "cyan" "DEBUG: $*" >&2
    fi
}

# Safe directory change with validation
safe_cd() {
    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        print_status "error" "Directory does not exist: $target_dir"
        return 1
    fi

    if ! cd "$target_dir"; then
        print_status "error" "Failed to change to directory: $target_dir"
        return 1
    fi

    debug_print "Changed to directory: $(pwd)"
    return 0
}

# Create directory with validation
safe_mkdir() {
    local target_dir="$1"

    if ! mkdir -p "$target_dir"; then
        print_status "error" "Failed to create directory: $target_dir"
        return 1
    fi

    debug_print "Created directory: $target_dir"
    return 0
}

# ========================================
# MODULE SYSTEM FUNCTIONS
# ========================================

# Get the modules directory path
get_modules_dir() {
    local functions_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "$functions_dir/modules"
}

# List available modules
list_modules() {
    local modules_dir="$(get_modules_dir)"
    if [ -d "$modules_dir" ]; then
        find "$modules_dir" -name "*.sh" -type f | sort
    fi
}

# Check if a specific module exists
module_exists() {
    local module_name="$1"
    local modules_dir="$(get_modules_dir)"
    [ -f "$modules_dir/$module_name" ]
}

# ========================================
# INITIALIZATION
# ========================================

# Initialize core module
init_core_module() {
    debug_print "Initializing core module..."

    # Validate dependencies
    if ! validate_core_dependencies; then
        return 1
    fi

    # Validate configuration if CONFIG is set
    if [ -n "${CONFIG:-}" ]; then
        if ! validate_config; then
            return 1
        fi
    fi

    debug_print "Core module initialized successfully"
    return 0
}

# Export functions for use by other modules
export -f get_config get_config_array expand_path
export -f print_color print_status debug_print
export -f validate_core_dependencies validate_config
export -f is_debug_mode safe_cd safe_mkdir
export -f get_modules_dir list_modules module_exists
