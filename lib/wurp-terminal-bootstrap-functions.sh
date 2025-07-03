#!/bin/bash
# lib/wurp-terminal-bootstrap-functions.sh
# Modular coordinator for Wurp Terminal Bootstrap
# This file loads modules and provides graceful fallbacks

# ========================================
# MODULE LOADING SYSTEM
# ========================================

# Get the directory of this script
FUNCTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$FUNCTIONS_DIR/modules"

# Debug function (available immediately)
debug_print() {
    if [[ "${DEBUG:-}" == "true" || "${DEBUG:-}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Initialise module loading
init_module_system() {
    debug_print "Initialising module system..."
    debug_print "Functions dir: $FUNCTIONS_DIR"
    debug_print "Modules dir: $MODULES_DIR"

    # Check if modules directory exists
    if [ ! -d "$MODULES_DIR" ]; then
        echo "⚠️ Modules directory not found: $MODULES_DIR"
        echo "Using legacy mode..."
        return 1
    fi

    return 0
}

# Load all modules in numerical order
load_modules() {
    debug_print "Loading modules from: $MODULES_DIR"

    local loaded_count=0
    local failed_modules=()

    # Source all modules in order (00-*, 10-*, etc.)
    for module in "$MODULES_DIR"/*.sh; do
        if [ -f "$module" ]; then
            local module_name=$(basename "$module")
            debug_print "Loading module: $module_name"

            if source "$module"; then
                debug_print "✅ Successfully loaded: $module_name"
                ((loaded_count++))
            else
                echo "❌ Failed to load module: $module_name"
                failed_modules+=("$module_name")
            fi
        fi
    done

    debug_print "Loaded $loaded_count modules successfully"

    if [ ${#failed_modules[@]} -gt 0 ]; then
        echo "❌ Failed to load modules: ${failed_modules[*]}"
        return 1
    fi

    echo "✅ Modular system loaded successfully"
    return 0
}

# ========================================
# LEGACY COMPATIBILITY FUNCTIONS
# ========================================
# These provide full functionality when modules aren't available

# FIXED: Expand variables in path
expand_path() {
    local path=$1
    # Handle $HOME expansion properly
    path="${path/\$HOME/$HOME}"
    # Handle ~ expansion
    path="${path/#\~/$HOME}"
    echo "$path"
}

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
# LEGACY PROJECT STRUCTURE FUNCTIONS
# ========================================

# FIXED: Create project directory structure
create_project_structure() {
    local project_dir=$1

    print_status "folder" "Creating project directory: $project_dir"

    # Create the full project directory path
    mkdir -p "$project_dir"

    # Change to project directory - this is crucial!
    if ! cd "$project_dir"; then
        print_status "error" "Failed to change to project directory: $project_dir"
        return 1
    fi

    # Store the project root for other functions
    export PROJECT_ROOT="$(pwd)"

    print_status "working" "Creating directory structure..."

    # Create directories from config
    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            mkdir -p "$dir"
        fi
    done < <(get_config_array '.project_structure.directories')

    print_status "success" "Project structure created:"
    echo "   $project_dir/"

    # Show directory tree
    while IFS= read -r dir; do
        [ -n "$dir" ] && echo "   ├── $dir/"
    done < <(get_config_array '.project_structure.directories')

    return 0
}

# ========================================
# LEGACY FILE CREATION FUNCTIONS
# ========================================

# Create .csproj file
create_csproj_file() {
    local filename=$(get_config '.project_structure.files.csproj')
    filename="${filename:-WurpTerminal.csproj}"

    print_status "file" "Creating $filename..."

    tee "$filename" > /dev/null << 'CSPROJ_EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <AssemblyName>wurp-terminal</AssemblyName>
    <PublishSingleFile>true</PublishSingleFile>
    <PublishTrimmed>false</PublishTrimmed>
    <SelfContained>false</SelfContained>
  </PropertyGroup>
</Project>
CSPROJ_EOF
}

# Create Program.cs file (simplified main entry point)
create_program_cs() {
    local filename=$(get_config '.project_structure.files.main')
    filename="${filename:-Program.cs}"

    print_status "computer" "Creating $filename..."

    cat > "$filename" << 'EOF'
using System;
using System.Threading.Tasks;
using WurpTerminal.Core;

namespace WurpTerminal;

class Program
{
    static async Task Main(string[] args)
    {
        try
        {
            var terminal = new WurpTerminalService();

            Console.WriteLine("🚀 Wurp (Warp Terminal Clone) v1.0");
            Console.WriteLine("AI-Powered Terminal built with .NET");
            Console.WriteLine("═══════════════════════════════════════\n");

            if (args.Length > 0)
            {
                await terminal.HandleCommands(args);
            }
            else
            {
                await terminal.RunInteractiveMode();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Error: {ex.Message}");
            Environment.Exit(1);
        }
    }
}
EOF
}

# Create Core/WurpTerminalService.cs file
create_wurp_terminal_service_cs() {
    local filename="Core/WurpTerminalService.cs"

    print_status "computer" "Creating $filename..."

    mkdir -p "Core"

    cat > "$filename" << 'EOF'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace WurpTerminal.Core;

public class WurpTerminalService
{
    private readonly List<string> _history = new();
    private readonly string _historyFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".wurp_terminal_history");
    private readonly AIIntegration _ai = new();
    private readonly ThemeManager _themes = new();

    public WurpTerminalService()
    {
        LoadHistory();
        Console.CancelKeyPress += OnCancelKeyPress;
    }

    public async Task HandleCommands(string[] args)
    {
        var command = args[0].ToLower();

        switch (command)
        {
            case "ai":
                await _ai.HandleAICommands(args[1..]);
                break;
            case "theme":
                _themes.HandleThemeCommand(args[1..]);
                break;
            case "help":
                ShowHelp();
                break;
            case "version":
                Console.WriteLine("Wurp (Warp Terminal Clone) v1.0 - .NET 8");
                break;
            default:
                Console.WriteLine($"Unknown command: {command}");
                Console.WriteLine("Run 'wurp-terminal help' for available commands.");
                break;
        }
    }

    public async Task RunInteractiveMode()
    {
        Console.WriteLine("🎯 Interactive mode - Type commands or 'exit' to quit");
        Console.WriteLine("Features: History, AI commands, themes\n");

        while (true)
        {
            Console.Write($"{_themes.GetPrompt()}> ");

            var input = Console.ReadLine();

            if (string.IsNullOrWhiteSpace(input))
                continue;

            if (input.ToLower() == "exit" || input.ToLower() == "quit")
            {
                Console.WriteLine("👋 Goodbye!");
                break;
            }

            _history.Add(input);
            SaveHistory();

            await ProcessCommand(input);
            Console.WriteLine();
        }
    }

    private async Task ProcessCommand(string input)
    {
        var parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        if (await ProcessSpecialCommandAsync(parts))
            return;

        await ExecuteSystemCommand(input);
    }

    private async Task<bool> ProcessSpecialCommandAsync(string[] parts)
    {
        if (parts.Length == 0) return false;

        switch (parts[0].ToLower())
        {
            case "ai":
                await _ai.HandleAICommands(parts[1..]);
                return true;
            case "theme":
                _themes.HandleThemeCommand(parts[1..]);
                return true;
            case "clear":
                Console.Clear();
                return true;
            case "history":
                ShowHistory();
                return true;
            default:
                return false;
        }
    }

    private async Task ExecuteSystemCommand(string command)
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "/bin/bash",
                    Arguments = $"-c \"{command}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                }
            };

            process.Start();

            var output = await process.StandardOutput.ReadToEndAsync();
            var error = await process.StandardError.ReadToEndAsync();

            await process.WaitForExitAsync();

            if (!string.IsNullOrEmpty(output))
                Console.Write(output);
            if (!string.IsNullOrEmpty(error))
                Console.Write(_themes.ColorText(error, "red"));
        }
        catch (Exception ex)
        {
            Console.WriteLine(_themes.ColorText($"Error executing command: {ex.Message}", "red"));
        }
    }

    private void LoadHistory()
    {
        try
        {
            if (File.Exists(_historyFile))
            {
                var lines = File.ReadAllLines(_historyFile);
                _history.AddRange(lines);
            }
        }
        catch { /* Ignore errors */ }
    }

    private void SaveHistory()
    {
        try
        {
            File.WriteAllLines(_historyFile, _history.TakeLast(1000));
        }
        catch { /* Ignore errors */ }
    }

    private void ShowHistory()
    {
        for (int i = Math.Max(0, _history.Count - 20); i < _history.Count; i++)
        {
            Console.WriteLine($"{i + 1,3}: {_history[i]}");
        }
    }

    private void OnCancelKeyPress(object? sender, ConsoleCancelEventArgs e)
    {
        e.Cancel = true;
        Console.WriteLine("\n👋 Use 'exit' to quit gracefully");
    }

    private void ShowHelp()
    {
        Console.WriteLine("🚀 Wurp (Warp Terminal Clone) - Help");
        Console.WriteLine("═══════════════════════════════════");
        Console.WriteLine();
        Console.WriteLine("Built-in Commands:");
        Console.WriteLine("  ai explain <command>     - Explain a command");
        Console.WriteLine("  ai suggest <task>        - Get command suggestions");
        Console.WriteLine("  ai debug <error>         - Debug help");
        Console.WriteLine("  theme [name]             - Change/show theme");
        Console.WriteLine("  clear                    - Clear screen");
        Console.WriteLine("  history                  - Show command history");
        Console.WriteLine("  help                     - Show this help");
        Console.WriteLine("  exit/quit                - Exit terminal");
        Console.WriteLine();
        Console.WriteLine("Features:");
        Console.WriteLine("  • Command history");
        Console.WriteLine("  • AI-powered assistance");
        Console.WriteLine("  • Multiple themes");
        Console.WriteLine("  • System command execution");
    }
}
EOF
}

