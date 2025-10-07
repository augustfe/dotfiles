#!/usr/bin/env fish
# Bootstrap augustfe dotfiles onto a fresh macOS machine.

set script_path (status -f)
set script_dir (cd (dirname "$script_path"); and pwd)
set -g repo_root (cd "$script_dir/.."; and pwd)
set -g dotconfig "$repo_root/.config"
set -g home_config "$HOME/.config"

set -g assume_yes 0
set -g dry_run 0
set -g selected_tools
set -g available_tools fastfetch gh starship uv wezterm fish nvim

source "$script_dir/lib/helpers.fish"
for tool in $available_tools
    source "$script_dir/tools/$tool.fish"
end

set -g __completed_tools

function tool_dependencies --argument-names tool
    switch $tool
        case fish
            printf '%s\n' starship fastfetch
        case '*'
            return 0
    end
end

function run_tool --argument-names tool context
    if contains -- $tool $__completed_tools
        return 0
    end

    set -l deps (tool_dependencies $tool)
    for dep in $deps
        if test -z "$dep"
            continue
        end
        run_tool $dep "dependency of $tool"; or return $status
    end

    if contains -- $tool $__completed_tools
        return 0
    end

    set -l function_name setup_$tool
    if not functions -q $function_name
        warn "Unknown tool '$tool'"
        return 1
    end

    if test -n "$context"
        announce_tool $tool $context
    else
        announce_tool $tool
    end

    $function_name
    set -l status_code $status
    if test $status_code -eq 0
        set -g __completed_tools $__completed_tools $tool
    end
    return $status_code
end

function usage
    echo "Usage: setup.fish [--all] [--tool TOOL ...] [--yes] [--dry-run] [--help]"
    echo
    echo "  --all           Install and configure every supported tool"
    echo "  --tool TOOL     Install a specific tool (may be repeated)"
    echo "  --yes           Assume 'yes' to non-critical prompts (overwrites/backups)"
    echo "  --dry-run       Show the actions without making changes"
    echo "  --help          Show this help message"
    echo
    echo "If no tools are specified, you'll be prompted to choose."
end

function parse_args
    set -l argv $argv
    argparse 'h/help' 'a/all' 't/tool=+' 'y/yes' 'd/dry-run' -- $argv; or begin
        usage
        return 1
    end

    if set -q _flag_help
        usage
        exit 0
    end

    if set -q _flag_yes
        set -g assume_yes 1
    end

    if set -q _flag_dry_run
        set -g dry_run 1
    end

    if set -q _flag_all
        set -g selected_tools $available_tools
    end

    if set -q _flag_tool
        set -g selected_tools $_flag_tool
    end
end

function normalize_selected_tools
    if not set -q selected_tools
        return 0
    end

    if test (count $selected_tools) -eq 0
        set -e selected_tools
        return 0
    end

    set -l filtered
    set -l invalid
    for tool in $selected_tools
        if contains -- $tool $available_tools
            set filtered $filtered $tool
        else
            set invalid $invalid $tool
        end
    end

    for name in $invalid
        warn "Ignoring unknown tool '$name'"
    end

    if test (count $filtered) -eq 0
        set -e selected_tools
        return 1
    end

    set -g selected_tools $filtered
    return 0
end

parse_args $argv; or exit 1

# Ensure we can find Homebrew-installed binaries (like fzf) before prompting.
load_brew_env

normalize_selected_tools; or begin
    usage
    error "No valid tools selected; exiting."
    exit 1
end

if not set -q selected_tools
    ensure_fzf; or begin
        error "fzf is required for interactive selection. Install it or supply --tool/--all."
        exit 1
    end
    set -l selection (prompt_for_tools)

    set -l prompt_status $status
    if test $prompt_status -ne 0
        usage
        error "No tools selected; exiting."
        exit 1
    end
    if test (count $selection) -eq 0
        usage
        error "No tools selected; exiting."
        exit 1
    end
    set selected_tools $selection
    normalize_selected_tools; or begin
        usage
        error "No valid tools selected; exiting."
        exit 1
    end
end

ensure_submodules

set -l failures
for tool in $selected_tools
    run_tool $tool
    if test $status -ne 0
        set failures $failures $tool
    end
end

if test (count $failures) -gt 0
    error "Some tools failed: $failures"
    exit 1
end

if test $dry_run -eq 1
    log "[dry-run] Completed without making changes."
else
    log "All selected tools configured successfully."
end
