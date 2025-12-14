local M = {}

local file = require('celebrimbor.context.file')

local MAX_FILES = 6

function M.get_files()
  local ok, harpoon = pcall(require, 'harpoon')
  if not ok then
    return {}
  end

  local files = {}
  local current_file = vim.fn.expand('%:p')

  local list_ok, list = pcall(function()
    return harpoon:list()
  end)

  if not list_ok or not list then
    return {}
  end

  local items = list.items or {}
  for i, item in ipairs(items) do
    if i > MAX_FILES then
      break
    end

    local file_path = item.value
    if file_path and file_path ~= '' then
      if not file_path:match('^/') then
        file_path = vim.fn.getcwd() .. '/' .. file_path
      end

      if file_path ~= current_file and vim.fn.filereadable(file_path) == 1 then
        local content = file.read(file_path)
        if content then
          table.insert(files, {
            path = file_path,
            name = vim.fn.fnamemodify(file_path, ':t'),
            content = content,
          })
        end
      end
    end
  end

  return files
end

return M
