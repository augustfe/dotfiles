# Tool discovery and orchestration helpers.

function ensure_submodules
    if not test -f "$repo_root/.gitmodules"
        return
    end

    log "Updating git submodules"
    if test $dry_run -eq 1
        return
    end
    command git -C "$repo_root" submodule update --init --recursive
end

function prompt_for_tools
    if type -q fzf
        set -l header "Select tools (TAB to toggle, ENTER to confirm)"
        set -l selected (printf '%s\n' $available_tools | fzf --multi --ansi --prompt "Tools ❯ " --header "$header" --height=40% --border)
        set -l selection_status $status
        if test $selection_status -ne 0
            return 1
        end
        if test (count $selected) -eq 0
            return 1
        end
        printf '%s\n' $selected
        return 0
    end

    error "fzf is required for interactive selection. Install fzf or pass --tool/--all."
    return 1
end

function discover_tools --argument-names tools_dir
    if test -z "$tools_dir"
        return 1
    end

    set -l discovered
    for tool_file in $tools_dir/*.fish
        if not test -f "$tool_file"
            continue
        end

        set -l tool_name (basename "$tool_file" .fish)
        if test -z "$tool_name"
            continue
        end

        source "$tool_file"
        set discovered $discovered $tool_name
    end

    if test (count $discovered) -gt 0
        printf '%s\n' $discovered
    end
end
