function setup_fzf
    install_formula fzf; or return $status
    load_brew_env
    return 0
end
