# Dotfiles

My personal Arch Linux dotfiles and configuration.

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MadMax182/dotfiles/main/init.sh)
```

## Manual Install

```bash
git clone https://github.com/MadMax182/dotfiles.git
cd ~/.userconfig
bash ./install/install.sh
```

## What's Included

<!-- PACKAGE_LIST_START -->
### Dependencies

- **1password** - Password manager
- **1password-cli** - Password manager CLI integration
- **nautilus** - file manager
- **kitty** - Modern, GPU-accelerated terminal emulator
- **lazygit** - Terminal UI for git commands (makes git operations visual and easier)
- **git** - Version control system for tracking code changes
- **hyprland** - The main tiling window manager (replaces traditional desktop environments)
- **hyprpaper** - Wallpaper utility for Hyprland
- **hyprlock** - Screen locker for Hyprland
- **hypridle** - Idle daemon (triggers actions when you're inactive, like locking screen)
- **hyprpicker** - Color picker tool for Hyprland
- **wget** - Command-line tool to download files from the web
- **unzip** - Extracts .zip compressed files
- **rsync** - Syncs and transfers files efficiently
- **xdg-user-dirs** - Creates standard user directories (Downloads, Documents, etc.)
- **tumbler** - Thumbnail generator for file managers
- **gvfs** - Virtual filesystem (enables trash, network drives, etc.)
- **xdg-desktop-portal-gtk** - Desktop integration for GTK apps on Wayland
- **xdg-desktop-portal-hyprland** - Desktop integration specifically for Hyprland
- **qt5-wayland** - Allows Qt5 applications to run on Wayland
- **qt6-wayland** - Allows Qt6 applications to run on Wayland
- **qt6ct** - Qt6 configuration tool for theming
- **figlet** - Creates ASCII art text banners
- **nwg-look** - GTK settings editor (change themes, icons, fonts)
- **breeze** - KDE's Breeze theme/cursor set
- **waypaper** - GUI wallpaper setter for Wayland
- **waybar** - Highly customizable status bar for Wayland
- **rofi-wayland** - Application launcher and window switcher
- **swaync** - Notification daemon (shows popup notifications)
- **wlogout** - Logout menu with icons (shutdown, reboot, logout options)
- **nwg-dock-hyprland** - MacOS-style dock for Hyprland
- **fastfetch** - System information tool (shows OS, CPU, RAM, etc. with logo)
- **htop** - Interactive process viewer (better than basic 'top')
- **neovim** - Modern, extensible terminal text editor (Vim fork)
- **libnotify** - Library for sending desktop notifications
- **polkit-gnome** - Authentication agent (prompts for sudo password in GUI)
- **imagemagick** - Image manipulation toolkit (resize, convert, edit images)
- **jq** - JSON processor for parsing/manipulating JSON data
- **xclip** - Command-line clipboard manager
- **brightnessctl** - Control screen brightness
- **blueman** - Bluetooth manager (GUI and applet)
- **nm-connection-editor** - GUI for editing network connections
- **power-profiles-daemon** - Manages power profiles (performance/balanced/power-saver)
- **grim** - Screenshot tool for Wayland
- **slurp** - Screen area selector (works with grim to select regions)
- **grimblast-git** - Wrapper that combines grim and slurp functionality
- **cliphist** - Clipboard history manager for Wayland
- **flatpak** - Universal package manager for sandboxed apps
### Applications

- brave-bin
### Fonts

- DepartureMono
- CommitMono
<!-- PACKAGE_LIST_END -->

## Features

- Automated package installation (pacman + AUR via yay)
- Flatpak support for applications
- Automatic font installation (Nerd Fonts)
- Config file linking with backup
- Home directory dotfile management
- Theme linking system

## Repository Structure

```
.
├── config/          # Configuration files (linked to ~/.config)
├── home/            # Home directory dotfiles (linked to ~/)
├── install/         # Installation scripts and lists
│   ├── dependencies/
│   │   ├── dependencies.list  # System packages
│   │   ├── apps.list          # Applications (supports flatpak:)
│   │   └── fonts.list         # Nerd Fonts to install
│   └── scripts/     # Installation scripts
├── themes/          # Theme configurations
└── wallpapers/      # Wallpaper collection
```

## License

MIT
