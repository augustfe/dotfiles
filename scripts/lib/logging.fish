# Logging and messaging utilities.

function log --argument-names msg
    if test $dry_run -eq 1
        echo "==> [dry-run] $msg"
    else
        echo "==> $msg"
    end
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
