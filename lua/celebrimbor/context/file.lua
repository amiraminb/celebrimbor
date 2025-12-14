local M = {}

local MAX_FILE_LINES = 1000

function M.get_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if #lines > MAX_FILE_LINES then
    return table.concat(vim.list_slice(lines, 1, MAX_FILE_LINES), '\n') .. '\n... (truncated)'
  end
  return table.concat(lines, '\n')
end

function M.get_prefix_suffix(func_node)
  if not func_node then
    return nil, nil
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]

  local func_start = func_node:start()
  local func_end = func_node:end_()

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local prefix_lines = {}
  for i = func_start + 1, cursor_line do
    if lines[i] then
      table.insert(prefix_lines, lines[i])
    end
  end

  local suffix_lines = {}
  for i = cursor_line + 1, func_end + 1 do
    if lines[i] then
      table.insert(suffix_lines, lines[i])
    end
  end

  return table.concat(prefix_lines, '\n'), table.concat(suffix_lines, '\n')
end

function M.read(file_path, max_lines)
  max_lines = max_lines or MAX_FILE_LINES

  local file = io.open(file_path, 'r')
  if not file then
    return nil
  end

  local lines = {}
  local count = 0
  for line in file:lines() do
    count = count + 1
    if count > max_lines then
      table.insert(lines, '... (truncated)')
      break
    end
    table.insert(lines, line)
  end

  file:close()
  return table.concat(lines, '\n')
end

return M
