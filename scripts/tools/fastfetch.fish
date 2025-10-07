function setup_fastfetch
    install_formula fastfetch; or return $status
    sync_config fastfetch fastfetch
end
