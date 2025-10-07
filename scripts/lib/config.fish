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
        warn "Skipping $relative: source $src not found"
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
            log "$relative already up to date; skipping."
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
        command mkdir -p "$dst"
        if not command -q rsync
            warn "rsync not found; falling back to copy for $relative"
            command rm -rf "$dst"
            command cp -R "$src" "$dst"
        else
            command rsync -a --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' "$src/" "$dst/"
        end
    else
        command cp "$src" "$dst"
    end

    log "Synced $relative"
end
