local M = {}

local function fetch_and_load(spec, install_root)
	local fetch = require("got.fetch")

	if spec.dependencies then
		for _, dep in ipairs(spec.dependencies) do
			local dep_repo = type(dep) == "string" and dep or dep[1]
			fetch_and_load({ dep_repo }, install_root)
		end
	end

	local repo = spec[1]
	local name = repo:gsub(".*/", "")
	local path = install_root .. "/" .. name

	if not vim.loop.fs_stat(path) then
		fetch.repo(repo, path)
	end

	vim.opt.rtp:append(path)
	local lua_path = path .. "/lua/?.lua;" .. path .. "/lua/?/init.lua;"
	package.path = lua_path .. package.path

	vim.cmd("packadd! " .. name)

	if spec.config then
		local ok, err = pcall(spec.config)
		if not ok then
			vim.api.nvim_err_writeln("❌ [got] Error in " .. name .. " config: " .. err)
		end
	end
end

function M.setup(opts)
	local install_root = vim.fn.stdpath("data") .. "/site/pack/got/start"
	vim.fn.mkdir(install_root, "p")

	opts = opts or {}
	local specs = {}

	if opts.spec then
		for _, item in ipairs(opts.spec) do
			if item.import then
				local config_path = vim.fn.stdpath("config") .. "/lua/" .. item.import:gsub("%.", "/")
				for _, file in ipairs(vim.fn.glob(config_path .. "/*.lua", true, true)) do
					local mod = item.import .. "." .. file:match("([^/]+)%.lua$")
					local plugin_spec = require(mod)
					table.insert(specs, plugin_spec)
				end
			else
				table.insert(specs, item)
			end
		end
	end

	for _, spec in ipairs(specs) do
		fetch_and_load(spec, install_root)
	end
end

return M