# Create Core/AIIntegration.cs file
create_ai_integration_cs() {
    local filename="Core/AIIntegration.cs"

    print_status "computer" "Creating $filename..."

    mkdir -p "Core"

    cat > "$filename" << 'EOF'
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace WurpTerminal.Core;

public class AIIntegration
{
    public async Task HandleAICommands(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("AI command requires subcommand (explain, suggest, debug)");
            return;
        }

        var subcommand = args[0].ToLower();
        var prompt = string.Join(" ", args[1..]);

        Console.WriteLine($"🤖 AI {subcommand}: {prompt}");

        var aiResponse = await CallFreelanceAI(subcommand, prompt);
        if (aiResponse != null)
        {
            Console.WriteLine($"✨ {aiResponse}");
        }
        else
        {
            Console.WriteLine("🔧 FreelanceAI API not available - using local fallback");
            await LocalAIFallback(subcommand, prompt);
        }
    }

    private async Task<string?> CallFreelanceAI(string subcommand, string prompt)
    {
        try
        {
            using var client = new HttpClient();
            client.Timeout = TimeSpan.FromSeconds(30);

            var response = await client.GetAsync("http://localhost:5000/health");
            if (response.IsSuccessStatusCode)
            {
                return $"AI response for '{prompt}' (via FreelanceAI)";
            }
        }
        catch { }

        return null;
    }

    private async Task LocalAIFallback(string subcommand, string prompt)
    {
        await Task.Delay(500);

        switch (subcommand)
        {
            case "explain":
                Console.WriteLine($"📖 Command explanation for: {prompt}");
                Console.WriteLine("This is a local fallback explanation.");
                break;
            case "suggest":
                Console.WriteLine($"💡 Suggestions for: {prompt}");
                Console.WriteLine("• Try using 'man' command for documentation");
                Console.WriteLine("• Use '--help' flag for command options");
                break;
            case "debug":
                Console.WriteLine($"🔍 Debug help for: {prompt}");
                Console.WriteLine("• Check error logs");
                Console.WriteLine("• Verify command syntax");
                Console.WriteLine("• Check file permissions");
                break;
        }
    }
}
EOF
}

