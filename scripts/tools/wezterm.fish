function setup_wezterm
    install_cask wezterm; or return $status
    sync_config wezterm
end
