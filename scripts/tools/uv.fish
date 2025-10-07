function setup_uv
    if not type -q brew
        error "Homebrew isn't ready; cannot manage uv"
        return 1
    end

    if command brew list uv >/dev/null 2>/dev/null
        log "uv already installed"
    else if test $dry_run -eq 1
        log "[dry-run] Would install uv (formula or tap astral-sh/uv/uv)"
    else
        log "Installing uv"
        command brew install uv; or command brew install astral-sh/uv/uv; or return $status
    end

    sync_config uv
end
