local M = {}

function M.sort(plugins)
    local visited = {}
    local sorted = {}
    local temp = {}
    
    local function visit(name)
        if temp[name] then
            return false, "circular dependency detected: " .. name
        end
        if visited[name] then
            return true, nil
        end
        
        temp[name] = true
        
        local plugin = plugins[name]
        if plugin and plugin.dependencies then
            for _, dep in ipairs(plugin.dependencies) do
                local ok, err = visit(dep)
                if not ok then
                    return false, err
                end
            end
        end
        
        temp[name] = false
        visited[name] = true
        sorted[#sorted + 1] = name
        
        return true, nil
    end
    
    for name, _ in pairs(plugins) do
        if not visited[name] then
            local ok, err = visit(name)
            if not ok then
                return nil, err
            end
        end
    end
    
    return sorted, nil
end

return M
