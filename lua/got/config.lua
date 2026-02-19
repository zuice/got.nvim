local Util = require("got.util")

local M = {}

M.defaults = {
    root = vim.fn.stdpath("data") .. "/got",
    lockfile = vim.fn.stdpath("config") .. "/got-lock.json",
    git = {
        timeout = 60,
        default_branch = "main",
    },
    concurrency = 4,
    debug = false,
    install_missing = true,
}

M.options = {}
M.plugins = {}
M.plugin_specs = {}

function M.setup(opts)
    opts = opts or {}
    
    if type(opts) == "string" then
        opts = { spec = opts }
    end
    
    if opts.spec then
        opts.plugins = M.import_spec(opts.spec)
    end
    
    M.options = vim.tbl_deep_extend("force", M.defaults, opts)
    M.options.root = Util.norm(M.options.root)
    M.options.lockfile = Util.norm(M.options.lockfile)
    
    Util.mkdir(M.options.root)
    
    if opts.plugins then
        M.plugin_specs = opts.plugins
    end
end

function M.import_spec(spec)
    local specs = {}
    
    if type(spec) == "string" then
        local ok, mod = pcall(require, spec)
        if ok then
            if mod then
                specs[#specs + 1] = mod
            end
            local mod_path = vim.fn.stdpath("config") .. "/lua/" .. spec:gsub("%.", "/")
            M.import_dir(mod_path, specs)
        end
    elseif type(spec) == "table" then
        for _, s in ipairs(spec) do
            if type(s) == "table" and s.import then
                local sub_specs = M.import_spec(s.import)
                vim.list_extend(specs, sub_specs)
            else
                specs[#specs + 1] = s
            end
        end
    end
    
    return specs
end

function M.import_dir(path, specs)
    if not Util.exists(path) then return end
    
    for name, type in vim.fs.dir(path) do
        if type == "file" and name:match("%.lua$") then
            local mod_name = name:gsub("%.lua$", "")
            local full_mod
            for part in path:gmatch("/lua/(.+)$") do
                full_mod = part .. "." .. mod_name
                break
            end
            if not full_mod then
                full_mod = mod_name
            end
            local ok, mod = pcall(require, full_mod)
            if ok and mod then
                specs[#specs + 1] = mod
            end
        end
    end
end

return M
