function setup_fish
    install_formula fish; or return $status
    sync_fish_config
end
