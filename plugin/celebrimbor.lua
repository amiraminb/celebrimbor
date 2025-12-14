if vim.g.loaded_celebrimbor then
    return
end
vim.g.loaded_celebrimbor = true


if vim.fn.has('nvim-0.10') ~= 1 then
    vim.notify("Celebrimbor requires Neovim 0.10+", vim.log.levels.ERROR)
    return
end