# Create Core/ThemeManager.cs file
create_theme_manager_cs() {
    local filename="Core/ThemeManager.cs"

    print_status "computer" "Creating $filename..."

    mkdir -p "Core"

    cat > "$filename" << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;

namespace WurpTerminal.Core;

public class ThemeManager
{
    private readonly Dictionary<string, Dictionary<string, string>> _themes = new()
    {
        ["default"] = new()
        {
            ["prompt"] = "\x1b[36mwurp",
            ["red"] = "\x1b[31m",
            ["green"] = "\x1b[32m",
            ["yellow"] = "\x1b[33m",
            ["blue"] = "\x1b[34m",
            ["reset"] = "\x1b[0m"
        },
        ["dark"] = new()
        {
            ["prompt"] = "\x1b[35mwurp",
            ["red"] = "\x1b[91m",
            ["green"] = "\x1b[92m",
            ["yellow"] = "\x1b[93m",
            ["blue"] = "\x1b[94m",
            ["reset"] = "\x1b[0m"
        },
        ["wurp"] = new()
        {
            ["prompt"] = "\x1b[96m❯",
            ["red"] = "\x1b[91m",
            ["green"] = "\x1b[92m",
            ["yellow"] = "\x1b[93m",
            ["blue"] = "\x1b[96m",
            ["reset"] = "\x1b[0m"
        }
    };

    private string _currentTheme = "default";

    public void HandleThemeCommand(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine($"Current theme: {_currentTheme}");
            Console.WriteLine("Available themes:");
            foreach (var theme in _themes.Keys)
            {
                Console.WriteLine($"  • {theme}");
            }
            return;
        }

        var themeName = args[0].ToLower();
        if (_themes.ContainsKey(themeName))
        {
            _currentTheme = themeName;
            Console.WriteLine($"✅ Theme changed to: {themeName}");
        }
        else
        {
            Console.WriteLine($"❌ Unknown theme: {themeName}");
        }
    }

    public string GetPrompt() => _themes[_currentTheme]["prompt"] + _themes[_currentTheme]["reset"];

    public string ColorText(string text, string color) =>
        _themes[_currentTheme].GetValueOrDefault(color, "") + text + _themes[_currentTheme]["reset"];
}
EOF
}

