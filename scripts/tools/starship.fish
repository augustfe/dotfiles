function setup_starship
    install_formula starship; or return $status
    sync_config starship.toml
end
