local M = {}

local FUNCTION_TYPES = {
  'function_declaration',
  'method_declaration',
}

function M.get_enclosing_function()
  local node = vim.treesitter.get_node()
  if not node then
    return nil
  end

  -- First, try traversing up from current node
  local current = node
  while current do
    local node_type = current:type()
    for _, func_type in ipairs(FUNCTION_TYPES) do
      if node_type == func_type then
        return current
      end
    end
    current = current:parent()
  end

  -- If not found, check if cursor is within any function's range
  -- This handles edge cases like cursor on closing brace
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1 -- 0-indexed
  local cursor_col = cursor[2]

  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  for child in root:iter_children() do
    local child_type = child:type()
    for _, func_type in ipairs(FUNCTION_TYPES) do
      if child_type == func_type then
        local start_row, start_col, end_row, end_col = child:range()
        -- Check if cursor is within function range (inclusive of end)
        if cursor_row >= start_row and cursor_row <= end_row then
          if cursor_row == start_row and cursor_col < start_col then
            goto continue
          end
          if cursor_row == end_row and cursor_col > end_col then
            goto continue
          end
          return child
        end
      end
    end
    ::continue::
  end

  return nil
end

function M.get_function_signature(func_node)
  if not func_node then
    return nil
  end

  local text = vim.treesitter.get_node_text(func_node, 0)
  local brace_pos = text:find('{')
  if brace_pos then
    return vim.trim(text:sub(1, brace_pos - 1))
  end

  return text
end

function M.get_function_body(func_node)
  if not func_node then
    return nil
  end

  for child in func_node:iter_children() do
    if child:type() == 'block' then
      return child
    end
  end

  return nil
end

function M.is_body_empty(body_node)
  if not body_node then
    return true
  end

  local text = vim.treesitter.get_node_text(body_node, 0)
  local inner = text:gsub('^%s*{', ''):gsub('}%s*$', '')
  return vim.trim(inner) == ''
end

function M.get_body_content(body_node)
  if not body_node then
    return nil
  end

  local text = vim.treesitter.get_node_text(body_node, 0)
  local inner = text:gsub('^%s*{\n?', ''):gsub('\n?%s*}%s*$', '')
  local trimmed = vim.trim(inner)
  if trimmed == '' then
    return nil
  end
  return inner
end

function M.get_preceding_comment(func_node)
  if not func_node then
    return nil
  end

  local prev = func_node:prev_sibling()
  if prev and prev:type() == 'comment' then
    return vim.treesitter.get_node_text(prev, 0)
  end

  return nil
end

function M.get_receiver_type(func_node)
  if not func_node or func_node:type() ~= 'method_declaration' then
    return nil
  end

  for child in func_node:iter_children() do
    if child:type() == 'parameter_list' then
      local receiver_text = vim.treesitter.get_node_text(child, 0)
      local type_match = receiver_text:match('%s+(%*?%w+)%s*%)')
      return type_match
    end
  end

  return nil
end

function M.get_function_context()
  local func_node = M.get_enclosing_function()
  if not func_node then
    return nil
  end

  local body = M.get_function_body(func_node)

  return {
    signature = M.get_function_signature(func_node),
    is_empty = M.is_body_empty(body),
    body_content = M.get_body_content(body),
    comment = M.get_preceding_comment(func_node),
    receiver_type = M.get_receiver_type(func_node),
    is_method = func_node:type() == 'method_declaration',
    node = func_node,
    body_node = body,
  }
end

return M
