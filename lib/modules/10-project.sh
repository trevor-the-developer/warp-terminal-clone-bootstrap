#!/bin/bash
# scripts/lib/modules/10-project.sh
# Project structure creation module for Wurp Terminal Bootstrap
# This module handles directory creation and project setup

# ========================================
# PROJECT STRUCTURE FUNCTIONS
# ========================================

# Create project directory structure
create_project_structure() {
    local project_dir=$1

    print_status "folder" "Creating project directory: $project_dir"

    # Create the full project directory path
    if ! safe_mkdir "$project_dir"; then
        return 1
    fi

    # Change to project directory - this is crucial!
    if ! safe_cd "$project_dir"; then
        return 1
    fi

    # Store the project root for other functions
    export PROJECT_ROOT="$(pwd)"
    debug_print "PROJECT_ROOT set to: $PROJECT_ROOT"

    print_status "working" "Creating directory structure..."

    # Create directories from config
    local created_dirs=()
    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            if safe_mkdir "$dir"; then
                created_dirs+=("$dir")
                debug_print "Created directory: $dir"
            else
                print_status "error" "Failed to create directory: $dir"
                return 1
            fi
        fi
    done < <(get_config_array '.project_structure.directories')

    print_status "success" "Project structure created:"
    echo "   $project_dir/"

    # Show directory tree
    for dir in "${created_dirs[@]}"; do
        echo "   ├── $dir/"
    done

    return 0
}

# Validate project structure
validate_project_structure() {
    local project_dir="$1"

    debug_print "Validating project structure in: $project_dir"

    # Check if we're in the right directory
    if [ "$(pwd)" != "$project_dir" ]; then
        print_status "warning" "Not in expected project directory"
        print_status "info" "Expected: $project_dir"
        print_status "info" "Current: $(pwd)"
    fi

    # Check if required directories exist
    local missing_dirs=()
    while IFS= read -r dir; do
        if [ -n "$dir" ] && [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done < <(get_config_array '.project_structure.directories')

    if [ ${#missing_dirs[@]} -gt 0 ]; then
        print_status "warning" "Missing directories: ${missing_dirs[*]}"
        return 1
    fi

    print_status "success" "Project structure validation passed"
    return 0
}

# Setup directory permissions
setup_directory_permissions() {
    debug_print "Setting up directory permissions..."

    # Make sure scripts directory is executable
    if [ -d "scripts" ]; then
        chmod +x scripts 2>/dev/null || true
        debug_print "Set execute permission on scripts directory"
    fi

    # Make sure lib directory is accessible
    if [ -d "scripts/lib" ]; then
        chmod +x scripts/lib 2>/dev/null || true
        debug_print "Set execute permission on scripts/lib directory"
    fi

    return 0
}

# Initialize project workspace
init_project_workspace() {
    local project_dir="$1"

    debug_print "Initializing project workspace..."

    # Create basic .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        create_gitignore
    fi

    # Set up directory permissions
    setup_directory_permissions

    # Create any additional workspace files
    setup_workspace_files

    print_status "success" "Project workspace initialized"
}

# Create .gitignore file
create_gitignore() {
    debug_print "Creating .gitignore file..."

    cat > ".gitignore" << 'GITIGNORE_EOF'
# Build results
bin/
obj/
*.user
*.suo
*.cache
*.docstates

# Visual Studio
.vs/
*.vssscc
*.vspscc

# .NET Core
project.lock.json
project.fragment.lock.json
artifacts/

# Logs
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/

# Local development
*.local.*
GITIGNORE_EOF

    debug_print "Created .gitignore file"
}

# Setup additional workspace files
setup_workspace_files() {
    debug_print "Setting up additional workspace files..."

    # Create .editorconfig for consistent coding style
    if [ ! -f ".editorconfig" ]; then
        create_editorconfig
    fi

    return 0
}

# Create .editorconfig file
create_editorconfig() {
    debug_print "Creating .editorconfig file..."

    cat > ".editorconfig" << 'EDITORCONFIG_EOF'
# EditorConfig is awesome: https://EditorConfig.org

root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{cs,csx}]
indent_size = 4

[*.{js,ts,json}]
indent_size = 2

[*.{yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.sh]
indent_size = 4
EDITORCONFIG_EOF

    debug_print "Created .editorconfig file"
}

# Clean up project directory (for development)
cleanup_project_structure() {
    local project_dir="$1"

    print_status "working" "Cleaning up project structure..."

    # Remove build artifacts if they exist
    local cleanup_dirs=("bin" "obj")
    for dir in "${cleanup_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            debug_print "Removed directory: $dir"
        fi
    done

    print_status "success" "Project cleanup completed"
}

# Show project structure tree
show_project_tree() {
    local max_depth="${1:-2}"

    print_status "info" "Project structure:"

    if command -v tree >/dev/null 2>&1; then
        tree -L "$max_depth" -a
    else
        # Fallback tree display
        find . -maxdepth "$max_depth" -type d | sed 's|[^/]*/|  |g; s|/| /|' | sort
    fi
}

# ========================================
# PROJECT VALIDATION FUNCTIONS
# ========================================

# Validate project prerequisites
validate_project_prerequisites() {
    debug_print "Validating project prerequisites..."

    # Check if we have write permissions in the target directory
    local parent_dir="$(dirname "$1")"
    if [ ! -w "$parent_dir" ]; then
        print_status "error" "No write permission in parent directory: $parent_dir"
        return 1
    fi

    # Check available disk space (basic check)
    local available_space=$(df "$parent_dir" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10240 ]; then  # Less than ~10MB
        print_status "warning" "Low disk space available"
    fi

    return 0
}

# ========================================
# EXPORT FUNCTIONS
# ========================================

# Export functions for use by other modules
export -f create_project_structure validate_project_structure
export -f setup_directory_permissions init_project_workspace
export -f create_gitignore create_editorconfig
export -f cleanup_project_structure show_project_tree
export -f validate_project_prerequisites
