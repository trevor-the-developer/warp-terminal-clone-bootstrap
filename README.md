# 🚀 Wurp Terminal Bootstrap

A comprehensive **modular bootstrap system** that generates complete AI-powered terminal applications built with .NET 9. Features a clean, maintainable architecture with numbered modules for easy development and extension.

**Latest Updates:**
- ✅ Updated to .NET 9 for compatibility with Freelance-AI project
- ✅ Fixed modular system warnings - no more "modules directory not found" messages
- ✅ Added comprehensive test suite with 17 automated tests
- ✅ Full integration testing for generated projects

## ⚡ Quick Start

```bash
# Create project in current directory
./wurp-terminal-bootstrap.sh

# Create project in specific location
./wurp-terminal-bootstrap.sh -p ~/workspace -n my-terminal

# Debug mode to see module loading
./wurp-terminal-bootstrap.sh --debug -p ~/test -n debug-project

# Show help
./wurp-terminal-bootstrap.sh -h
```

## 🎯 Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `-p, --path` | Base directory for project | `-p ~/Projects` |
| `-n, --name` | Project folder name | `-n my-terminal` |
| `-d, --debug` | Enable debug mode (shows module loading) | `--debug` |
| `-h, --help` | Show help message | `-h` |

## 🏗️ Modular Architecture

This bootstrap uses a **numbered module system** for clean, maintainable code:

```
lib/
├── wurp-terminal-bootstrap-functions.sh  # Smart coordinator with fallbacks
└── modules/
    ├── 00-core.sh                        # Core utilities (config, colors, validation)
    ├── 10-project.sh                     # Project structure creation
    └── 20-files.sh                       # File generation (C#, configs, docs)
```

### 🧩 Module Benefits
- **`00-core.sh`** (150 lines) - Pure utilities, no dependencies
- **`10-project.sh`** (100 lines) - Directory structure only
- **`20-files.sh`** (400 lines) - All C# and config file generation
- **Smart loading** - Modules load in order with graceful fallbacks
- **Debug mode** - See exactly what's loading with `--debug`

## 📁 What It Creates

The bootstrap script generates a complete project structure:

```
your-project/
├── Program.cs                          # Main terminal application entry point
├── WurpTerminal.csproj                 # .NET 9 project file
├── wurp-config.json                   # Centralised configuration
├── Core/                               # Modular C# architecture
│   ├── WurpTerminalService.cs          # Main terminal service
│   ├── AIIntegration.cs                # AI command handling
│   └── ThemeManager.cs                 # Theme management
├── scripts/
│   ├── wurp-terminal                   # Main launcher script
│   └── lib/
│       └── wurp-terminal-functions.sh # Generated function library
├── .gitignore                          # Git ignore file
├── .editorconfig                       # Editor configuration
└── README.md                          # Project documentation
```

## 🚀 Generated Terminal Features

The created terminal includes:

- 🤖 **Enhanced AI Integration** - Full FreelanceAI API integration with smart routing
- 📊 **Real-time Metrics** - Provider selection, cost tracking, and performance monitoring
- 📜 **Command History** - Persistent command history with search
- 🎨 **Multiple Themes** - Default, dark, and wurp themes with colors
- 🐚 **Shell Integration** - Works seamlessly with bash/zsh
- ⚡ **System Commands** - Execute any system command with output
- 🔧 **Built-in Commands** - help, clear, history, themes, AI commands
- 💻 **Cross-platform** - Runs on Linux, macOS, Windows with .NET 8
- 🔄 **Automatic Failover** - Seamless switching between AI providers
- 💰 **Cost Optimisation** - Budget tracking and intelligent provider selection

## 🛠️ After Bootstrap

Navigate to your project and use the generated build system:

