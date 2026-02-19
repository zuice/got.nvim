local M = {}

M.root = debug.getinfo(1, "S").source:sub(2):gsub("/lua/got/util.lua$", "")

function M.norm(path)
    return vim.fs.normalize(path)
end

function M.join(...)
    return M.norm(table.concat({...}, "/"))
end

function M.log(msg, level)
    level = level or vim.log.levels.INFO
    vim.notify(msg, level, { title = "got.nvim" })
end

function M.debug(msg)
    if require("got.config").options.debug then
        M.log("[DEBUG] " .. msg, vim.log.levels.DEBUG)
    end
end

function M.error(msg)
    M.log(msg, vim.log.levels.ERROR)
end

function M.warn(msg)
    M.log(msg, vim.log.levels.WARN)
end

function M.shellescape(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

function M.exists(path)
    return vim.uv.fs_stat(path) ~= nil
end

function M.mkdir(path)
    vim.fn.mkdir(path, "p")
end

function M.rmrf(path)
    if M.exists(path) then
        vim.fn.delete(path, "rf")
    end
end

function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

function M.write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function M.exec(cmd, opts)
    opts = opts or {}
    local result = vim.system(cmd, { timeout = opts.timeout or 60000 }):wait()
    if result.code ~= 0 then
        return false, result.stderr or "command failed"
    end
    return true, result.stdout
end

function M.split_plugin_name(spec)
    local name = type(spec) == "table" and spec[1] or spec
    local owner, repo = name:match("^([^/]+)/(.+)$")
    if not owner then
        return nil, nil, "invalid plugin format: " .. name
    end
    return owner, repo, nil
end

function M.plugin_dir(owner, repo)
    local config = require("got.config")
    return M.join(config.options.root, repo)
end

return M
