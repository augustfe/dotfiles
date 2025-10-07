# Initialize global state defaults for the bootstrap scripts.

if not set -q repo_root
    set -g repo_root (pwd)
end
if not set -q dotconfig
    set -g dotconfig "$repo_root/.config"
end
if not set -q home_config
    set -g home_config "$HOME/.config"
end
if not set -q assume_yes
    set -g assume_yes 0
end
if not set -q dry_run
    set -g dry_run 0
end
if not set -q selected_tools
    set -g selected_tools
end
