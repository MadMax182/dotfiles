-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Remap movement keys for Dvorak users in Normal and Visual modes
-- This maps the physical keys that correspond to QWERTY's H, J, K, L
-- to their respective standard Vim motions.

-- h (left) -> 'd' on Dvorak
vim.keymap.set({"n", "v"}, "d", "h", { silent = true })
-- j (down) -> 'h' on Dvorak
vim.keymap.set({"n", "v"}, "h", "j", { silent = true })
-- k (up) -> 't' on Dvorak
vim.keymap.set({"n", "v"}, "t", "k", { silent = true })
-- l (right) -> 'n' on Dvorak
vim.keymap.set({"n", "v"}, "n", "l", { silent = true })
