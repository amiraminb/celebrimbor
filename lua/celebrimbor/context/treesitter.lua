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

  while node do
    local node_type = node:type()
    for _, func_type in ipairs(FUNCTION_TYPES) do
      if node_type == func_type then
        return node
      end
    end
    node = node:parent()
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
