local M = {}

local ts = require('celebrimbor.context.treesitter')
local file_ctx = require('celebrimbor.context.file')
local harpoon_ctx = require('celebrimbor.context.harpoon')
local neighbors_ctx = require('celebrimbor.context.neighbors')
local imports_ctx = require('celebrimbor.context.imports')

function M.get_imports()
  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local imports = {}
  for node in root:iter_children() do
    if node:type() == 'import_declaration' then
      table.insert(imports, vim.treesitter.get_node_text(node, bufnr))
    end
  end

  if #imports > 0 then
    return table.concat(imports, '\n')
  end
  return nil
end

function M.get_type_definition(type_name)
  if not type_name then
    return nil
  end

  type_name = type_name:gsub('^%*', '')

  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  for node in root:iter_children() do
    if node:type() == 'type_declaration' then
      local text = vim.treesitter.get_node_text(node, bufnr)
      if text:match('type%s+' .. type_name .. '%s') then
        return text
      end
    end
  end

  return nil
end

function M.get_other_functions(current_node)
  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return {}
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local functions = {}
  for node in root:iter_children() do
    local ntype = node:type()
    if (ntype == 'function_declaration' or ntype == 'method_declaration') then
      if current_node and node:id() == current_node:id() then
        goto continue
      end

      local text = vim.treesitter.get_node_text(node, bufnr)
      local brace_pos = text:find('{')
      if brace_pos then
        table.insert(functions, vim.trim(text:sub(1, brace_pos - 1)))
      end

      ::continue::
    end
  end

  return functions
end

function M.get_package_name()
  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  for node in root:iter_children() do
    if node:type() == 'package_clause' then
      local text = vim.treesitter.get_node_text(node, bufnr)
      return text:match('package%s+(%w+)')
    end
  end

  return nil
end

function M.gather()
  local func_ctx = ts.get_function_context()
  if not func_ctx then
    return nil, 'Cursor is not inside a function'
  end

  local file_path = vim.fn.expand('%:p')
  local file_name = vim.fn.expand('%:t')
  local prefix, suffix = file_ctx.get_prefix_suffix(func_ctx.node)

  return {
    signature = func_ctx.signature,
    is_empty = func_ctx.is_empty,
    body_content = func_ctx.body_content,
    comment = func_ctx.comment,
    is_method = func_ctx.is_method,
    receiver_type = func_ctx.receiver_type,

    file_path = file_path,
    file_name = file_name,
    package_name = M.get_package_name(),
    language = 'go',

    current_file = file_ctx.get_content(),
    prefix = prefix,
    suffix = suffix,

    imports = M.get_imports(),
    type_definition = func_ctx.receiver_type and M.get_type_definition(func_ctx.receiver_type),
    other_functions = M.get_other_functions(func_ctx.node),

    harpoon_files = harpoon_ctx.get_files(),
    neighboring_files = neighbors_ctx.get_files(),
    imported_files = imports_ctx.get_local_files(),

    func_node = func_ctx.node,
    body_node = func_ctx.body_node,
  }
end

return M