# NEW: Create Core class files function for better organisation
create_core_files() {
    print_status "working" "Creating Core class files..."

    create_wurp_terminal_service_cs || { print_status "error" "Failed to create WurpTerminalService.cs"; return 1; }
    create_ai_integration_cs || { print_status "error" "Failed to create AIIntegration.cs"; return 1; }
    create_theme_manager_cs || { print_status "error" "Failed to create ThemeManager.cs"; return 1; }

    print_status "success" "Core class files created"
}

# Create modules directory and basic module files
create_modules() {
    local modules_dir="scripts/lib/modules"
    
    print_status "wrench" "Creating modular system..."
    
    # Ensure modules directory exists
    mkdir -p "$modules_dir"
    
    # Copy basic module templates from bootstrap
    local bootstrap_modules_dir="$SCRIPT_DIR/scripts/lib/modules"
    
    if [ -d "$bootstrap_modules_dir" ]; then
        cp "$bootstrap_modules_dir"/*.sh "$modules_dir/" 2>/dev/null || true
        print_status "success" "Module templates copied"
    else
        # Create basic stub modules if bootstrap modules don't exist
        cat > "$modules_dir/00-core.sh" << 'MODULE_EOF'
#!/bin/bash
# 00-core.sh
# Core utilities for Wurp (Warp Terminal Clone)

# Core utility functions will be loaded first
print_status "info" "Core module loaded"
MODULE_EOF

        cat > "$modules_dir/10-project.sh" << 'MODULE_EOF'
#!/bin/bash
# 10-project.sh
# Project management functions for Wurp (Warp Terminal Clone)

# Project management functions
print_status "info" "Project module loaded"
MODULE_EOF

        cat > "$modules_dir/20-files.sh" << 'MODULE_EOF'
#!/bin/bash
# 20-files.sh
# File generation functions for Wurp (Warp Terminal Clone)

# File generation functions
print_status "info" "Files module loaded"
MODULE_EOF
        
        print_status "success" "Module stubs created"
    fi
    
    # Make modules executable
    chmod +x "$modules_dir"/*.sh 2>/dev/null || true
}

# Create wurp-config.json
create_wurp_config() {
    local filename=$(get_config '.project_structure.files.config')
    filename="${filename:-wurp-config.json}"

    print_status "gear" "Creating $filename..."

    # Extract project config from bootstrap config and write using tee
    echo "$CONFIG" | jq '.project_config' | tee "$filename" > /dev/null
}

# Create README.md
create_readme() {
    local filename=$(get_config '.project_structure.files.readme')
    filename="${filename:-README.md}"

    print_status "book" "Creating $filename..."

    local project_name=$(get_config '.project_config.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"

    cat > "$filename" << README_EOF
# 🚀 $project_name

A feature-rich terminal emulator built with .NET 8, featuring AI integration, command history, auto-completion, and themes.

## Quick Start

\`\`\`bash
# Check dependencies
./scripts/wurp-terminal check

# Install everything
./scripts/wurp-terminal install

# Run the terminal
wurp-terminal
\`\`\`

## Features

- 🤖 AI Integration (FreelanceAI compatible)
- 📜 Command History
- ⚡ Auto-completion
- 🎨 Multiple themes (default, dark, wurp)
- 🐚 Multi-shell support (bash/zsh)
- ⚙️ JSON configuration
- 🔧 Modular architecture

## Usage

\`\`\`bash
# AI commands
ai explain "docker ps"
ai suggest "deploy app"
ai debug "permission denied"

# Built-in commands
theme wurp
clear
history
help
\`\`\`

## Project Structure

- \`Program.cs\` - Main entry point
- \`Core/\` - Core application classes
  - \`WurpTerminalService.cs\` - Main terminal service
  - \`AIIntegration.cs\` - AI integration logic
  - \`ThemeManager.cs\` - Theme management
- \`wurp-config.json\` - Centralised configuration
- \`scripts/wurp-terminal\` - Installation script
- \`scripts/lib/wurp-terminal-functions.sh\` - Function library

Built with ❤️ using .NET 8
README_EOF
}

# Create function library for wurp terminal
create_wurp_functions() {
    local filename=$(get_config '.project_structure.files.functions')
    filename="${filename:-scripts/lib/wurp-terminal-functions.sh}"

    print_status "wrench" "Creating $filename..."

    # Ensure the directory exists
    local dir_path=$(dirname "$filename")
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        print_status "info" "Created directory: $dir_path"
    fi

    # Copy the functions we created in 20-files.sh module
    cat > "$filename" << 'FUNCTIONS_EOF'
#!/bin/bash
# lib/wurp-terminal-functions.sh
# Function library for Wurp (Warp Terminal Clone)

# Legacy compatibility until full modular migration
get_config() {
    local path=$1
    echo "$CONFIG" | jq -r "$path // empty" 2>/dev/null
}

expand_path() {
    local path=$1
    echo "${path/\$HOME/$HOME}"
}

print_color() {
    local color_name=$1
    local message=$2
    case $color_name in
        "red") echo -e "\033[0;31m${message}\033[0m" ;;
        "green") echo -e "\033[0;32m${message}\033[0m" ;;
        "yellow") echo -e "\033[1;33m${message}\033[0m" ;;
        "blue") echo -e "\033[0;34m${message}\033[0m" ;;
        "cyan") echo -e "\033[0;36m${message}\033[0m" ;;
        *) echo "$message" ;;
    esac
}

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") print_color "green" "✅ $message" ;;
        "error") print_color "red" "❌ $message" ;;
        "warning") print_color "yellow" "⚠️  $message" ;;
        "info") print_color "cyan" "ℹ️  $message" ;;
        "working") print_color "yellow" "🔨 $message" ;;
        *) echo "$message" ;;
    esac
}

# Basic dependency check
check_dependencies() {
    print_status "working" "Checking dependencies..."
    local missing_deps=()
    local has_errors=false

    if ! command -v dotnet &> /dev/null; then
        missing_deps+=(".NET 8 SDK: Install from https://dotnet.microsoft.com/download")
        has_errors=true
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq: sudo apt install jq (Ubuntu) or brew install jq (macOS)")
        has_errors=true
    fi

    if [ "$has_errors" = true ]; then
        print_status "error" "Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            print_color "yellow" "  • $dep"
        done
        return 1
    fi

    print_status "success" "All dependencies satisfied"
    return 0
}

# Basic build function
build_app() {
    print_status "working" "Building application..."
    cd "$PROJECT_ROOT" || return 1

    if dotnet build -c Release; then
        print_status "success" "Build successful"
        return 0
    else
        print_status "error" "Build failed"
        return 1
    fi
}

# Basic publish function
publish_app() {
    print_status "working" "Publishing application..."
    cd "$PROJECT_ROOT" || return 1

    if dotnet publish -c Release --self-contained false; then
        print_status "success" "Publish successful"
        return 0
    else
        print_status "error" "Publish failed"
        return 1
    fi
}

# Basic run function
run_app() {
    local binary_name="wurp-terminal"
    local search_paths=(
        "bin/Release/net9.0/linux-x64/publish/$binary_name"
        "bin/Release/net9.0/publish/$binary_name"
        "bin/Release/net9.0/linux-x64/$binary_name"
        "bin/Release/net9.0/linux-x64/publish/$binary_name.dll"
        "bin/Release/net9.0/publish/$binary_name.dll"
    )

    for path in "${search_paths[@]}"; do
        if [ -f "$PROJECT_ROOT/$path" ]; then
            if [[ "$path" == *.dll ]]; then
                exec dotnet "$PROJECT_ROOT/$path" "$@"
            else
                exec "$PROJECT_ROOT/$path" "$@"
            fi
            return 0
        fi
    done

    print_status "error" "Application not found. Please build first."
    return 1
}

# Basic status function
show_status() {
    print_color "cyan" "🚀 Wurp Terminal Status"
    echo ""

    if [ -f "$PROJECT_ROOT/bin/Release/net8.0/publish/wurp-terminal" ] || [ -f "$PROJECT_ROOT/bin/Release/net8.0/publish/wurp-terminal.dll" ]; then
        print_status "success" "Application built and published"
    else
        print_status "error" "Application not built"
    fi
}

# Basic help function
show_help() {
    print_color "cyan" "Wurp (Warp Terminal Clone) - Build & Installation Script"
    echo ""
    print_color "yellow" "Usage:"
    echo "  ./scripts/wurp-terminal [command] [options]"
    echo ""
    print_color "yellow" "Commands:"
    echo "  build         - Build the application"
    echo "  publish       - Build and publish"
    echo "  run           - Run the application"
    echo "  status        - Show installation status"
    echo "  check         - Check dependencies"
    echo "  help          - Show this help"
}

# Stub functions (to be implemented in future modules)
install_shell_integration() {
    print_status "info" "Shell integration not yet implemented"
}

create_desktop_entry() {
    print_status "info" "Desktop integration not yet implemented"
}

check_freelance_ai() {
    print_status "info" "Service checks not yet implemented"
}

check_ollama() {
    print_status "info" "Service checks not yet implemented"
}

uninstall() {
    print_status "info" "Uninstall not yet implemented"
}
FUNCTIONS_EOF

    chmod +x "$filename"
}

# Create main launcher script
create_main_launcher() {
    local filename=$(get_config '.project_structure.files.main_script')
    filename="${filename:-scripts/wurp-terminal}"

    print_status "rocket" "Creating $filename..."

    cat > "$filename" << 'LAUNCHER_EOF'
#!/bin/bash
# scripts/wurp-terminal
# Main launcher script for Wurp (Warp Terminal Clone)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CONFIG_FILE="$PROJECT_ROOT/wurp-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

CONFIG=$(cat "$CONFIG_FILE")

FUNCTIONS_FILE="$SCRIPT_DIR/lib/wurp-terminal-functions.sh"
if [ -f "$FUNCTIONS_FILE" ]; then
    export SCRIPT_DIR PROJECT_ROOT CONFIG
    source "$FUNCTIONS_FILE"
else
    echo "❌ Function library not found: $FUNCTIONS_FILE"
    exit 1
fi

main() {
    local command=${1:-help}
    shift || true

    case $command in
        "build")
            check_dependencies && build_app
            ;;
        "publish")
            check_dependencies && build_app && publish_app
            ;;
        "install")
            check_dependencies && build_app && publish_app && \
            print_status "success" "🎉 Installation complete!" && show_status
            ;;
        "run")
            check_dependencies && run_app "$@"
            ;;
        "status")
            show_status
            ;;
        "check")
            check_dependencies
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
LAUNCHER_EOF

    chmod +x "$filename"
}

# ========================================
# MAIN BOOTSTRAP ORCHESTRATION
# ========================================

# Execute the bootstrap process with modular support
execute_bootstrap_with_args() {
    local base_dir="$1"
    local project_name="$2"

    print_color "cyan" "🚀 Creating Wurp (Warp Terminal Clone) Project Structure"
    print_color "cyan" "=================================================="
    echo ""

    local project_dir="$base_dir/$project_name"

    debug_print "Using provided base_dir: '$base_dir'"
    debug_print "Using provided project_name: '$project_name'"
    debug_print "final project_dir: '$project_dir'"
    echo ""

    # Initialise module system
    if ! init_module_system; then
        print_status "warning" "Module system not available, using legacy mode"
    else
        # Try to load modules
        if load_modules; then
            debug_print "Modular system loaded successfully"
        else
            print_status "warning" "Module loading failed, using legacy mode"
        fi
    fi

    # Create project structure and change to it
    if ! create_project_structure "$project_dir"; then
        print_status "error" "Failed to create project structure"
        return 1
    fi

    # Verify we're in the right directory
    print_status "info" "Current working directory: $(pwd)"
    echo ""

    # Create all project files
    print_status "working" "Creating project files..."

    # Use modular functions if available, otherwise use legacy individual functions
    if command -v create_all_project_files &> /dev/null; then
        create_all_project_files || { print_status "error" "Failed to create project files"; return 1; }
    else
        # Legacy file creation
        debug_print "Using legacy file creation mode"
        create_csproj_file || { print_status "error" "Failed to create .csproj file"; return 1; }
        create_program_cs || { print_status "error" "Failed to create Program.cs"; return 1; }
        create_core_files || { print_status "error" "Failed to create Core files"; return 1; }
        create_wurp_config || { print_status "error" "Failed to create wurp-config.json"; return 1; }
        create_readme || { print_status "error" "Failed to create README.md"; return 1; }
    fi

    create_wurp_functions || { print_status "error" "Failed to create functions library"; return 1; }
    create_main_launcher || { print_status "error" "Failed to create main launcher"; return 1; }

    # Make scripts executable
    local main_script="scripts/wurp-terminal"
    local functions_script="scripts/lib/wurp-terminal-functions.sh"

    if [ -f "$main_script" ]; then
        chmod +x "$main_script"
        print_status "success" "Made executable: $main_script"
    fi

    if [ -f "$functions_script" ]; then
        chmod +x "$functions_script"
        print_status "success" "Made executable: $functions_script"
    fi

    # Final status
    echo ""
    print_status "party" "Wurp Terminal project structure created successfully!"
    echo ""
    print_status "folder" "Project location: $project_dir"
    echo ""
    print_status "rocket" "Next steps:"
    echo "   cd \"$project_dir\""
    echo "   ./scripts/wurp-terminal check    # Check dependencies"
    echo "   ./scripts/wurp-terminal install  # Build and install"
    echo "   wurp-terminal                    # Run the terminal"
    echo ""
    print_status "success" "All files created:"
    echo "   ├── Program.cs (Main entry point)"
    echo "   ├── Core/ (Modular class architecture)"
    echo "   │   ├── WurpTerminalService.cs"
    echo "   │   ├── AIIntegration.cs"
    echo "   │   └── ThemeManager.cs"
    echo "   ├── WurpTerminal.csproj"
    echo "   ├── wurp-config.json (Complete configuration)"
    echo "   ├── scripts/wurp-terminal (Main launcher)"
    echo "   ├── scripts/lib/wurp-terminal-functions.sh (Function library)"
    echo "   └── README.md"
    echo ""
    print_status "target" "The project is ready for testing!"
    echo ""

    # Show modular upgrade path
    if ! init_module_system; then
        print_status "info" "💡 To enable full modular functionality:"
        echo "   1. Create lib/modules/ directory in your bootstrap project"
        echo "   2. Add the modular function files:"
        echo "      • 00-core.sh (Core utilities)"
        echo "      • 10-project.sh (Project structure)"
        echo "      • 20-files.sh (File generation)"
        echo "   3. Test with DEBUG=true to see module loading"
        echo "   4. Enjoy enhanced maintainability and development experience!"
        echo ""
        print_status "success" "Generated projects will automatically detect and use modules when available"
    fi

    return 0
}

# Keep the old function for backward compatibility
execute_bootstrap() {
    # Get project directory from config with proper expansion
    local base_dir=$(get_config '.bootstrap.base_dir')
    local project_subdir=$(get_config '.bootstrap.project_subdir')

    # If config values are empty, use defaults
    if [ -z "$base_dir" ]; then
        base_dir="$HOME/Development"
    fi

    if [ -z "$project_subdir" ]; then
        project_subdir="wurp-terminal"
    fi

    # Expand the base directory first
    base_dir=$(expand_path "$base_dir")

    # Call the new function with extracted values
    execute_bootstrap_with_args "$base_dir" "$project_subdir"
}

# ========================================
# MODULE SYSTEM INITIALISATION
# ========================================

# Initialise the module system when this file is sourced
if init_module_system; then
    if load_modules; then
        debug_print "Bootstrap coordinator: Modular system active"
    else
        debug_print "Bootstrap coordinator: Module loading failed, using legacy mode"
    fi
else
    debug_print "Bootstrap coordinator: No modules found, using legacy mode"
fi

# Export key functions for external use
export -f execute_bootstrap execute_bootstrap_with_args
export -f print_status print_color get_config expand_path debug_print

# Export all legacy functions to ensure compatibility
export -f create_project_structure create_csproj_file create_program_cs
export -f create_wurp_terminal_service_cs create_ai_integration_cs create_theme_manager_cs
export -f create_core_files create_wurp_config create_readme
export -f create_wurp_functions create_main_launcher