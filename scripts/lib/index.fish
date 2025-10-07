# Load all helper modules in the correct order.
set helper_dir (dirname (status -f))
set helper_modules state logging backup config brew tools
for helper in $helper_modules
    source "$helper_dir/$helper.fish"
end
