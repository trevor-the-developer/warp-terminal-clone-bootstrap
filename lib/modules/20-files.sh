#!/bin/bash
# scripts/lib/modules/20-files.sh
# File generation module for Wurp Terminal Bootstrap
# This module handles creation of all project files

# ========================================
# PROJECT FILES
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
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <AssemblyName>wurp-terminal</AssemblyName>
    <PublishSingleFile>true</PublishSingleFile>
    <PublishTrimmed>false</PublishTrimmed>
    <SelfContained>false</SelfContained>
  </PropertyGroup>
</Project>
CSPROJ_EOF

    debug_print "Created $filename successfully"
}

# Create Program.cs file (main entry point)
create_program_cs() {
    local filename=$(get_config '.project_structure.files.main')
    filename="${filename:-Program.cs}"

    print_status "computer" "Creating $filename..."

    cat > "$filename" << 'PROGRAM_EOF'
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
PROGRAM_EOF

    debug_print "Created $filename successfully"
}

# ========================================
# CORE CLASS FILES
# ========================================

# Create Core/WurpTerminalService.cs file
create_wurp_terminal_service_cs() {
    local filename="Core/WurpTerminalService.cs"

    print_status "computer" "Creating $filename..."

    # Ensure Core directory exists
    safe_mkdir "Core"

    cat > "$filename" << 'SERVICE_EOF'
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

            // Add to history
            _history.Add(input);
            SaveHistory();

            // Process command
            await ProcessCommand(input);
            Console.WriteLine();
        }
    }

    private async Task ProcessCommand(string input)
    {
        var parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        if (await ProcessSpecialCommandAsync(parts))
            return;

        // Execute system command
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
SERVICE_EOF

    debug_print "Created $filename successfully"
}

