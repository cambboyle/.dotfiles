# dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed manually with symlinks.

## What's in here

| File/Folder | Description | |---|---| | `.zshrc` | Shell config — plugins, aliases, integrations | | 
`.gitconfig` | Git config | | `Brewfile` | All Homebrew packages | | `config/tmux/` | tmux config, 
session start script, project opener | | `config/zellij/` | Zellij config and layouts (kept for 
reference) | | `config/ghostty/` | Ghostty terminal config |
| `config/nvim/` | LazyVim config with auto dark/light mode switching |
| `config/lazygit/` | lazygit config with delta diffs and icons | ## 
| `config.omp.json` | oh-my-posh prompt config |

New machine setup
### 1. Install Xcode command line tools

```bash
xcode-select --install
```

### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Clone this repo

```bash
git clone git@github.com:cambboyle/.dotfiles.git ~/.dotfiles
```

### 4. Install all packages

```bash
brew bundle --file=~/.dotfiles/Brewfile
```

### 5. Symlink configs

```bash
# Shell
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig

# tmux
ln -sf ~/.dotfiles/config/tmux ~/.config/tmux

# Zellij
ln -sf ~/.dotfiles/config/zellij ~/.config/zellij

# Ghostty
ln -sf ~/.dotfiles/config/ghostty/config.ghostty \
  ~/Library/Application\ Support/com.mitchellh.ghostty/config.ghostty
```

### 6. Install tmux plugins

Launch tmux and install plugins manually:

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```

Or clone them directly:

```bash
cd ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tmux-sensible
git clone https://github.com/tmux-plugins/tmux-yank
git clone https://github.com/tmux-plugins/tmux-resurrect
git clone https://github.com/tmux-plugins/tmux-continuum
git clone https://github.com/tmux-plugins/tmux-cpu
git clone https://github.com/tmux-plugins/tmux-battery
git clone https://github.com/catppuccin/tmux catppuccin-tmux
```

### 7. Install zinit (zsh plugin manager)

Zinit installs itself automatically on first shell load.

### 8. Manual steps

These can't be automated and need to be done manually:

**Spotify (spotify-player):**
Run `spotify_player` and authenticate via browser on first launch.

**oh-my-posh:**
Copy your `config.omp.json` to `~/config.omp.json`.

**fzf-zellij:**
```bash
curl -L https://raw.githubusercontent.com/k-kuroguro/fzf-zellij/refs/heads/main/bin/fzf-zellij \
  -o ~/.local/bin/fzf-zellij chmod +x ~/.local/bin/fzf-zellij ``` 

**Neovim plugins:** LazyVim bootstraps itself on first launch. Just run `nvim` and wait for plugins to install.

**lazygit delta diffs:**
brew install git-delta

## tmux keybinds
Prefix is `Ctrl+Space`.

| Keybind | Action |
|---|---|
| `prefix + \|` | Split pane vertically |
| `prefix + -` | Split pane horizontally |
| `prefix + x` | Kill pane |
| `prefix + hjkl` | Navigate panes |
| `prefix + HJKL` | Resize panes |
| `prefix + c` | New window |
| `prefix + &` | Kill window |
| `prefix + ,` | Rename window |
| `prefix + 1-9` | Jump to window |
| `prefix + d` | Detach session |
| `prefix + p` | Open project (fuzzy picker) |
| `prefix + f` | Switch session |
| `prefix + r` | Reload config |
| `prefix + ?` | Show keybind cheatsheet |