```bash
cd your-project

# Check dependencies (dotnet, jq, curl)
./scripts/wurp-terminal check

# Build the application
./scripts/wurp-terminal build

# Build and publish optimised binary
./scripts/wurp-terminal publish

# Full installation (build, publish, create symlinks)
./scripts/wurp-terminal install

# Show installation status
./scripts/wurp-terminal status

# Run the terminal directly
./scripts/wurp-terminal run

# Or use the installed binary
wurp-terminal
```

## 🤖 Generated Terminal Commands

Once installed, use these commands in your AI-powered terminal:

### AI Commands
```bash
ai explain "docker ps"        # Explain what a command does
ai suggest "deploy app"       # Get command suggestions for tasks
ai debug "permission denied"  # Get debugging help for errors
ai code "REST API controller" # Generate code with smart routing
ai review "my-code.cs"        # Code review with AI assistance
ai optimise "slow query"      # Performance optimisation suggestions
ai test "async methods"       # Testing strategies and examples
```

### FreelanceAI Integration
```bash
./scripts/wurp-terminal ai-status  # Check FreelanceAI provider status and costs
./scripts/wurp-terminal check       # Verify dependencies and AI services
```

### Theme Commands
```bash
theme                         # Show current theme and available options
theme dark                    # Switch to dark theme
theme wurp                    # Switch to wurp theme (cyan prompt)
theme default                 # Switch to default theme
```

### Built-in Commands
```bash
help                          # Show comprehensive help
history                       # Show recent command history
clear                         # Clear screen
exit / quit                   # Exit terminal gracefully
```

### System Integration
```bash
# All system commands work normally
ls -la                        # File listing
git status                    # Git commands
npm install                   # Package managers
docker ps                     # Container management
```

## 📋 Requirements

| Requirement | Purpose | Installation |
|-------------|---------|--------------|
|| **.NET 9 SDK** | Build and run C# application | [Download from Microsoft](https://dotnet.microsoft.com/download) |
| **jq** | JSON configuration processing | `sudo apt install jq` or `brew install jq` |
| **curl** | AI service health checks | `sudo apt install curl` or `brew install curl` |
| **bash/zsh** | Shell compatibility | Usually pre-installed |

## 🔧 Development Workflow

### Adding New Features
```bash
# Modify C# file generation
nano lib/modules/20-files.sh

# Change project structure
nano lib/modules/10-project.sh

# Update core utilities
nano lib/modules/00-core.sh

# Test changes with debug mode
DEBUG=true ./wurp-terminal-bootstrap.sh -p ~/test -n dev-test
```

### Future Module Extensions
```bash
# Ready for additional modules:
lib/modules/30-build.sh        # Enhanced build operations
lib/modules/40-integration.sh  # Shell and desktop integration
lib/modules/50-services.sh     # AI service management
lib/modules/60-management.sh   # Advanced project management
```

## 🧪 Testing & Debugging

### Comprehensive Test Suite

We provide a complete test script that validates all aspects of generated projects:

```bash
# Test the current project
./test-wurp-terminal.sh

# Test a specific project
./test-wurp-terminal.sh /path/to/your-project

# Test the example project we just created
./test-wurp-terminal.sh ~/workspace/my-terminal
```

### Test Coverage (17 Automated Tests)

The test script performs comprehensive validation:

#### 🔧 **Build & Functionality Tests**
1. **Help Command** - Validates script help system
2. **Dependency Check** - Ensures all required tools are available
3. **Build Application** - Tests .NET 9 compilation
4. **Publish Application** - Validates optimized binary creation
5. **Status Check** - Verifies installation status reporting

#### 🚀 **Terminal Functionality Tests**
6. **Version Command** - Tests terminal version display
7. **Terminal Help** - Validates built-in help system
8. **AI Explain Command** - Tests AI command explanation feature
9. **AI Suggest Command** - Tests AI task suggestion feature
10. **AI Debug Command** - Tests AI debugging assistance
11. **Theme List Command** - Tests theme management listing
12. **Theme Change Command** - Tests theme switching functionality