# Create Core/AIIntegration.cs file
create_ai_integration_cs() {
    local filename="Core/AIIntegration.cs"

    print_status "computer" "Creating $filename..."

    # Ensure Core directory exists
    safe_mkdir "Core"

    cat > "$filename" << 'AI_EOF'
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
            Console.WriteLine("AI command requires subcommand:");
            Console.WriteLine("  ai explain <command>     - Explain a command or concept");
            Console.WriteLine("  ai suggest <task>        - Get suggestions for a task");
            Console.WriteLine("  ai debug <error>         - Debug help for errors");
            Console.WriteLine("  ai code <task>          - Generate code");
            Console.WriteLine("  ai review <code>        - Review code");
            Console.WriteLine("  ai optimise <task>      - Optimisation suggestions");
            Console.WriteLine("  ai test <task>          - Testing guidance");
            return;
        }

        var subcommand = args[0].ToLower();
        var prompt = string.Join(" ", args[1..]);

        if (string.IsNullOrWhiteSpace(prompt))
        {
            Console.WriteLine($"❌ Please provide a prompt for 'ai {subcommand}'");
            return;
        }

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

            // Check FreelanceAI health first
            var healthResponse = await client.GetAsync("http://localhost:5000/health");
            if (!healthResponse.IsSuccessStatusCode)
                return null;

            // Create AI request based on subcommand
            var aiPrompt = FormatPromptForSubcommand(subcommand, prompt);
            var requestBody = new
            {
                prompt = aiPrompt,
                maxTokens = 500,
                temperature = 0.7m
            };

            var jsonContent = System.Text.Json.JsonSerializer.Serialize(requestBody);
            var content = new StringContent(jsonContent, System.Text.Encoding.UTF8, "application/json");

            var response = await client.PostAsync("http://localhost:5000/api/ai/generate", content);
            if (response.IsSuccessStatusCode)
            {
                var responseText = await response.Content.ReadAsStringAsync();
                var jsonResponse = System.Text.Json.JsonDocument.Parse(responseText);

                if (jsonResponse.RootElement.TryGetProperty("success", out var success) && success.GetBoolean())
                {
                    if (jsonResponse.RootElement.TryGetProperty("content", out var contentProp))
                    {
                        var aiContent = contentProp.GetString();
                        var provider = jsonResponse.RootElement.TryGetProperty("provider", out var providerProp)
                            ? providerProp.GetString() : "Unknown";
                        var cost = jsonResponse.RootElement.TryGetProperty("cost", out var costProp)
                            ? costProp.GetDecimal() : 0m;

                        Console.WriteLine($"📊 Provider: {provider} | Cost: ${cost:F4}");
                        return aiContent;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"🚨 FreelanceAI Error: {ex.Message}");
        }

        return null;
    }

    private string FormatPromptForSubcommand(string subcommand, string prompt)
    {
        return subcommand.ToLower() switch
        {
            "explain" => $"Please explain the following command or concept in simple terms for a developer: {prompt}",
            "suggest" => $"Suggest practical solutions or commands for this task: {prompt}",
            "debug" => $"Help debug this issue and provide troubleshooting steps: {prompt}",
            "code" => $"Generate clean, production-ready code for: {prompt}",
            "review" => $"Review this code and suggest improvements: {prompt}",
            "optimise" => $"Optimise this code or process: {prompt}",
            "test" => $"Provide testing strategies and examples for: {prompt}",
            _ => prompt
        };
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
            case "code":
                Console.WriteLine($"💻 Code generation for: {prompt}");
                Console.WriteLine("• Local fallback - basic code templates available");
                break;
            case "review":
                Console.WriteLine($"🔍 Code review for: {prompt}");
                Console.WriteLine("• Local fallback - basic syntax checking");
                break;
            case "optimise":
                Console.WriteLine($"⚡ Optimisation suggestions for: {prompt}");
                Console.WriteLine("• Local fallback - general performance tips");
                break;
            case "test":
                Console.WriteLine($"🧪 Testing guidance for: {prompt}");
                Console.WriteLine("• Local fallback - basic testing strategies");
                break;
        }
    }

    public async Task<bool> CheckFreelanceAIHealthAsync()
    {
        try
        {
            using var client = new HttpClient();
            client.Timeout = TimeSpan.FromSeconds(5);

            var response = await client.GetAsync("http://localhost:5000/health");
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public async Task ShowFreelanceAIStatusAsync()
    {
        try
        {
            using var client = new HttpClient();
            client.Timeout = TimeSpan.FromSeconds(10);

            // Check basic health
            var healthResponse = await client.GetAsync("http://localhost:5000/health");
            if (!healthResponse.IsSuccessStatusCode)
            {
                Console.WriteLine("❌ FreelanceAI is not available");
                return;
            }

            Console.WriteLine("✅ FreelanceAI is running");

            // Get provider status
            var statusResponse = await client.GetAsync("http://localhost:5000/api/ai/status");
            if (statusResponse.IsSuccessStatusCode)
            {
                var statusText = await statusResponse.Content.ReadAsStringAsync();
                var statusJson = System.Text.Json.JsonDocument.Parse(statusText);

                Console.WriteLine("📊 Provider Status:");
                foreach (var provider in statusJson.RootElement.EnumerateArray())
                {
                    var name = provider.GetProperty("name").GetString();
                    var isHealthy = provider.GetProperty("isHealthy").GetBoolean();
                    var requests = provider.GetProperty("requestsToday").GetInt32();
                    var cost = provider.GetProperty("costToday").GetDecimal();

                    var healthIcon = isHealthy ? "✅" : "❌";
                    Console.WriteLine($"  {healthIcon} {name}: {requests} requests, ${cost:F4} spent today");
                }
            }

            // Get today's spend
            var spendResponse = await client.GetAsync("http://localhost:5000/api/ai/spend");
            if (spendResponse.IsSuccessStatusCode)
            {
                var spendText = await spendResponse.Content.ReadAsStringAsync();
                if (decimal.TryParse(spendText, out var totalSpend))
                {
                    Console.WriteLine($"💰 Total spend today: ${totalSpend:F4}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"🚨 Error checking FreelanceAI status: {ex.Message}");
        }
    }
}
AI_EOF

    debug_print "Created $filename successfully"
}

# Create Core/ThemeManager.cs file
create_theme_manager_cs() {
    local filename="Core/ThemeManager.cs"

    print_status "computer" "Creating $filename..."

    # Ensure Core directory exists
    safe_mkdir "Core"

    cat > "$filename" << 'THEME_EOF'
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
THEME_EOF

    debug_print "Created $filename successfully"
}

# ========================================
# CONFIGURATION FILES
# ========================================

# Create wurp-config.json
create_wurp_config() {
    local filename=$(get_config '.project_structure.files.config')
    filename="${filename:-wurp-config.json}"

    print_status "gear" "Creating $filename..."

    # Extract project config from bootstrap config and write using tee
    echo "$CONFIG" | jq '.project_config' | tee "$filename" > /dev/null

    debug_print "Created $filename successfully"
}

# Create README.md
create_readme() {
    local filename=$(get_config '.project_structure.files.readme')
    filename="${filename:-README.md}"

    print_status "book" "Creating $filename..."

    local project_name=$(get_config '.project_config.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"

    cat > "$filename" << 'README_EOF'
# 🚀 Wurp (Warp Terminal Clone)

A feature-rich terminal emulator built with .NET 8, featuring AI integration, command history, auto-completion, and themes.

## Quick Start

```bash
# Check dependencies
./scripts/wurp-terminal check

# Install everything
./scripts/wurp-terminal install

# Run the terminal
wurp-terminal
```

## Features

- 🤖 **Enhanced AI Integration** - Full FreelanceAI API integration with smart routing and real-time cost tracking
- 📊 **Real-time Metrics** - Provider selection and performance monitoring
- 📜 **Command History** - Persistent history with search capability
- 🎨 **Multiple Themes** - Customisable themes with default, dark, and wurp options
- 🐚 **Cross-Shell Support** - Compatible with bash and zsh
- ⚙️ **JSON Configuration** - Centralised config management for easy setup
- 🔧 **Modular Architecture** - Clean separation of concerns with extendable modules

## AI Commands

The terminal includes comprehensive AI integration with FreelanceAI's smart routing system:

### Basic AI Commands
```bash
# Explain commands and concepts
ai explain "docker ps"        # Get detailed explanations
ai suggest "deploy app"       # Get practical suggestions
ai debug "permission denied"  # Troubleshooting help
```

### Advanced AI Commands
```bash
# Code generation with smart provider routing
ai code "REST API controller in C#"
ai code "React component for login form"

# Code review and optimisation
ai review "my-function.cs"           # Get code review feedback
ai optimise "slow database query"    # Performance optimisation tips

# Testing guidance
ai test "async methods in C#"        # Testing strategies and examples
```

### Real-time Monitoring
Each AI request shows:
- 📊 **Provider Used**: Which AI service handled the request (Groq, Ollama)
- 💰 **Cost Tracking**: Real-time cost per request
- ⚡ **Performance**: Response time and success metrics

## Built-in Commands

```bash
# Theme management
theme                    # Show current theme and options
theme wurp              # Switch to wurp theme (cyan prompt)
theme dark              # Switch to dark theme
theme default           # Switch to default theme

# Terminal operations
clear                   # Clear screen
history                 # Show command history
help                    # Show comprehensive help
exit / quit             # Exit gracefully

# System commands work normally
ls -la                  # File operations
git status              # Version control
npm install             # Package management
docker ps               # Container management
```

## FreelanceAI Integration

This terminal is designed to work seamlessly with FreelanceAI's intelligent routing system:

### Requirements
- **FreelanceAI API** running on `http://localhost:5000`
- Optional: **Ollama** for local AI fallback

### Smart Features
- **Automatic Provider Selection** - Routes to best available AI provider (Groq → Ollama)
- **Cost Optimisation** - Real-time budget tracking and cost monitoring
- **Health Monitoring** - Automatic failover when providers are unavailable
- **Rate Limiting** - Respects provider limits and quotas
- **Response History** - Tracks all AI interactions for analytics

### Setup FreelanceAI
```bash
# Clone and start FreelanceAI
git clone <freelance-ai-repo>
cd FreelanceAI
dotnet run --project src/FreelanceAI.WebApi

# Verify it's running
curl http://localhost:5000/health
```

## Installation & Management

### Build Commands
```bash
./scripts/wurp-terminal check      # Verify dependencies
./scripts/wurp-terminal build      # Build application
./scripts/wurp-terminal publish    # Create optimised binary
./scripts/wurp-terminal install    # Full installation
./scripts/wurp-terminal status     # Show installation status
```

### Advanced Usage
```bash
# Run directly without installation
./scripts/wurp-terminal run

# Check AI service status
./scripts/wurp-terminal ai-status

# Development workflow
dotnet run                          # Direct .NET execution
dotnet build --watch               # Hot reload during development
```

## Project Structure

```
wurp-terminal/
├── Program.cs                          # Application entry point
├── Core/                               # Modular architecture
│   ├── WurpTerminalService.cs          # Main terminal service
│   ├── AIIntegration.cs               # FreelanceAI integration
│   └── ThemeManager.cs                # Theme management
├── wurp-config.json                   # Centralised configuration
├── scripts/
│   ├── wurp-terminal                   # Main launcher script
│   └── lib/
│       └── wurp-terminal-functions.sh # Function library
├── WurpTerminal.csproj                # .NET project file
└── README.md                          # This file
```

## Configuration

The `wurp-config.json` file contains all settings:

```json
{
  "services": {
    "freelance_ai": {
      "base_url": "http://localhost:5000",
      "features": [
        "Smart provider routing (Groq, Ollama)",
        "Cost optimisation and tracking",
        "Response history analytics",
        "Health monitoring",
        "Automatic failover"
      ]
    }
  }
}
```

## Troubleshooting

### Common Issues
1. **AI commands not working**: Ensure FreelanceAI is running on port 5000
2. **Theme not changing**: Try using the full command: `theme <name>`
3. **Build fails**: Check that .NET 8 SDK is properly installed

### Debug Commands
```bash
# Check FreelanceAI connectivity
curl http://localhost:5000/health

# Check dependencies
./scripts/wurp-terminal check

# View detailed status
./scripts/wurp-terminal status
```

---

**Built with ❤️ using .NET 8 and FreelanceAI**

*Experience the future of terminal interaction with AI-powered assistance and intelligent routing.*
README_EOF

    debug_print "Created $filename successfully"
}

# ========================================
# SCRIPT GENERATION FUNCTIONS
# ========================================

# Create wurp-functions script
create_wurp_functions() {
    local filename=$(get_config '.project_structure.files.functions')
    filename="${filename:-scripts/lib/wurp-terminal-functions.sh}"

    print_status "wrench" "Creating $filename..."

    # Ensure the directory exists
    local dir_path=$(dirname "$filename")
    if [ ! -d "$dir_path" ]; then
        safe_mkdir "$dir_path"
        print_status "info" "Created directory: $dir_path"
    fi

    cat > "$filename" << 'FUNCTIONS_EOF'
#!/bin/bash
# lib/wurp-terminal-functions.sh
# Modular function library for Wurp (Warp Terminal Clone)

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

    print_status "success" "Modular system loaded successfully"
    return 0
}

# ========================================
# LEGACY COMPATIBILITY FUNCTIONS
# ========================================
# These provide basic functionality when modules aren't available

# Basic config functions
get_config() {
    local path=$1
    echo "$CONFIG" | jq -r "$path // empty" 2>/dev/null
}

get_config_array() {
    local path=$1
    echo "$CONFIG" | jq -r "$path[]? // empty" 2>/dev/null
}

expand_path() {
    local path=$1
    echo "${path/\$HOME/$HOME}"
}

# Basic output functions
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
        "folder") print_color "blue" "📁 $message" ;;
        "file") print_color "green" "📝 $message" ;;
        "computer") print_color "cyan" "💻 $message" ;;
        "gear") print_color "yellow" "⚙️ $message" ;;
        "wrench") print_color "yellow" "🔧 $message" ;;
        "book") print_color "blue" "📖 $message" ;;
        "rocket") print_color "cyan" "🚀 $message" ;;
        "party") print_color "green" "🎉 $message" ;;
        "target") print_color "cyan" "🎯 $message" ;;
        *) echo "$message" ;;
    esac
}

