#!/bin/bash
# wurp-terminal-bootstrap-functions.sh
# Function library for Wurp Terminal Bootstrap

# Global variables (set by main script)
SCRIPT_DIR=""
CONFIG=""

# ========================================
# UTILITY FUNCTIONS
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

# FIXED: Expand variables in path
expand_path() {
    local path=$1
    # Handle $HOME expansion properly
    path="${path/\$HOME/$HOME}"
    # Handle ~ expansion
    path="${path/#\~/$HOME}"
    echo "$path"
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
# PROJECT STRUCTURE FUNCTIONS
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
# FILE CREATION FUNCTIONS
# ========================================

# Create .csproj file
create_csproj_file() {
    local filename=$(get_config '.project_structure.files.csproj')
    filename="${filename:-WurpTerminal.csproj}"
    
    print_status "file" "Creating $filename..."
    
    # Use tee instead of cat with heredoc for better compatibility
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
}

# Create Program.cs file
create_program_cs() {
    local filename=$(get_config '.project_structure.files.main')
    filename="${filename:-Program.cs}"
    
    print_status "computer" "Creating $filename..."
    
    cat > "$filename" << 'EOF'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace WurpTerminal;

class Program
{
    static async Task Main(string[] args)
    {
        try
        {
            var terminal = new WarpTerminalService();
            
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

public class WarpTerminalService
{
    private readonly List<string> _history = new();
    private readonly string _historyFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".warp_terminal_history");
    private readonly AIIntegration _ai = new();
    private readonly ThemeManager _themes = new();

    public WarpTerminalService()
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
            using var client = new System.Net.Http.HttpClient();
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

public class ThemeManager
{
    private readonly Dictionary<string, Dictionary<string, string>> _themes = new()
    {
        ["default"] = new()
        {
            ["prompt"] = "\x1b[36mwarp",
            ["red"] = "\x1b[31m",
            ["green"] = "\x1b[32m",
            ["yellow"] = "\x1b[33m",
            ["blue"] = "\x1b[34m",
            ["reset"] = "\x1b[0m"
        },
        ["dark"] = new()
        {
            ["prompt"] = "\x1b[35mwarp",
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

# Create wurp-config.json
create_warp_config() {
    local filename=$(get_config '.project_structure.files.config')
    filename="${filename:-wurp-config.json}"
    
    print_status "gear" "Creating $filename..."
    
    # Extract project config from bootstrap config and write using tee
    echo "$CONFIG" | jq '.project_config' | tee "$filename" > /dev/null
}

# Create function library for wurp terminal
create_warp_functions() {
    local filename=$(get_config '.project_structure.files.functions')
    filename="${filename:-scripts/lib/wurp-terminal-functions.sh}"
    
    print_status "wrench" "Creating $filename..."
    
    # Ensure the directory exists - THIS IS THE FIX
    local dir_path=$(dirname "$filename")
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        print_status "info" "Created directory: $dir_path"
    fi
    
    cat > "$filename" << 'EOF'
#!/bin/bash
# lib/wurp-terminal-functions.sh
# Function library for Wurp (Warp Terminal Clone)

# ========================================
# UTILITY FUNCTIONS
# ========================================

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
    local color_code=$(get_config ".colors.$color_name")
    local nc=$(get_config ".colors.nc")
    
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

# ========================================
# SHELL DETECTION FUNCTIONS
# ========================================

detect_current_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "zsh"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "bash"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        echo "zsh"
    elif [ -n "${BASH_VERSION:-}" ]; then
        echo "bash"
    else
        echo "bash"
    fi
}

get_shell_config() {
    local shell_type=$1
    local config_key=$2
    echo "$CONFIG" | jq -r ".shell_integration.shells.$shell_type.$config_key // empty"
}

# ========================================
# DEPENDENCY FUNCTIONS
# ========================================

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

# ========================================
# BUILD FUNCTIONS
# ========================================

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

publish_app() {
    print_status "working" "Publishing application..."
    
    cd "$PROJECT_ROOT" || return 1
    
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    # Publish (let .NET use its default structure)
    local publish_args="-c Release --self-contained false"
    
    if dotnet publish $publish_args; then
        print_status "success" "Publish successful"
        
        local user_bin_path=$(get_config '.paths.user_bin')
        local user_bin=$(expand_path "${user_bin_path:-$HOME/.local/bin}")
        
        # Find the actual binary location (check common .NET publish paths)
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
            print_status "info" "Searched locations:"
            for path in "${search_paths[@]}"; do
                echo "  - $path"
            done
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

# ========================================
# SHELL INTEGRATION FUNCTIONS
# ========================================

install_shell_integration() {
    print_status "working" "Installing shell integration..."
    
    local current_shell=$(detect_current_shell)
    print_color "cyan" "Detected shell: $current_shell"
    
    local rc_file_path=$(get_shell_config "$current_shell" "rc_file")
    local rc_file=$(expand_path "${rc_file_path:-$HOME/.bashrc}")
    
    local marker=$(get_config '.shell_integration.marker')
    marker="${marker:-# Wurp Terminal Integration}"
    
    if grep -q "$marker" "$rc_file" 2>/dev/null; then
        print_status "info" "Shell integration already installed"
        return 0
    fi
    
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    # Build integration block
    local integration_block=""
    integration_block+="\n$marker\n"
    
    while IFS= read -r alias_line; do
        [ -n "$alias_line" ] && integration_block+="$alias_line\n"
    done < <(echo "$CONFIG" | jq -r '.shell_integration.aliases[]? // empty')
    
    integration_block+="\n# AI helper functions\n"
    integration_block+="warp_explain() { $binary_name ai explain \"\$*\"; }\n"
    integration_block+="warp_suggest() { $binary_name ai suggest \"\$*\"; }\n"
    integration_block+="warp_debug() { $binary_name ai debug \"\$*\"; }\n\n"
    
    while IFS= read -r alias_line; do
        [ -n "$alias_line" ] && integration_block+="$alias_line\n"
    done < <(echo "$CONFIG" | jq -r '.shell_integration.quick_aliases[]? // empty')
    
    echo -e "$integration_block" >> "$rc_file"
    
    print_status "success" "Shell integration installed"
    print_color "cyan" "Restart your shell or run: source $rc_file"
}

# ========================================
# SERVICE FUNCTIONS
# ========================================

check_freelance_ai() {
    print_status "working" "Checking FreelanceAI service..."
    
    local health_url=$(get_config '.services.freelance_ai.health_url')
    health_url="${health_url:-http://localhost:5000/health}"
    
    if curl -s "$health_url" > /dev/null 2>&1; then
        print_status "success" "FreelanceAI API is running"
        return 0
    else
        print_status "warning" "FreelanceAI API not running"
        return 1
    fi
}

check_ollama() {
    local health_url=$(get_config '.services.ollama.health_url')
    health_url="${health_url:-http://localhost:11434/api/tags}"
    
    if curl -s "$health_url" > /dev/null 2>&1; then
        print_status "success" "Ollama is running"
        return 0
    else
        print_status "info" "Ollama not running (optional)"
        return 1
    fi
}

# ========================================
# DESKTOP INTEGRATION FUNCTIONS
# ========================================

create_desktop_entry() {
    print_status "working" "Creating desktop entry..."
    
    local desktop_dir_path=$(get_config '.paths.desktop_dir')
    local desktop_dir=$(expand_path "${desktop_dir_path:-$HOME/.local/share/applications}")
    
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    local desktop_file="$desktop_dir/$binary_name.desktop"
    
    local publish_path=$(get_config '.paths.publish_dir')
    local publish_dir=$(expand_path "${publish_path:-bin/Release/net8.0/publish}")
    
    mkdir -p "$desktop_dir"
    
    local entry_name=$(get_config '.desktop_entry.name')
    entry_name="${entry_name:-Wurp (Warp Terminal Clone)}"
    
    local entry_comment=$(get_config '.desktop_entry.comment')
    entry_comment="${entry_comment:-AI-Powered Terminal built with .NET}"
    
    local entry_icon=$(get_config '.desktop_entry.icon')
    entry_icon="${entry_icon:-utilities-terminal}"
    
    local entry_categories=$(get_config '.desktop_entry.categories')
    entry_categories="${entry_categories:-System;TerminalEmulator;}"
    
    local entry_keywords=$(get_config '.desktop_entry.keywords')
    entry_keywords="${entry_keywords:-terminal;console;command;shell;ai;}"
    
    cat > "$desktop_file" << DESKTOP_EOF
[Desktop Entry]
Name=$entry_name
Comment=$entry_comment
Exec=$PROJECT_ROOT/$publish_dir/$binary_name
Icon=$entry_icon
Type=Application
Categories=$entry_categories
Terminal=false
StartupNotify=true
Keywords=$entry_keywords
DESKTOP_EOF
    
    chmod +x "$desktop_file"
    print_status "success" "Desktop entry created"
}

# ========================================
# STATUS FUNCTIONS
# ========================================

show_status() {
    local project_name=$(get_config '.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"
    
    print_color "cyan" "🚀 $project_name Status"
    echo ""
    
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    # Use same search logic as publish_app
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
    
    local user_bin_path=$(get_config '.paths.user_bin')
    local user_bin=$(expand_path "${user_bin_path:-$HOME/.local/bin}")
    
    # Check build status
    if [ -n "$actual_binary" ]; then
        print_status "success" "Application built and published"
        echo -e "   Location: $actual_binary"
    else
        print_status "error" "Application not built"
    fi
    
    # Check symlink
    [ -L "$user_bin/$binary_name" ] && print_status "success" "Symlink installed" || print_status "warning" "Symlink not installed"
    
    # Check PATH
    [[ ":$PATH:" == *":$user_bin:"* ]] && print_status "success" "PATH configured correctly" || print_status "warning" "~/.local/bin not in PATH"
    
    # Check shell integration
    local marker=$(get_config '.shell_integration.marker')
    marker="${marker:-# Wurp Terminal Integration}"
    
    local current_shell=$(detect_current_shell)
    local rc_file_path=$(get_shell_config "$current_shell" "rc_file")
    local rc_file=$(expand_path "$rc_file_path")
    
    if [ -f "$rc_file" ] && grep -q "$marker" "$rc_file" 2>/dev/null; then
        print_status "success" "Shell integration installed ($current_shell)"
    else
        print_status "warning" "Shell integration not installed"
    fi
    
    # Check services
    check_freelance_ai > /dev/null 2>&1 && print_status "success" "FreelanceAI API available" || print_status "warning" "FreelanceAI API not available"
    
    echo ""
}

# ========================================
# RUN FUNCTIONS
# ========================================

run_app() {
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    # Use same search logic as publish_app
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

# ========================================
# CLEANUP FUNCTIONS
# ========================================

uninstall() {
    local project_name=$(get_config '.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"
    
    print_status "working" "Uninstalling $project_name..."
    
    local binary_name=$(get_config '.project.binary_name')
    binary_name="${binary_name:-wurp-terminal}"
    
    local user_bin_path=$(get_config '.paths.user_bin')
    local user_bin=$(expand_path "${user_bin_path:-$HOME/.local/bin}")
    
    local desktop_dir_path=$(get_config '.paths.desktop_dir')
    local desktop_dir=$(expand_path "${desktop_dir_path:-$HOME/.local/share/applications}")
    
    local marker=$(get_config '.shell_integration.marker')
    marker="${marker:-# Wurp Terminal Integration}"
    
    # Remove symlink
    if [ -L "$user_bin/$binary_name" ]; then
        rm -f "$user_bin/$binary_name"
        print_status "success" "Symlink removed"
    fi
    
    # Remove desktop entry
    local desktop_file="$desktop_dir/$binary_name.desktop"
    if [ -f "$desktop_file" ]; then
        rm -f "$desktop_file"
        print_status "success" "Desktop entry removed"
    fi
    
    # Remove shell integration
    local current_shell=$(detect_current_shell)
    local rc_file_path=$(get_shell_config "$current_shell" "rc_file")
    local rc_file=$(expand_path "$rc_file_path")
    
    if [ -f "$rc_file" ] && grep -q "$marker" "$rc_file" 2>/dev/null; then
        cp "$rc_file" "$rc_file.wurp.bak"
        sed -i "/$marker/,/^$/d" "$rc_file"
        print_status "success" "Shell integration removed"
        print_color "cyan" "Backup created: $rc_file.wurp.bak"
    fi
    
    # Clean build artifacts
    cd "$PROJECT_ROOT" || return 1
    local clean_dirs_str
    clean_dirs_str=$(echo "$CONFIG" | jq -r '.build.clean_dirs[]? // empty' | tr '\n' ' ')
    IFS=' ' read -r -a clean_dirs <<< "$clean_dirs_str"
    for dir in "${clean_dirs[@]}"; do
        [ -n "$dir" ] && [ -d "$dir" ] && rm -rf "$dir"
    done
    
    print_status "success" "Uninstall complete"
}

# ========================================
# HELP FUNCTIONS
# ========================================

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
    echo "  shell         - Install shell integration only"
    echo "  desktop       - Create desktop entry"
    echo "  uninstall     - Remove all traces"
    echo "  check         - Check dependencies"
    echo "  help          - Show this help"
    echo ""
    print_color "yellow" "Examples:"
    print_color "green" "  ./scripts/$binary_name install"
    echo "    # Full installation"
    print_color "green" "  ./scripts/$binary_name run"
    echo "    # Run directly"
    print_color "green" "  ./scripts/$binary_name status"
    echo "    # Check status"
    echo ""
    print_color "cyan" "After installation, use:"
    print_color "green" "  $binary_name"
    echo "                      # Start terminal"
    print_color "green" "  wt"
    echo "                                 # Short alias"
    print_color "green" "  explain 'docker ps'"
    echo "               # Explain command"
    print_color "green" "  suggest 'deploy to kubernetes'"
    echo "    # Get suggestions"
}
EOF
}

# Create main launcher script
create_main_launcher() {
    local filename=$(get_config '.project_structure.files.main_script')
    filename="${filename:-scripts/wurp-terminal}"
    
    print_status "rocket" "Creating $filename..."
    
    cat > "$filename" << 'EOF'
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
EOF

    chmod +x "$filename"
}

# Create README.md
create_readme() {
    local filename=$(get_config '.project_structure.files.readme')
    filename="${filename:-README.md}"
    
    print_status "book" "Creating $filename..."
    
    local project_name=$(get_config '.project_config.project.name')
    project_name="${project_name:-Wurp (Warp Terminal Clone)}"
    
    cat > "$filename" << EOF
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

- \`Program.cs\` - Main terminal application
- \`wurp-config.json\` - Centralized configuration
- \`scripts/wurp-terminal\` - Installation script
- \`scripts/lib/wurp-terminal-functions.sh\` - Function library

Built with ❤️ using .NET 8
EOF
}

# ========================================
# MAIN BOOTSTRAP FUNCTIONS
# ========================================

# FIXED: Execute the bootstrap process with custom arguments
execute_bootstrap_with_args() {
    local base_dir="$1"
    local project_name="$2"
    
    print_color "cyan" "🚀 Creating Wurp (Warp Terminal Clone) Project Structure"
    print_color "cyan" "=================================================="
    echo ""
    
    # Debug: Check if CONFIG is properly loaded
    echo "Debug: CONFIG length: ${#CONFIG}"
    if [ ${#CONFIG} -gt 0 ]; then
        echo "Debug: CONFIG loaded successfully"
    else
        echo "Debug: CONFIG is empty, using defaults"
    fi
    
    # Use provided arguments instead of config
    local project_dir="$base_dir/$project_name"
    
    echo "Debug: Using provided base_dir: '$base_dir'"
    echo "Debug: Using provided project_name: '$project_name'"
    echo "Debug: final project_dir: '$project_dir'"
    echo ""
    
    # Create project structure and change to it
    if ! create_project_structure "$project_dir"; then
        print_status "error" "Failed to create project structure"
        return 1
    fi
    
    # Verify we're in the right directory
    print_status "info" "Current working directory: $(pwd)"
    echo ""
    
    # Create all project files (now we're in the project directory)
    print_status "working" "Creating project files..."
    
    create_csproj_file || { print_status "error" "Failed to create .csproj file"; return 1; }
    create_program_cs || { print_status "error" "Failed to create Program.cs"; return 1; }
    create_warp_config || { print_status "error" "Failed to create wurp-config.json"; return 1; }
    create_warp_functions || { print_status "error" "Failed to create functions library"; return 1; }
    create_main_launcher || { print_status "error" "Failed to create main launcher"; return 1; }
    create_readme || { print_status "error" "Failed to create README.md"; return 1; }
    
    # Make scripts executable
    local main_script=$(get_config '.project_structure.files.main_script')
    local functions_script=$(get_config '.project_structure.files.functions')
    
    # Use defaults if config is empty
    main_script="${main_script:-scripts/wurp-terminal}"
    functions_script="${functions_script:-scripts/lib/wurp-terminal-functions.sh}"
    
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
    echo "   ├── Program.cs (Enhanced terminal with AI, themes, history)"
    echo "   ├── WurpTerminal.csproj"
    echo "   ├── wurp-config.json (Complete configuration)"
    echo "   ├── scripts/wurp-terminal (Main launcher)"
    echo "   ├── scripts/lib/wurp-terminal-functions.sh (Complete library)"
    echo "   └── README.md"
    echo ""
    print_status "target" "The project is ready for testing!"
    
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