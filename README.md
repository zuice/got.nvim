# got.nvim

A minimal Neovim plugin manager that uses only GitHub GET requests. Drop-in replacement for lazy.nvim with a simpler implementation.

## Why?

If you're behind a corporate firewall that blocks POST requests to GitHub's API, got.nvim works where lazy.nvim doesn't.

## Installation

### One-liner

```bash
curl -sSL https://raw.githubusercontent.com/zuice/got.nvim/main/install.sh | bash
```

### Bootstrap (add to init.lua)

```lua
local got_path = vim.fn.stdpath("data") .. "/got/got.nvim"
if not vim.loop.fs_stat(got_path) then
    vim.fn.system({
        "git", "clone", "--depth", "1",
        "https://github.com/zuice/got.nvim.git",
        got_path,
    })
end
vim.opt.rtp:prepend(got_path)

require("got").setup("plugins")
```

## Usage

Drop-in replacement for lazy.nvim:

```lua
require("got").setup("plugins")
```

Or with options:

```lua
require("got").setup({
    spec = "plugins",
    debug = false,
})
```

## Plugin Spec

Compatible with lazy.nvim format:

```lua
-- Simple
return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme tokyonight]])
    end,
}

-- With dependencies
return {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.0",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("telescope").setup({})
    end,
}

-- Pin to commit
return {
    "neovim/nvim-lspconfig",
    commit = "abc1234",
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:GotInstall` | Install missing plugins |
| `:GotUpdate [name]` | Update all or specific plugin |
| `:GotSync` | Install missing + clean unused |
| `:GotClean` | Remove plugins not in spec |
| `:GotList` | Show plugin status |

## How it Works

- Uses GitHub API GET requests to check for updates
- Downloads tarballs from `codeload.github.com` (GET only)
- Stores commit SHAs in `got-lock.json` for reproducibility
- Resolves dependencies with topological sort

## Differences from lazy.nvim

- Simpler implementation (single-purpose)
- Only GET requests (no GitHub POST API calls)
- No UI window (uses notifications)
- Core features only: install, update, clean, deps

## Testing

Test in an isolated environment without affecting your setup:

```bash
git clone https://github.com/zuice/got.nvim.git
cd got.nvim/test
./run.sh
```

This runs neovim with isolated config/data directories.

## License

MIT
