# Shared helper functions for the dotfiles bootstrap script.

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

function log --argument-names msg
    echo "==> $msg"
end

function warn --argument-names msg
    set_color yellow
    echo "[warn] $msg"
    set_color normal
end

function error --argument-names msg
    set_color red
    echo "[error] $msg"
    set_color normal
end

function announce_tool --argument-names tool context
    set -l descriptor "Configuring $tool"
    if test -n "$context"
        set descriptor "$descriptor [$context]"
    end

    if test $dry_run -eq 1
        set descriptor "[dry-run] $descriptor"
    end

    set_color --bold brcyan
    echo "==> $descriptor"
    set_color normal
end

function ensure_config_home
    if test -d "$home_config"
        return 0
    end

    if test $dry_run -eq 1
        log "[dry-run] Would create directory $home_config"
        return 0
    end

    command mkdir -p "$home_config"
end

function load_brew_env
    for prefix in /opt/homebrew /usr/local
        if test -x "$prefix/bin/brew"
            eval ($prefix/bin/brew shellenv)
            break
        end
    end
end

function install_formula --argument-names formula
    if not type -q brew
        error "Homebrew isn't ready; cannot install $formula"
        return 1
    end

    if command brew list --formula $formula >/dev/null 2>/dev/null
        log "$formula already installed"
        return 0
    end

    if test $dry_run -eq 1
        log "[dry-run] Would install formula $formula"
        return 0
    end

    log "Installing $formula"
    command brew install $formula
end

function install_cask --argument-names cask
    if not type -q brew
        error "Homebrew isn't ready; cannot install $cask"
        return 1
    end

    if command brew list --cask $cask >/dev/null 2>/dev/null
        log "$cask already installed"
        return 0
    end

    if test $dry_run -eq 1
        log "[dry-run] Would install cask $cask"
        return 0
    end

    log "Installing Cask $cask"
    command brew install --cask $cask
end

function sync_config --argument-names relative
    set src "$dotconfig/$relative"
    set dst "$home_config/$relative"

    if not test -e "$src"
        warn "Skipping $relative: source $src not found"
        return 0
    end

    set -l needs_sync 1
    if test -e "$dst"
        if test -d "$src"
            if test -d "$dst"
                if command -q rsync
                    set -l diff_output (command rsync -ani --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' "$src/" "$dst/")
                    if test (count $diff_output) -eq 0
                        set needs_sync 0
                    end
                else
                    command diff -rq "$src" "$dst" >/dev/null
                    if test $status -eq 0
                        set needs_sync 0
                    end
                end
            end
        else if test -f "$dst"
            command cmp -s "$src" "$dst"
            if test $status -eq 0
                set needs_sync 0
            end
        end
    end

    if test $needs_sync -eq 0
        if test $dry_run -eq 1
            log "[dry-run] $relative already up to date; skipping backup & sync."
        else
            log "$relative already up to date; skipping."
        end
        return 0
    end

    ensure_config_home
    set dest_parent (dirname "$dst")
    if not test -d "$dest_parent"
        if test $dry_run -eq 1
            log "[dry-run] Would create directory $dest_parent"
        else
            command mkdir -p "$dest_parent"
        end
    end

    if test -e "$dst"
        set -l backup (backup_target "$dst")
        set -l backup_status $status
        if test $backup_status -eq 1
            warn "Skipped $relative per user request"
            return 0
        end

        if test -n "$backup"
            if test $dry_run -eq 1
                log "[dry-run] Would back up existing $relative to $backup"
            else
                log "Backed up existing $relative to $backup"
            end
        end
    end

    if test -d "$src"
        if test $dry_run -eq 1
            log "[dry-run] Would sync directory $src -> $dst"
            return 0
        end

        command mkdir -p "$dst"
        if not command -q rsync
            warn "rsync not found; falling back to copy for $relative"
            command rm -rf "$dst"
            command cp -R "$src" "$dst"
        else
            command rsync -a --delete --exclude '.git' --exclude '.gitmodules' --exclude '.DS_Store' "$src/" "$dst/"
        end
    else
        if test $dry_run -eq 1
            log "[dry-run] Would copy file $src -> $dst"
            return 0
        end

        command cp "$src" "$dst"
    end

    if test $dry_run -eq 1
        log "[dry-run] Would mark $relative as synced"
    else
        log "Synced $relative"
    end
end

function ensure_fzf
    if type -q fzf
        return 0
    end

    log "Ensuring fzf is available for interactive selection"
    install_formula fzf
    set -l status_code $status
    if test $status_code -eq 0
        load_brew_env
    end
    return $status_code
end

function ensure_submodules
    if not test -f "$repo_root/.gitmodules"
        return
    end

    if test $dry_run -eq 1
        log "[dry-run] Would update git submodules"
        return
    end

    log "Updating git submodules"
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

function confirm_backup --argument-names path
    if test $assume_yes -eq 1
        return 0
    end

    set name (basename "$path")
    read -P "Existing $name will be backed up. Continue? [Y/n] " reply
    if test -z "$reply"
        return 0
    end

    if string match -ri 'y(es)?' -- $reply >/dev/null
        return 0
    end

    return 1
end

function backup_target --argument-names target
    if not test -e "$target"
        return 0
    end

    if test $assume_yes -ne 1
        if not confirm_backup "$target"
            return 1
        end
    end

    set timestamp (date "+%Y%m%d-%H%M%S")
    set backup "$target.backup.$timestamp"

    if test $dry_run -eq 1
        echo $backup
        return 0
    end

    command mv "$target" "$backup"
    echo $backup
end