# Basic dependency check
check_dependencies() {
    print_status "working" "Checking dependencies..."
    local missing_deps=()
    local has_errors=false

    while IFS= read -r dep_json; do
        [ -z "$dep_json" ] && continue

        local name=$(echo "$dep_json" | jq -r '.name')
        local command=$(echo "$dep_json" | jq -r '.command')
        local install_hint=$(echo "$dep_json" | jq -r '.install_hint')

        if ! command -v "$command" &> /dev/null; then
            missing_deps+=("$name: $install_hint")
            has_errors=true
        fi
    done < <(echo "$CONFIG" | jq -c '.dependencies.required[]? // empty')

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

    local build_args=$(get_config '.build.dotnet_args.build')
    build_args="${build_args:--c Release}"

    if dotnet build $build_args; then
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

    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"

    local publish_args="-c Release --self-contained false"

    if dotnet publish $publish_args; then
        print_status "success" "Publish successful"

        local user_bin_path=$(get_config '.paths.user_bin')
        local user_bin=$(expand_path "${user_bin_path:-$HOME/.local/bin}")

        # Find the actual binary location
        local actual_binary=""
        local search_paths=(
            "bin/Release/net8.0/linux-x64/publish/$binary_name"
            "bin/Release/net8.0/publish/$binary_name"
            "bin/Release/net8.0/linux-x64/$binary_name"
            "bin/Release/net8.0/linux-x64/publish/$binary_name.dll"
            "bin/Release/net8.0/publish/$binary_name.dll"
        )

        for path in "${search_paths[@]}"; do
            if [ -f "$PROJECT_ROOT/$path" ]; then
                actual_binary="$PROJECT_ROOT/$path"
                print_status "info" "Found binary at: $path"
                break
            fi
        done

        if [ -z "$actual_binary" ]; then
            print_status "error" "Published binary not found"
            return 1
        fi

        chmod +x "$actual_binary"

        mkdir -p "$user_bin"
        [ -L "$user_bin/$binary_name" ] && rm -f "$user_bin/$binary_name"
        [ -f "$user_bin/$binary_name" ] && rm -f "$user_bin/$binary_name"

        # Create a wrapper script if it's a .dll
        if [[ "$actual_binary" == *.dll ]]; then
            cat > "$user_bin/$binary_name" << WRAPPER_EOF
#!/bin/bash
exec dotnet "$actual_binary" "\$@"
WRAPPER_EOF
            chmod +x "$user_bin/$binary_name"
            print_color "cyan" "🔗 Wrapper script created: $user_bin/$binary_name"
        else
            ln -s "$actual_binary" "$user_bin/$binary_name"
            print_color "cyan" "🔗 Symlink created: $user_bin/$binary_name"
        fi

        if [[ ":$PATH:" != *":$user_bin:"* ]]; then
            print_status "warning" "Add $user_bin to your PATH:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo "  source ~/.bashrc"
        fi
        return 0
    else
        print_status "error" "Publish failed"
        return 1
    fi
}

