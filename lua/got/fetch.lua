local Util = require("got.util")
local Config = require("got.config")

local M = {}

local API_BASE = "https://api.github.com/repos"
local DOWNLOAD_BASE = "https://codeload.github.com"

function M.api_url(owner, repo, path)
    return string.format("%s/%s/%s%s", API_BASE, owner, repo, path or "")
end

function M.download_url(owner, repo, ref)
    return string.format("%s/%s/%s/tar.gz/%s", DOWNLOAD_BASE, owner, repo, ref)
end

function M.curl_get(url, headers)
    headers = headers or {}
    local cmd = { "curl", "-sL", "-H", "Accept: application/vnd.github+json" }
    for _, h in ipairs(headers) do
        cmd[#cmd + 1] = "-H"
        cmd[#cmd + 1] = h
    end
    cmd[#cmd + 1] = url
    
    local ok, result = Util.exec(cmd, { timeout = Config.options.git.timeout * 1000 })
    if not ok then
        return nil, result
    end
    return result, nil
end

function M.get_repo_info(owner, repo)
    local url = M.api_url(owner, repo)
    local resp, err = M.curl_get(url)
    if err then
        return nil, err
    end
    
    local ok, data = pcall(vim.json.decode, resp)
    if not ok or type(data) ~= "table" then
        return nil, "failed to parse repo info"
    end
    
    return data, nil
end

function M.get_default_branch(owner, repo)
    local info, err = M.get_repo_info(owner, repo)
    if err then
        return nil, err
    end
    return info.default_branch, nil
end

function M.get_commits(owner, repo, branch)
    local url = M.api_url(owner, repo, string.format("/commits?sha=%s&per_page=1", branch))
    Util.debug("GET " .. url)
    
    local resp, err = M.curl_get(url)
    if err then
        return nil, err
    end
    
    local ok, data = pcall(vim.json.decode, resp)
    if not ok or type(data) ~= "table" then
        if type(data) == "table" and data.message then
            return nil, data.message
        end
        return nil, "failed to parse commits response"
    end
    
    if #data == 0 then
        return nil, "no commits found"
    end
    
    return data[1].sha, nil
end

function M.get_tags(owner, repo)
    local url = M.api_url(owner, repo, "/tags?per_page=100")
    Util.debug("GET " .. url)
    
    local resp, err = M.curl_get(url)
    if err then
        return nil, err
    end
    
    local ok, data = pcall(vim.json.decode, resp)
    if not ok then
        return nil, "failed to parse tags response"
    end
    
    return data, nil
end

function M.resolve_ref(owner, repo, branch, tag, commit)
    if commit then
        return commit, nil
    end
    
    if tag then
        local tags, err = M.get_tags(owner, repo)
        if err then
            return nil, "failed to fetch tags: " .. err
        end
        for _, t in ipairs(tags) do
            if t.name == tag then
                return t.commit.sha, nil
            end
        end
        return nil, "tag not found: " .. tag
    end
    
    local sha, err = M.get_commits(owner, repo, branch)
    if sha then
        return sha, nil
    end
    
    if branch == "main" then
        Util.debug("main branch failed, trying master")
        return M.get_commits(owner, repo, "master")
    elseif branch == "master" then
        Util.debug("master branch failed, trying main")
        return M.get_commits(owner, repo, "main")
    end
    
    return nil, err
end

function M.download(owner, repo, ref, dest_dir)
    local url = M.download_url(owner, repo, ref)
    Util.debug("Downloading " .. url .. " to " .. dest_dir)
    
    Util.mkdir(dest_dir)
    
    local cmd = string.format(
        "curl -sL %s | tar -xzf - -C %s --strip-components=1 2>&1",
        Util.shellescape(url),
        Util.shellescape(dest_dir)
    )
    
    local result = vim.system({ "sh", "-c", cmd }, { timeout = Config.options.git.timeout * 1000 }):wait()
    
    if result.code ~= 0 then
        Util.rmrf(dest_dir)
        return false, result.stderr or "download/extract failed"
    end
    
    return true, nil
end

return M
