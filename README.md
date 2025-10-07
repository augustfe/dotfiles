# dotfiles

This repository tracks the configuration files from `~/.config` along with two larger components maintained as Git submodules.

## Layout

- `.config/fastfetch`, `.config/gh`, `.config/ghc`, `.config/raycast`, `.config/uv`, `.config/wezterm`, `.config/starship.toml` are tracked directly in this repository.
- `.config/fish` → submodule pointing to [`github.com/augustfe/fish`](https://github.com/augustfe/fish).
- `.config/nvim` → submodule pointing to [`github.com/augustfe/nvim`](https://github.com/augustfe/nvim).

## Getting started

```bash
# Clone the main repository
git clone git@github.com:augustfe/dotfiles.git
cd dotfiles

# Install Homebrew and fish (one-time setup)
./bootstrap.sh

# Bootstrap tools & configs (interactive by default)
fish scripts/setup.fish

# Preview changes without modifying the system
fish scripts/setup.fish --dry-run --all
```

`bootstrap.sh` uses the official Homebrew installer and then installs the `fish` shell so subsequent runs of the Fish-based tooling can assume Homebrew is available. The main setup script pulls submodules, installs each selected tool, and copies the matching config into `~/.config`. When an existing config is detected it's moved into `~/.config/.backup/<tool>/<timestamp>/`, preserving every version created by the bootstrapper. Omit `--all` to be prompted or pass `--tool <name>` for a targeted setup. Add `--dry-run` to see what would happen without touching your system. When no tools are specified, you'll get an interactive [`fzf`](https://github.com/junegunn/fzf) multi-select (the script will offer to install `fzf` if it's missing).

### Cleaning up backups

Backups accumulate over time under `~/.config/.backup`. Run the helper script below to review and optionally delete the stored snapshots tool-by-tool:

```bash
fish scripts/cleanup_backups.fish
```

Use `--dry-run` to preview deletions or `--yes` to remove everything without prompting.

## Adding new configuration

1. Place small files or directories directly in `.config/` and commit as usual.
2. For larger, standalone configurations create a dedicated repository under `github.com/augustfe/<name>`, add it as a submodule (`git submodule add git@github.com:augustfe/<name>.git .config/<name>`), commit the resulting changes, and push both repositories.