# Basic run function
run_app() {
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"

    # Try to find the published binary
    local actual_binary=""
    local search_paths=(
        "bin/Release/net8.0/linux-x64/publish/$binary_name"
        "bin/Release/net8.0/publish/$binary_name"
        "bin/Release/net8.0/linux-x64/$binary_name"
        "bin/Release/net8.0/linux-x64/publish/$binary_name.dll"
        "bin/Release/net8.0/publish/$binary_name.dll"
    )

    for path in "${search_paths[@]}"; do
        if [ -f "$PROJECT_ROOT/$path" ]; then
            actual_binary="$PROJECT_ROOT/$path"
            break
        fi
    done

    if [ -n "$actual_binary" ]; then
        if [[ "$actual_binary" == *.dll ]]; then
            exec dotnet "$actual_binary" "$@"
        else
            exec "$actual_binary" "$@"
        fi
    else
        print_status "error" "Application not found. Please build first."
        return 1
    fi
}

# Basic status function
show_status() {
    local project_name=$(get_config '.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"

    print_color "cyan" "🚀 $project_name Status"
    echo ""

    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"

    # Check if application is built
    local actual_binary=""
    local search_paths=(
        "bin/Release/net8.0/linux-x64/publish/$binary_name"
        "bin/Release/net8.0/publish/$binary_name"
        "bin/Release/net8.0/linux-x64/$binary_name"
        "bin/Release/net8.0/linux-x64/publish/$binary_name.dll"
        "bin/Release/net8.0/publish/$binary_name.dll"
    )

    for path in "${search_paths[@]}"; do
        if [ -f "$PROJECT_ROOT/$path" ]; then
            actual_binary="$PROJECT_ROOT/$path"
            break
        fi
    done

    if [ -n "$actual_binary" ]; then
        print_status "success" "Application built and published"
        echo -e "   Location: $actual_binary"
    else
        print_status "error" "Application not built"
    fi

    local user_bin_path=$(get_config '.paths.user_bin')
    local user_bin=$(expand_path "${user_bin_path:-$HOME/.local/bin}")

    # Check symlink
    [ -L "$user_bin/$binary_name" ] && print_status "success" "Symlink installed" || print_status "warning" "Symlink not installed"

    # Check PATH
    [[ ":$PATH:" == *":$user_bin:"* ]] && print_status "success" "PATH configured correctly" || print_status "warning" "~/.local/bin not in PATH"

    echo ""
}

# Basic help function
show_help() {
    local project_name=$(get_config '.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"

    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"

    print_color "cyan" "$project_name - Build & Installation Script"
    echo ""
    print_color "yellow" "Usage:"
    echo "  ./scripts/$binary_name [command] [options]"
    echo ""
    print_color "yellow" "Commands:"
    echo "  build         - Build the application"
    echo "  publish       - Build and publish as single file"
    echo "  install       - Full installation (build, publish, integrate)"
    echo "  run           - Run the application"
    echo "  status        - Show installation status"
    echo "  check         - Check dependencies"
    echo "  help          - Show this help"
}

# Stub functions for missing functionality (will be implemented in future modules)
install_shell_integration() {
    print_status "info" "Shell integration not yet implemented in modular system"
}

create_desktop_entry() {
    print_status "info" "Desktop integration not yet implemented in modular system"
}

check_freelance_ai() {
    print_status "info" "Service checks not yet implemented in modular system"
}

check_ollama() {
    print_status "info" "Service checks not yet implemented in modular system"
}

uninstall() {
    print_status "info" "Uninstall not yet implemented in modular system"
}

# ========================================
# BOOTSTRAP ORCHESTRATION
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
            print_status "success" "Modular system loaded successfully"
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
        print_status "warning" "Using legacy file creation mode"
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
    echo "   ├── scripts/lib/wurp-terminal-functions.sh (Modular library)"
    echo "   └── README.md"
    echo ""
    print_status "target" "The project is ready for testing!"
    echo ""
    print_status "info" "💡 To enable full modular functionality:"
    echo "   1. Create scripts/lib/modules/ directory in generated project"
    echo "   2. Add the modular function files (00-core.sh, 10-project.sh, 20-files.sh)"
    echo "   3. Restart to use enhanced modular features"

    return 0
}

# Keep the old function for backward compatibility
execute_bootstrap() {
    local base_dir=$(get_config '.bootstrap.base_dir')
    local project_subdir=$(get_config '.bootstrap.project_subdir')

    if [ -z "$base_dir" ]; then
        base_dir="$HOME/Development"
    fi

    if [ -z "$project_subdir" ]; then
        project_subdir="wurp-terminal"
    fi

    base_dir=$(expand_path "$base_dir")

    execute_bootstrap_with_args "$base_dir" "$project_subdir"
}

# ========================================
# MODULE SYSTEM INITIALIZATION
# ========================================

# Initialise the module system when this file is sourced
if init_module_system; then
    load_modules
fi

# Export key functions for external use
export -f execute_bootstrap execute_bootstrap_with_args
export -f print_status print_color get_config expand_path debug_print
FUNCTIONS_EOF

    chmod +x "$filename"
    debug_print "Created $filename successfully"
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

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load configuration from JSON
CONFIG_FILE="$PROJECT_ROOT/wurp-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Read configuration into variable
CONFIG=$(cat "$CONFIG_FILE")

# Source the function library
FUNCTIONS_FILE="$SCRIPT_DIR/lib/wurp-terminal-functions.sh"
if [ -f "$FUNCTIONS_FILE" ]; then
    # Set global variables for functions
    export SCRIPT_DIR PROJECT_ROOT CONFIG
    source "$FUNCTIONS_FILE"
else
    echo "❌ Function library not found: $FUNCTIONS_FILE"
    exit 1
fi

# Main command processing
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
            check_dependencies && \
            build_app && \
            publish_app && \
            install_shell_integration && \
            create_desktop_entry && \
            print_status "success" "🎉 Installation complete!" && \
            show_status
            ;;

        "run")
            check_dependencies && run_app "$@"
            ;;

        "status")
            show_status
            ;;

        "shell")
            install_shell_integration
            ;;

        "desktop")
            create_desktop_entry
            ;;

        "check")
            check_dependencies && check_freelance_ai && check_ollama
            ;;

        "ai-status")
            cd "$PROJECT_ROOT" && dotnet run ai status 2>/dev/null || echo "⚠️  Run 'build' first"
            ;;

        "uninstall")
            uninstall
            ;;

        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
