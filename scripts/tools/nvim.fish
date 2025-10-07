function setup_nvim
    install_formula neovim; or return $status
    sync_config nvim
end
