local M = {}

function M.repo(repo, plugin_path)
	local name = repo:gsub(".*/", "")
	print("🚚 [got] fetching " .. name .. "...")

	local tmp_zip = "/tmp/" .. name .. ".zip"
	local tmp_dir = "/tmp/" .. name .. "_extract"

	vim.fn.system({ "curl", "-L", "https://github.com/" .. repo .. "/archive/refs/heads/main.zip", "-o", tmp_zip })
	vim.fn.system({ "unzip", "-q", tmp_zip, "-d", tmp_dir })

	local internal = vim.fn.glob(tmp_dir .. "/*")
	vim.fn.system({ "mkdir", "-p", plugin_path })
	vim.fn.system({ "mv", internal, plugin_path })
	vim.fn.system({ "rm", "-rf", tmp_zip, tmp_dir })

	print("🚚 [got] finished operation for " .. name .. ".")
end

return M
