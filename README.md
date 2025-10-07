# augustfe dotfiles

This repository tracks the configuration files from `~/.config` along with two larger components maintained as Git submodules.

## Layout

- `.config/fastfetch`, `.config/gh`, `.config/ghc`, `.config/raycast`, `.config/uv`, `.config/wezterm`, `.config/starship.toml` are tracked directly in this repository.
- `.config/fish` → submodule pointing to [`github.com/augustfe/fish`](https://github.com/augustfe/fish).
- `.config/nvim` → submodule pointing to [`github.com/augustfe/nvim`](https://github.com/augustfe/nvim).

## Getting started

```fish
# Clone the main repository
git clone git@github.com:augustfe/dotfiles.git
cd dotfiles

# Pull nested configuration
git submodule update --init --recursive
```

After cloning, link the configurations into place (e.g. using GNU Stow or manual symlinks) so that they appear under `~/.config`.

## Adding new configuration

1. Place small files or directories directly in `.config/` and commit as usual.
2. For larger, standalone configurations create a dedicated repository under `github.com/augustfe/<name>`, add it as a submodule (`git submodule add git@github.com:augustfe/<name>.git .config/<name>`), commit the resulting changes, and push both repositories.
