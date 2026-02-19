#!/bin/bash
# Test got.nvim in isolated environment

export NVIM_TEST_DIR="/home/jeff/got-test"

# Clean previous test
rm -rf "$NVIM_TEST_DIR/data"

# Run neovim with isolated config/data directories
NVIM_APP_NAME=got-test \
XDG_CONFIG_HOME="$NVIM_TEST_DIR" \
XDG_DATA_HOME="$NVIM_TEST_DIR/data" \
XDG_STATE_HOME="$NVIM_TEST_DIR/data" \
XDG_CACHE_HOME="$NVIM_TEST_DIR/data" \
nvim "$@"
