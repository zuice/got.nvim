local Util = require("got.util")
local Config = require("got.config")
local Spec = require("got.spec")
local Fetch = require("got.fetch")
local Lockfile = require("got.lockfile")
local Deps = require("got.deps")

local M = {}

local function is_installed(plugin)
    return Util.exists(plugin.dir) and Util.exists(Util.join(plugin.dir, ".git")) ~= true
end

local function get_local_commit(plugin)
    if not Util.exists(plugin.dir) then
        return nil
    end
    local lock_info = Lockfile.get(plugin.name)
    return lock_info and lock_info.commit
end

local function install_plugin(plugin)
    Util.log("Installing " .. plugin.full_name)
    
    local ref, err = Fetch.resolve_ref(plugin.owner, plugin.repo, plugin.branch, plugin.tag, plugin.commit)
    if err then
        return false, "failed to resolve ref: " .. err
    end
    
    if Util.exists(plugin.dir) then
        Util.rmrf(plugin.dir)
    end
    
    local ok, err = Fetch.download(plugin.owner, plugin.repo, ref, plugin.dir)
    if not ok then
        return false, err
    end
    
    Lockfile.set(plugin.name, {
        commit = ref,
        branch = plugin.branch,
        tag = plugin.tag,
    })
    
    Util.debug("Installed " .. plugin.full_name .. " @ " .. ref:sub(1, 7))
    return true, nil
end

local function update_plugin(plugin)
    local local_commit = get_local_commit(plugin)
    
    if plugin.commit then
        if local_commit == plugin.commit then
            Util.debug(plugin.name .. " is pinned and up to date")
            return true, nil, false
        end
    else
        local remote_commit, err = Fetch.get_commits(plugin.owner, plugin.repo, plugin.branch)
        if err then
            return false, "failed to check for updates: " .. err, false
        end
        
        if local_commit == remote_commit then
            Util.debug(plugin.name .. " is up to date")
            return true, nil, false
        end
    end
    
    Util.log("Updating " .. plugin.full_name)
    
    if Util.exists(plugin.dir) then
        Util.rmrf(plugin.dir)
    end
    
    local ref = plugin.commit
    if not ref then
        ref, _ = Fetch.get_commits(plugin.owner, plugin.repo, plugin.branch)
    end
    
    local ok, err = Fetch.download(plugin.owner, plugin.repo, ref, plugin.dir)
    if not ok then
        return false, err, false
    end
    
    Lockfile.set(plugin.name, {
        commit = ref,
        branch = plugin.branch,
        tag = plugin.tag,
    })
    
    return true, nil, true
end

function M.install()
    local plugins = Spec.parse(Config.plugin_specs)
    local order, err = Deps.sort(plugins)
    if err then
        Util.error(err)
        return false
    end
    
    local installed = 0
    local failed = 0
    
    for _, name in ipairs(order) do
        local plugin = plugins[name]
        if not is_installed(plugin) then
            local ok, err = install_plugin(plugin)
            if ok then
                installed = installed + 1
            else
                Util.error("Failed to install " .. plugin.full_name .. ": " .. err)
                failed = failed + 1
            end
        end
    end
    
    if installed > 0 then
        Util.log(string.format("Installed %d plugin(s)", installed))
    end
    if failed > 0 then
        Util.error(string.format("Failed to install %d plugin(s)", failed))
        return false
    end
    
    return true
end

function M.update(plugin_name)
    local plugins = Spec.parse(Config.plugin_specs)
    
    if plugin_name then
        local plugin = plugins[plugin_name]
        if not plugin then
            Util.error("Plugin not found: " .. plugin_name)
            return false
        end
        local ok, err, updated = update_plugin(plugin)
        if not ok then
            Util.error("Failed to update " .. plugin_name .. ": " .. err)
            return false
        end
        if updated then
            Util.log("Updated " .. plugin_name)
        else
            Util.log(plugin_name .. " is up to date")
        end
        return true
    end
    
    local order, err = Deps.sort(plugins)
    if err then
        Util.error(err)
        return false
    end
    
    local updated = 0
    local failed = 0
    
    for _, name in ipairs(order) do
        local plugin = plugins[name]
        local ok, err, was_updated = update_plugin(plugin)
        if not ok then
            Util.error("Failed to update " .. plugin.name .. ": " .. err)
            failed = failed + 1
        elseif was_updated then
            updated = updated + 1
        end
    end
    
    if updated > 0 then
        Util.log(string.format("Updated %d plugin(s)", updated))
    else
        Util.log("All plugins are up to date")
    end
    if failed > 0 then
        Util.error(string.format("Failed to update %d plugin(s)", failed))
        return false
    end
    
    return true
end

function M.clean()
    local plugins = Spec.parse(Config.plugin_specs)
    local keep = {}
    for name, _ in pairs(plugins) do
        keep[name] = true
    end
    
    local lock = Lockfile.read()
    local removed = 0
    
    for name, _ in pairs(lock) do
        if not keep[name] then
            local dir = Util.join(Config.options.root, name)
            if Util.exists(dir) then
                Util.log("Removing " .. name)
                Util.rmrf(dir)
                removed = removed + 1
            end
            Lockfile.remove(name)
        end
    end
    
    for _, entry in vim.fs.dir(Config.options.root) do
        if entry.type == "directory" and not keep[entry.name] then
            local dir = Util.join(Config.options.root, entry.name)
            Util.log("Removing " .. entry.name)
            Util.rmrf(dir)
            removed = removed + 1
        end
    end
    
    if removed > 0 then
        Util.log(string.format("Removed %d plugin(s)", removed))
    else
        Util.log("No plugins to remove")
    end
    
    return true
end

function M.sync()
    M.install()
    M.clean()
end

function M.list()
    local plugins = Spec.parse(Config.plugin_specs)
    local lock = Lockfile.read()
    
    local lines = {}
    lines[#lines + 1] = "Installed plugins:"
    lines[#lines + 1] = ""
    
    for name, plugin in pairs(plugins) do
        local status = is_installed(plugin) and "[installed]" or "[not installed]"
        local lock_info = lock[name]
        local version = lock_info and (lock_info.commit and lock_info.commit:sub(1, 7)) or "?"
        lines[#lines + 1] = string.format("  %s %s @%s", plugin.full_name, status, version)
    end
    
    Util.log(table.concat(lines, "\n"))
end

return M
