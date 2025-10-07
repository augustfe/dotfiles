#!/usr/bin/env fish
# Interactively prune configuration backups stored under ~/.config/.backup.

set script_path (status -f)
set script_dir (cd (dirname "$script_path"); and pwd)
set -g repo_root (cd "$script_dir/.."; and pwd)
set -g dotconfig "$repo_root/.config"
set -g home_config "$HOME/.config"

set -g assume_yes 0
set -g dry_run 0

source "$script_dir/lib/index.fish"

function usage
    echo "Usage: cleanup_backups.fish [--yes] [--dry-run] [--help]"
    echo
    echo "  --yes       Delete backups without prompting"
    echo "  --dry-run   Show which backups would be deleted without removing them"
    echo "  --help      Show this help message"
end

function parse_args
    set -l argv $argv
    argparse h/help y/yes d/dry-run -- $argv; or begin
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
end

function prompt_delete --argument-names tool
    if test $assume_yes -eq 1
        return 0
    end

    while true
        read -n 1 -P "Delete backups for $tool? [y/N] " reply
        set status_code $status
        echo

        if test $status_code -ne 0
            return 1
        end

        set reply_trim (string trim -- $reply)
        if test -z "$reply_trim"
            return 1
        end

        switch (string lower -- $reply_trim)
            case y
                return 0
            case n
                return 1
        end

        warn "Please answer with 'y' or 'n'."
    end
end

parse_args $argv; or exit 1

set backup_root "$home_config/.backup"
if not test -d "$backup_root"
    log "No backups found in $backup_root"
    exit 0
end

set -l entries
for entry in $backup_root/*
    if test -d "$entry" -o -f "$entry"
        set entries $entries $entry
    end
end

if test (count $entries) -eq 0
    log "No backups found in $backup_root"
    exit 0
end

for entry in $entries
    if test -d "$entry"
        set tool (basename "$entry")
        set -l snapshots (command find "$entry" -mindepth 1 -maxdepth 1)
        if test (count $snapshots) -gt 0
            log "Backups for $tool:"
            for snapshot in $snapshots
                set rel (string replace "$backup_root/" "" $snapshot)
                log "  $rel"
            end
        else
            log "No snapshots recorded for $tool."
        end
    else
        set tool (basename "$entry")
        log "Legacy backup artifact: $tool"
    end

    if prompt_delete $tool
        if test $dry_run -eq 1
            log "Would delete backups for $tool at $entry"
        else
            command rm -rf "$entry"
            log "Deleted backups for $tool"
        end
    else
        log "Kept backups for $tool"
    end
end

if test $dry_run -eq 1
    log "Dry-run complete. Backups were not removed."
    exit 0
end

if test -d "$backup_root"
    set -l remaining (command find "$backup_root" -mindepth 1 -maxdepth 1)
    if test (count $remaining) -eq 0
        command rmdir "$backup_root"
        log "Removed empty backup directory $backup_root"
    end
end

log "Backup cleanup complete."