#### 📁 **Structure & Configuration Tests**
13. **Project Structure Validation** - Ensures all required files and directories exist
14. **Configuration File Validation** - Validates JSON configuration syntax
15. **Executable Permissions** - Checks script execution permissions
16. **Published Binary Verification** - Confirms binary creation and location
17. **Symlink Verification** - Tests global installation symlinks

### Test Output Example
```bash
🚀 Wurp Terminal Clone - Test Suite
==================================

ℹ️  Testing project: /home/user/workspace/my-terminal

🔍 Running Wurp Terminal Tests...

🧪 Test 1: Help command
✅ PASSED: Help command
🧪 Test 2: Dependency check
✅ PASSED: Dependency check
...
🧪 Test 17: Symlink verification
✅ PASSED: Symlink verification

═══════════════════════════════════════
📊 Test Results Summary
═══════════════════════════════════════

ℹ️  Tests Run: 17
✅ Tests Passed: 17
✅ All tests passed successfully! 🎉

✨ Wurp Terminal Clone is working correctly!
```

### Debug Mode
```bash
# See detailed module loading and execution
./wurp-terminal-bootstrap.sh --debug -p ~/debug -n test-project
```

### Verify Installation
```bash
# Check generated project works
cd your-project
./scripts/wurp-terminal check    # Verify dependencies
./scripts/wurp-terminal build    # Test build process
./scripts/wurp-terminal status   # Show installation status

# Run full test suite
/path/to/bootstrap/test-wurp-terminal.sh ./
```

## 📚 Project Structure Details

| Component | Purpose | Technology |
|-----------|---------|------------|
|| **Program.cs** | Application entry point with async/await | C# 12, .NET 9 |
| **Core/*.cs** | Modular service architecture | Clean Architecture pattern |
| **wurp-config.json** | Centralised configuration | JSON with jq processing |
| **scripts/wurp-terminal** | Build and deployment automation | Bash with error handling |
| **Function library** | Reusable build and utility functions | Modular bash functions |

## 🎯 Example Usage Scenarios

### Basic Project Creation
```bash
# Simple project in current directory
./wurp-terminal-bootstrap.sh

# Custom location and name
./wurp-terminal-bootstrap.sh -p ~/workspace -n ai-terminal
cd ~/workspace/ai-terminal
./scripts/wurp-terminal install
```

### Development Workflow
```bash
# Create development version with debug
./wurp-terminal-bootstrap.sh --debug -p ~/dev -n terminal-dev
cd ~/dev/terminal-dev

# Iterative development
./scripts/wurp-terminal build    # Quick build for testing
./scripts/wurp-terminal publish  # Optimised build
./scripts/wurp-terminal install  # Full installation
```

### Production Deployment
```bash
# Create production version
./wurp-terminal-bootstrap.sh -p /opt -n company-terminal
cd /opt/company-terminal
./scripts/wurp-terminal install

# Verify installation
./scripts/wurp-terminal status
company-terminal --help
```

## 🌟 Why This Architecture Rocks

### 🧠 **Maintainable Code**
- **Single responsibility** - Each module has one clear purpose
- **Easy debugging** - Know exactly where to look for issues
- **Clean extensions** - Add features without touching existing code

### 🚀 **Developer Experience**
- **Fast iterations** - Modify only what you need
- **Debug mode** - See exactly what's happening
- **Module isolation** - Test components independently

### 📈 **Scalable Design**
- **Numbered modules** - Clear dependency ordering
- **Graceful fallbacks** - Works with or without modules
- **Future-ready** - Easy to add new capabilities

---

## 📊 **Current State**

### **Complete: 60%** ✅
- Core architecture ✅
- File generation ✅
- Project structure ✅
- Basic build system ✅

### **Remaining: 40%** 🚧
- Enhanced build operations
- Shell/desktop integration
- Service management
- Advanced project management

---

**Built with ❤️ using .NET 9, C# 12, and Modular Bash Architecture**

*Transform your terminal experience with AI-powered assistance and modern development practices.*