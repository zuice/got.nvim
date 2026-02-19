local Config = require("got.config")
local Spec = require("got.spec")
local Manage = require("got.manage")
local Util = require("got.util")

local M = {}

M.version = "1.0.0"

function M.setup(spec_or_opts, opts)
    if type(spec_or_opts) == "string" or (type(spec_or_opts) == "table" and spec_or_opts[1]) then
        opts = opts or {}
        opts.spec = spec_or_opts
    else
        opts = spec_or_opts or {}
    end
    
    Config.setup(opts)
    
    local plugins = Spec.parse(Config.plugin_specs)
    Config.plugins = plugins
    
    for name, plugin in pairs(plugins) do
        if Util.exists(plugin.dir) then
            vim.opt.rtp:append(plugin.dir)
        end
    end
    
    for name, plugin in pairs(plugins) do
        if plugin.init then
            local ok, err = pcall(plugin.init, plugin)
            if not ok then
                Util.warn("Failed to run init for " .. plugin.name .. ": " .. tostring(err))
            end
        end
    end
    
    local load_now = {}
    for name, plugin in pairs(plugins) do
        if plugin.lazy ~= true then
            load_now[#load_now + 1] = plugin
        end
    end
    
    local order, err = require("got.deps").sort(plugins)
    if err then
        Util.error(err)
    else
        for _, name in ipairs(order) do
            local plugin = plugins[name]
            if plugin.lazy ~= true then
                M.run_config(plugin)
            end
        end
    end
    
    if Config.options.install_missing ~= false then
        vim.api.nvim_create_autocmd("UIEnter", {
            once = true,
            callback = function()
                local has_missing = false
                for name, plugin in pairs(plugins) do
                    if not Util.exists(plugin.dir) then
                        has_missing = true
                        break
                    end
                end
                if has_missing then
                    Util.log("Installing missing plugins...")
                    Manage.install()
                    for name, plugin in pairs(plugins) do
                        if not plugin.lazy and plugin.config then
                            M.run_config(plugin)
                        end
                    end
                end
            end,
        })
    end
    
    M.setup_lazy_loaders(plugins)
end

function M.run_config(plugin)
    if not plugin.config then return end
    
    if not Util.exists(plugin.dir) then
        return
    end
    
    if plugin.opts and type(plugin.config) == "function" then
        plugin.config(plugin.opts, plugin)
    else
        plugin.config(plugin)
    end
end

function M.setup_lazy_loaders(plugins)
    local event_plugins = {}
    local cmd_plugins = {}
    local ft_plugins = {}
    
    for name, plugin in pairs(plugins) do
        if plugin.lazy == true then
            if plugin.event then
                local events = type(plugin.event) == "table" and plugin.event or { plugin.event }
                for _, event in ipairs(events) do
                    event_plugins[event] = event_plugins[event] or {}
                    event_plugins[event][name] = plugin
                end
            end
            if plugin.cmd then
                local cmds = type(plugin.cmd) == "table" and plugin.cmd or { plugin.cmd }
                for _, cmd in ipairs(cmds) do
                    cmd_plugins[cmd] = plugin
                end
            end
            if plugin.ft then
                local fts = type(plugin.ft) == "table" and plugin.ft or { plugin.ft }
                for _, ft in ipairs(fts) do
                    ft_plugins[ft] = ft_plugins[ft] or {}
                    ft_plugins[ft][name] = plugin
                end
            end
        end
    end
    
    for event, plugin_map in pairs(event_plugins) do
        vim.api.nvim_create_autocmd(event, {
            once = true,
            callback = function()
                for name, plugin in pairs(plugin_map) do
                    if not Util.exists(plugin.dir) then
                        Manage.install()
                    end
                    vim.opt.rtp:append(plugin.dir)
                    M.run_config(plugin)
                end
            end,
        })
    end
    
    for ft, plugin_map in pairs(ft_plugins) do
        vim.api.nvim_create_autocmd("FileType", {
            pattern = ft,
            once = true,
            callback = function()
                for name, plugin in pairs(plugin_map) do
                    if not Util.exists(plugin.dir) then
                        Manage.install()
                    end
                    vim.opt.rtp:append(plugin.dir)
                    M.run_config(plugin)
                end
            end,
        })
    end
    
    for cmd, plugin in pairs(cmd_plugins) do
        vim.api.nvim_create_user_command(cmd, function(opts)
            vim.api.nvim_del_user_command(cmd)
            if not Util.exists(plugin.dir) then
                Manage.install()
            end
            vim.opt.rtp:append(plugin.dir)
            M.run_config(plugin)
            vim.cmd(opts.args)
        end, { bang = true, nargs = "*" })
    end
end

function M.install()
    return Manage.install()
end

function M.update(plugin_name)
    return Manage.update(plugin_name)
end

function M.sync()
    return Manage.sync()
end

function M.clean()
    return Manage.clean()
end

function M.list()
    return Manage.list()
end

function M.bootstrap()
    local got_path = vim.fn.stdpath("data") .. "/got/got.nvim"
    if not Util.exists(got_path) then
        vim.fn.system({
            "git", "clone", "--depth", "1",
            "https://github.com/zuice/got.nvim.git",
            got_path,
        })
    end
    vim.opt.rtp:prepend(got_path)
end

return M
