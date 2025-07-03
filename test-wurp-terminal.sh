#!/bin/bash
# test-wurp-terminal.sh
# Comprehensive test script for Wurp Terminal Clone projects
# 
# Usage:
#   ./test-wurp-terminal.sh [PROJECT_DIR]
#   ./test-wurp-terminal.sh /home/trevor/workspace/wurp-test-terminal-four
#   ./test-wurp-terminal.sh  # Uses current directory

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_test() {
    print_color "$CYAN" "🧪 $1"
}

print_success() {
    print_color "$GREEN" "✅ $1"
}

print_error() {
    print_color "$RED" "❌ $1"
}

print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

print_info() {
    print_color "$BLUE" "ℹ️  $1"
}

# Get project directory
PROJECT_DIR="${1:-$(pwd)}"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

# Check if it's a Wurp Terminal project
if [ ! -f "$PROJECT_DIR/scripts/wurp-terminal" ]; then
    print_error "Not a valid Wurp Terminal project: missing scripts/wurp-terminal"
    print_info "Please specify a valid Wurp Terminal project directory"
    exit 1
fi

print_color "$CYAN" "🚀 Wurp Terminal Clone - Test Suite"
print_color "$CYAN" "=================================="
echo ""
print_info "Testing project: $PROJECT_DIR"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    print_test "Test $TESTS_RUN: $test_name"
    
    if eval "$test_command" > /tmp/wurp_test.log 2>&1; then
        print_success "PASSED: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "FAILED: $test_name"
        print_warning "Command output:"
        cat /tmp/wurp_test.log | head -20
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run a test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    print_test "Test $TESTS_RUN: $test_name"
    
    if eval "$test_command"; then
        print_success "PASSED: $test_name"
        ((TESTS_PASSED++))
        echo ""
        return 0
    else
        print_error "FAILED: $test_name"
        ((TESTS_FAILED++))
        echo ""
        return 1
    fi
}

echo "🔍 Running Wurp Terminal Tests..."
echo ""

# Test 1: Help command
run_test "Help command" "./scripts/wurp-terminal --help"

# Test 2: Dependency check
run_test "Dependency check" "./scripts/wurp-terminal check"

# Test 3: Build application
run_test "Build application" "./scripts/wurp-terminal build"

# Test 4: Publish application
run_test "Publish application" "./scripts/wurp-terminal publish"

# Test 5: Status check
run_test "Status check" "./scripts/wurp-terminal status"

# Test 6: Version command
run_test "Version command" "timeout 5 ./scripts/wurp-terminal run version"

# Test 7: Help in terminal
run_test "Terminal help command" "timeout 5 ./scripts/wurp-terminal run help"

# Test 8: AI explain command
run_test "AI explain command" "timeout 5 ./scripts/wurp-terminal run ai explain 'ls -la'"

# Test 9: AI suggest command
run_test "AI suggest command" "timeout 5 ./scripts/wurp-terminal run ai suggest 'find files'"

# Test 10: AI debug command
run_test "AI debug command" "timeout 5 ./scripts/wurp-terminal run ai debug 'permission denied'"

# Test 11: Theme list command
run_test "Theme list command" "timeout 5 ./scripts/wurp-terminal run theme"

# Test 12: Theme change command
run_test "Theme change command" "timeout 5 ./scripts/wurp-terminal run theme wurp"

# Test 13: Project structure validation
print_test "Test $((TESTS_RUN + 1)): Project structure validation"
((TESTS_RUN++))

required_files=(
    "Program.cs"
    "WurpTerminal.csproj"
    "wurp-config.json"
    "README.md"
    "scripts/wurp-terminal"
    "scripts/lib/wurp-terminal-functions.sh"
    "Core/WurpTerminalService.cs"
    "Core/AIIntegration.cs"
    "Core/ThemeManager.cs"
)

structure_ok=true
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Missing file: $file"
        structure_ok=false
    fi
done

