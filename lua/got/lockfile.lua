local Util = require("got.util")
local Config = require("got.config")

local M = {}

function M.read()
    local content = Util.read_file(Config.options.lockfile)
    if not content then
        return {}
    end
    local ok, data = pcall(vim.json.decode, content)
    if not ok then
        Util.warn("Failed to parse lockfile, starting fresh")
        return {}
    end
    return data
end

function M.write(data)
    local content = vim.json.encode(data, { indent = true })
    Util.write_file(Config.options.lockfile, content)
end

function M.get(plugin_name)
    local lock = M.read()
    return lock[plugin_name]
end

function M.set(plugin_name, info)
    local lock = M.read()
    lock[plugin_name] = {
        commit = info.commit,
        branch = info.branch,
        tag = info.tag,
        installed = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    M.write(lock)
end

function M.remove(plugin_name)
    local lock = M.read()
    lock[plugin_name] = nil
    M.write(lock)
end

return M
