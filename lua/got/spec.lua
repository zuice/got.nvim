local Util = require("got.util")
local Config = require("got.config")

local M = {}

function M.parse(specs)
    local plugins = {}
    specs = M.flatten(specs)
    
    for _, spec in ipairs(specs) do
        local plugin = M.normalize(spec)
        if plugin then
            plugins[plugin.name] = plugin
        end
    end
    
    for name, plugin in pairs(plugins) do
        plugin.dependencies = plugin.dependencies or {}
        local deps = {}
        for _, dep in ipairs(plugin.dependencies) do
            local dep_name = type(dep) == "table" and dep[1] or dep
            local short_name = dep_name:match("^[^/]+/(.+)$") or dep_name
            if not plugins[short_name] then
                local dep_spec = type(dep) == "table" and dep or { dep }
                local parsed = M.normalize(dep_spec)
                if parsed then
                    plugins[parsed.name] = parsed
                    deps[#deps + 1] = parsed.name
                end
            else
                deps[#deps + 1] = short_name
            end
        end
        plugin.dependencies = deps
    end
    
    return plugins
end

function M.flatten(specs)
    local result = {}
    
    for _, spec in ipairs(specs) do
        if type(spec) == "table" then
            if spec.import then
                local imported = Config.import_spec(spec.import)
                vim.list_extend(result, M.flatten(imported))
            elseif spec[1] or spec.config or spec.opts then
                result[#result + 1] = spec
            end
        end
    end
    
    return result
end

function M.normalize(spec)
    if type(spec) == "string" then
        spec = { spec }
    end
    
    if type(spec) ~= "table" then
        return nil
    end
    
    if spec.import then
        return nil
    end
    
    local name = spec[1]
    if not name then return nil end
    
    local owner, repo, err = Util.split_plugin_name(name)
    if err then
        Util.error(err)
        return nil
    end
    
    return {
        name = repo,
        full_name = owner .. "/" .. repo,
        owner = owner,
        repo = repo,
        branch = spec.branch or Config.options.git.default_branch,
        commit = spec.commit,
        tag = spec.tag,
        version = spec.version,
        dependencies = spec.dependencies or {},
        dir = Util.plugin_dir(owner, repo),
        lazy = spec.lazy,
        priority = spec.priority,
        config = spec.config,
        opts = spec.opts,
        init = spec.init,
        event = spec.event,
        cmd = spec.cmd,
        keys = spec.keys,
        ft = spec.ft,
        enabled = spec.enabled,
    }
end

return M
