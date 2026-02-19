vim.api.nvim_create_user_command("GotInstall", function()
    require("got").install()
end, { desc = "Install missing plugins" })

vim.api.nvim_create_user_command("GotUpdate", function(opts)
    require("got").update(opts.args ~= "" and opts.args or nil)
end, { 
    desc = "Update all or specific plugin",
    nargs = "?",
    complete = function()
        local plugins = require("got.config").plugins
        return vim.tbl_keys(plugins)
    end,
})

vim.api.nvim_create_user_command("GotSync", function()
    require("got").sync()
end, { desc = "Sync plugins (install missing, remove unused)" })

vim.api.nvim_create_user_command("GotClean", function()
    require("got").clean()
end, { desc = "Remove unused plugins" })

vim.api.nvim_create_user_command("GotList", function()
    require("got").list()
end, { desc = "List installed plugins" })
