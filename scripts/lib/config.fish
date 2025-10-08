# Helpers for preparing configuration directories and syncing files.

function ensure_config_home
    if test -d "$home_config"
        return 0
    end

    log "Creating directory $home_config"
    if test $dry_run -eq 1
        return 0
    end
    command mkdir -p "$home_config"
end

function configs_match --argument-names src dst
    if test -d "$src" -a -d "$dst"
        if command -q rsync
            set -l diff_output (command rsync -ani --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' "$src/" "$dst/")
            if test (count $diff_output) -eq 0
                return 0
            end
            return 1
        end

        command diff -rq "$src" "$dst" >/dev/null
        return $status
    end

    if test -f "$src" -a -f "$dst"
        command cmp -s "$src" "$dst"
        return $status
    end

    return 1
end

function derive_tool_name --argument-names relative
    if test -z "$relative"
        return 1
    end

    set -l first_component (string split '/' -- $relative)[1]
    if test -z "$first_component"
        set first_component (basename "$relative")
    end

    set -l tool (string split '.' -- $first_component)[1]
    if test -z "$tool"
        set tool $first_component
    end

    echo $tool
end

function sync_config --argument-names relative tool_name
    set src "$dotconfig/$relative"
    set dst "$home_config/$relative"

    if not test -e "$src"
        warn "Skipping configs for $relative: source $src not found"
        return 0
    end

    if test -z "$tool_name"
        set tool_name (derive_tool_name $relative)
    end

    if test -z "$tool_name"
        set tool_name (basename "$relative")
    end

    if test -e "$dst"
        configs_match "$src" "$dst"
        if test $status -eq 0
            log "Configs for $relative already up to date; skipping."
            return 0
        end
    end

    ensure_config_home

    set dest_parent (dirname "$dst")
    if not test -d "$dest_parent"
        log "Creating directory $dest_parent"
        if test $dry_run -eq 0
            command mkdir -p "$dest_parent"
        end
    end

    if test -e "$dst"
        set -l backup (backup_target "$dst" "$tool_name")
        set -l backup_status $status
        if test $backup_status -eq 1
            warn "Skipped $relative per user request"
            return 0
        end

        if test -n "$backup"
            log "Backed up existing $relative to $backup"
        end
    end

    if test $dry_run -eq 1
        if test -d "$src"
            log "Would sync directory $src -> $dst"
        else
            log "Would copy file $src -> $dst"
        end
        return 0
    end

    if test -d "$src"
        if test $dry_run -ne 1 -a -e "$dst"
            command rm -rf "$dst"
        end

        command rsync -a --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' "$src/" "$dst/"
        set -l rsync_status $status
        if test $rsync_status -ne 0
            return $rsync_status
        end
    else
        command cp "$src" "$dst"
        set -l file_copy_status $status
        if test $file_copy_status -ne 0
            return $file_copy_status
        end
    end

    log "Synced $relative"
    return 0
end

function sync_fish_config
    set relative fish
    set tool_name fish
    set src "$dotconfig/$relative"
    set dst "$home_config/$relative"
    set completions_dir "completions"

    if not test -d "$src"
        warn "Skipping fish config: source $src not found"
        return 0
    end

    set -l fish_tool_name $tool_name

    ensure_config_home

    if test -e "$dst"
        configs_match "$src" "$dst"
        if test $status -eq 0
            log "Fish configs already up to date; skipping."
            return 0
        end
    end

    set dest_parent (dirname "$dst")
    if not test -d "$dest_parent"
        log "Creating directory $dest_parent"
        if test $dry_run -eq 0
            command mkdir -p "$dest_parent"
        end
    end

    set -l only_completions_diff 0
    if test -d "$dst"; and command -q rsync
        set -l diff_output (command rsync -ani --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' --exclude "$completions_dir/" "$src/" "$dst/")
        if test (count $diff_output) -eq 0
            set only_completions_diff 1
        end
    end

    if test -e "$dst"
        if test $only_completions_diff -eq 1
            log "Skipping backup for fish; only completions differ."
        else
            set -l backup (backup_target "$dst" $fish_tool_name)
            set -l backup_status $status
            if test $backup_status -eq 1
                warn "Skipped fish config per user request"
                return 0
            end

            if test -n "$backup"
                log "Backed up existing fish config to $backup"
            end
        end
    end

    if test $dry_run -eq 1
        log "Would sync fish directory $src -> $dst (preserving completions)"
        if test -d "$src/$completions_dir"
            log "Would copy fish completions from $src/$completions_dir"
        end
        return 0
    end

    if not command -q rsync
        error "rsync is required to sync fish config while preserving completions"
        return 1
    end

    command mkdir -p "$dst"
    command rsync -a --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' --exclude "$completions_dir/" "$src/" "$dst/"
    set -l sync_status $status
    if test $sync_status -ne 0
        return $sync_status
    end

    if test -d "$src/$completions_dir"
        command mkdir -p "$dst/$completions_dir"
        command rsync -a "$src/$completions_dir/" "$dst/$completions_dir/"
    end

    log "Synced fish config"
end
