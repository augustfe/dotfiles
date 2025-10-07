function setup_gh
    install_formula gh; or return $status
    sync_config gh gh
end
