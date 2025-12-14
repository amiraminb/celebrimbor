local M = {}

local file = require('celebrimbor.context.file')

local MAX_FILES = 8

function M.get_files()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.expand('%:p:h')
  local current_name = vim.fn.expand('%:t:r')

  local files = {}
  local go_files = vim.fn.glob(current_dir .. '/*.go', false, true)

  local prioritized = {}
  local others = {}

  for _, file_path in ipairs(go_files) do
    if file_path ~= current_file then
      local name = vim.fn.fnamemodify(file_path, ':t:r')
      if name == current_name .. '_test' or name:match('^' .. current_name) then
        table.insert(prioritized, file_path)
      else
        table.insert(others, file_path)
      end
    end
  end

  for _, file_path in ipairs(prioritized) do
    if #files >= MAX_FILES then
      break
    end
    local content = file.read(file_path)
    if content then
      table.insert(files, {
        path = file_path,
        name = vim.fn.fnamemodify(file_path, ':t'),
        content = content,
      })
    end
  end

  for _, file_path in ipairs(others) do
    if #files >= MAX_FILES then
      break
    end
    local content = file.read(file_path)
    if content then
      table.insert(files, {
        path = file_path,
        name = vim.fn.fnamemodify(file_path, ':t'),
        content = content,
      })
    end
  end

  return files
end

return M
