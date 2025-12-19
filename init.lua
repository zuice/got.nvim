local fetch = require("got.nvim.fetch")

local M = {}

function M.setup(opts)
	local install_root = vim.fn.stdpath("data") .. "/site/pack/got/start"
	opts = opts or {}

	local specs = {}
	if opts.spec then
		for _, item in ipairs(opts.spec) do
			if item.import then
				local config_path = vim.fn.stdpath("config") .. "/lua/" .. item.import:gsub("%.", "/")
				for _, file in ipairs(vim.fn.glob(config_path .. "/*.lua", true, true)) do
					local mod = item.import .. "." .. file:match("([^/]+)%.lua$")
					table.insert(specs, require(mod))
				end
			else
				table.insert(specs, item)
			end
		end
	end

	for _, spec in ipairs(specs) do
		local repo = spec[1]
		local name = repo:gsub(".*/", "")
		local path = install_root .. "/" .. name

		if not vim.loop.fs_stat(path) then
			fetch(repo, path)
		end

		if spec.config then
			spec.config()
		end
	end
end

return M
