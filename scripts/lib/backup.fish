# Backup utilities for preserving existing configuration files.

function confirm_backup --argument-names path
    if test $assume_yes -eq 1
        return 0
    end

    set name (basename "$path")
    while true
        read -n 1 -P "Existing $name will be backed up. Continue? [Y/n] " reply
        set read_status $status
        echo

        if test $read_status -ne 0
            return 1
        end

        set reply_trim (string trim -- $reply)
        if test -z "$reply_trim"
            return 0
        end

        switch (string lower -- $reply_trim)
            case 'y'
                return 0
            case 'n'
                return 1
        end

        warn "Please answer with 'y' or 'n'."
    end
end

function backup_target --argument-names target tool_name
    if not test -e "$target"
        return 0
    end

    if test -z "$tool_name"
        set tool_name (basename "$target")
    end

    if test $assume_yes -ne 1
        if not confirm_backup "$target"
            return 1
        end
    end

    set timestamp (date "+%Y%m%d-%H%M%S")
    set backup_dir "$home_config/.backup/$tool_name/$timestamp"
    set backup_destination "$backup_dir/"(basename "$target")

    if test $dry_run -eq 1
        echo $backup_destination
        return 0
    end

    command mkdir -p "$backup_dir"
    command mv "$target" "$backup_dir/"
    echo $backup_destination
end
