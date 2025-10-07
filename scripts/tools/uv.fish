function setup_uv
    install_formula uv; or return $status
    sync_config uv
end
