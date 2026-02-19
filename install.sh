#!/bin/bash
# got.nvim installer
# Usage: curl -sSL https://raw.githubusercontent.com/zuice/got.nvim/main/install.sh | bash

set -e

GOT_PATH="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/got/got.nvim

echo "Installing got.nvim to $GOT_PATH..."

if [ -d "$GOT_PATH" ]; then
    echo "got.nvim already installed. Updating..."
    cd "$GOT_PATH"
    git pull origin main
else
    git clone --depth 1 https://github.com/zuice/got.nvim.git "$GOT_PATH"
fi

echo ""
echo "got.nvim installed!"
echo ""
echo "Add this to your init.lua:"
echo ""
echo "-- Bootstrap got.nvim"
echo 'local got_path = vim.fn.stdpath("data") .. "/got/got.nvim"'
echo 'if not vim.loop.fs_stat(got_path) then'
echo '    vim.fn.system({ "git", "clone", "--depth", "1", "https://github.com/zuice/got.nvim.git", got_path })'
echo 'end'
echo 'vim.opt.rtp:prepend(got_path)'
echo ''
echo 'require("got").setup("plugins")'
echo ""