LAUNCHER_EOF

    chmod +x "$filename"
    debug_print "Created $filename successfully"
}

# ========================================
# ORCHESTRATION FUNCTIONS
# ========================================

# Create all Core class files
create_core_files() {
    print_status "working" "Creating Core class files..."

    create_wurp_terminal_service_cs || { print_status "error" "Failed to create WurpTerminalService.cs"; return 1; }
    create_ai_integration_cs || { print_status "error" "Failed to create AIIntegration.cs"; return 1; }
    create_theme_manager_cs || { print_status "error" "Failed to create ThemeManager.cs"; return 1; }

    print_status "success" "Core class files created"
}

# Create all project files
create_all_project_files() {
    print_status "working" "Creating all project files..."

    create_csproj_file || { print_status "error" "Failed to create .csproj file"; return 1; }
    create_program_cs || { print_status "error" "Failed to create Program.cs"; return 1; }
    create_core_files || { print_status "error" "Failed to create Core files"; return 1; }
    create_wurp_config || { print_status "error" "Failed to create wurp-config.json"; return 1; }
    create_readme || { print_status "error" "Failed to create README.md"; return 1; }

    print_status "success" "All project files created"
}

# Export functions for use by other modules
export -f create_csproj_file create_program_cs
export -f create_wurp_terminal_service_cs create_ai_integration_cs create_theme_manager_cs
export -f create_wurp_config create_readme
export -f create_wurp_functions create_main_launcher
export -f create_core_files create_all_project_files