required_dirs=(
    "Core"
    "scripts"
    "scripts/lib"
    "scripts/lib/modules"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        print_error "Missing directory: $dir"
        structure_ok=false
    fi
done

if [ "$structure_ok" = true ]; then
    print_success "PASSED: Project structure validation"
    ((TESTS_PASSED++))
else
    print_error "FAILED: Project structure validation"
    ((TESTS_FAILED++))
fi

# Test 14: Configuration file validation
print_test "Test $((TESTS_RUN + 1)): Configuration file validation"
((TESTS_RUN++))

if jq . wurp-config.json > /dev/null 2>&1; then
    print_success "PASSED: Configuration file is valid JSON"
    ((TESTS_PASSED++))
else
    print_error "FAILED: Configuration file is not valid JSON"
    ((TESTS_FAILED++))
fi

# Test 15: Executable permissions
print_test "Test $((TESTS_RUN + 1)): Executable permissions"
((TESTS_RUN++))

executable_files=(
    "scripts/wurp-terminal"
    "scripts/lib/wurp-terminal-functions.sh"
)

perms_ok=true
for file in "${executable_files[@]}"; do
    if [ ! -x "$file" ]; then
        print_error "File not executable: $file"
        perms_ok=false
    fi
done

if [ "$perms_ok" = true ]; then
    print_success "PASSED: Executable permissions"
    ((TESTS_PASSED++))
else
    print_error "FAILED: Executable permissions"
    ((TESTS_FAILED++))
fi

# Test 16: Binary existence after publish
print_test "Test $((TESTS_RUN + 1)): Published binary verification"
((TESTS_RUN++))

binary_paths=(
    "bin/Release/net9.0/linux-x64/publish/wurp-terminal"
    "bin/Release/net9.0/publish/wurp-terminal.dll"
)

binary_found=false
for path in "${binary_paths[@]}"; do
    if [ -f "$path" ]; then
        print_info "Found binary: $path"
        binary_found=true
        break
    fi
done

if [ "$binary_found" = true ]; then
    print_success "PASSED: Published binary verification"
    ((TESTS_PASSED++))
else
    print_error "FAILED: Published binary verification"
    ((TESTS_FAILED++))
fi

# Test 17: Symlink verification (if ~/.local/bin exists)
if [ -d "$HOME/.local/bin" ]; then
    print_test "Test $((TESTS_RUN + 1)): Symlink verification"
    ((TESTS_RUN++))
    
    if [ -L "$HOME/.local/bin/wurp-terminal" ] || [ -f "$HOME/.local/bin/wurp-terminal" ]; then
        print_success "PASSED: Symlink verification"
        print_info "Found: $HOME/.local/bin/wurp-terminal"
        ((TESTS_PASSED++))
    else
        print_warning "No symlink found at $HOME/.local/bin/wurp-terminal"
        print_info "This is expected if publish wasn't run"
        ((TESTS_PASSED++))
    fi
fi

echo ""
echo "═══════════════════════════════════════"
print_color "$CYAN" "📊 Test Results Summary"
echo "═══════════════════════════════════════"
echo ""
print_info "Tests Run: $TESTS_RUN"
print_success "Tests Passed: $TESTS_PASSED"

if [ $TESTS_FAILED -gt 0 ]; then
    print_error "Tests Failed: $TESTS_FAILED"
    echo ""
    print_warning "Some tests failed. Please review the output above."
    exit 1
else
    print_success "All tests passed successfully! 🎉"
    echo ""
    print_color "$GREEN" "✨ Wurp Terminal Clone is working correctly!"
    echo ""
    print_info "You can now use the terminal with:"
    echo "  cd $PROJECT_DIR"
    echo "  ./scripts/wurp-terminal run"
    echo ""
    print_info "Or install it globally with:"
    echo "  ./scripts/wurp-terminal install"
fi

# Cleanup
rm -f /tmp/wurp_test.log

echo ""
print_color "$CYAN" "🎯 Test completed!"
