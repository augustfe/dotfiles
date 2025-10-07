function setup_fish
    install_formula fish; or return $status
    sync_config fish fish
end
