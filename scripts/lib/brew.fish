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
        log "$formula already installed"
        return 0
    end

    log "Installing $formula"
    if test $dry_run -eq 1
        return 0
    end
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

    log "Installing Cask $cask"
    if test $dry_run -eq 1
        return 0
    end
    command brew install --cask $cask
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
