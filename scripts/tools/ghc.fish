function setup_ghc
    install_formula ghc; or return $status
    sync_config ghc
end
