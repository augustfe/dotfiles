# Homebrew-related helpers.

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
        log "$formula already installed, checking for updates"
        if test $dry_run -eq 1
            return 0
        end
        command brew upgrade $formula --quiet
        return 0
    end

    log "Installing $formula"
    if test $dry_run -eq 1
        return 0
    end
    command brew install $formula
end
