# 🚀 Warp Terminal Bootstrap

A comprehensive bootstrap script that generates a complete AI-powered terminal application built with .NET 8.

## Quick Start

```bash
# Create project in current directory
./bootstrap-warp-terminal.sh

# Create project in specific location
./bootstrap-warp-terminal.sh -p ~/workspace -n my-terminal

# Show help
./bootstrap-warp-terminal.sh -h
```

## Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `-p, --path` | Base directory for project | `-p ~/Projects` |
| `-n, --name` | Project folder name | `-n my-terminal` |
| `-h, --help` | Show help message | `-h` |

## What It Creates

The bootstrap script generates a complete project structure:

```
your-project/
├── Program.cs                          # Main terminal application
├── WarpTerminal.csproj                 # .NET project file
├── warp-config.json                   # Configuration file
├── scripts/
│   ├── warp-terminal                   # Main launcher script
│   └── lib/
│       └── warp-terminal-functions.sh # Function library
├── bin/                                # Build output (after build)
└── README.md                          # Project documentation
```

## Generated Terminal Features

The created terminal includes:

- 🤖 **AI Integration** - FreelanceAI compatible commands
- 📜 **Command History** - Persistent command history
- 🎨 **Multiple Themes** - Default, dark, and warp themes
- 🐚 **Shell Integration** - Works with bash/zsh
- ⚡ **System Commands** - Execute any system command
- 🔧 **Built-in Commands** - help, clear, history, themes

## After Bootstrap

Navigate to your project and use the generated build script:

```bash
cd your-project

# Check dependencies
./scripts/warp-terminal check

# Full installation (build, publish, integrate)
./scripts/warp-terminal install

# Run the terminal
warp-terminal
```

## Generated Terminal Commands

Once installed, use these commands in the terminal:

### AI Commands
```bash
ai explain "docker ps"        # Explain a command
ai suggest "deploy app"       # Get suggestions
ai debug "permission denied"  # Debug help
```

### Theme Commands
```bash
theme                         # Show current theme
theme dark                    # Switch to dark theme
theme warp                    # Switch to warp theme
```

### Built-in Commands
```bash
help                          # Show help
history                       # Show command history
clear                         # Clear screen
exit                          # Exit terminal
```

## Requirements

- .NET 8 SDK
- jq (JSON processor)
- curl (for AI service checks)
- bash/zsh shell

## Project Structure Details

| File | Purpose |
|------|---------|
| `Program.cs` | Main C# application with AI, themes, history |
| `warp-config.json` | Centralized configuration |
| `scripts/warp-terminal` | Build, install, and run script |
| `scripts/lib/warp-terminal-functions.sh` | Reusable functions |

## Example Usage

```bash
# Bootstrap a new terminal project
./bootstrap-warp-terminal.sh -p ~/Development -n ai-terminal

# Navigate and install
cd ~/Development/ai-terminal
./scripts/warp-terminal install

# Start using your AI terminal
warp-terminal
```

---

**Built with ❤️ using .NET 8 and Bash**