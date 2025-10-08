function setup_uv
    if not type -q uv
        if test $dry_run -eq 1
            log "uv not installed; would install from https://astral.sh/uv/install.sh"
        else
            command curl -LsSf https://astral.sh/uv/install.sh | sh; or return $status
        end
    end
    
    log "Checking for updates and adding completions"
    if test $dry_run -eq 1
        return 0
    end
    command uv self update --quiet; or return $status

    # Add uv completions
    set -l completions_dir "$home_config/fish/completions"
    if not test -d "$completions_dir"
        command mkdir -p "$completions_dir"; or return $status
    end
    echo 'uv generate-shell-completion fish | source' > $completions_dir/uv.fish
    echo 'uvx --generate-shell-completion fish | source' > $completions_dir/uvx.fish
end
