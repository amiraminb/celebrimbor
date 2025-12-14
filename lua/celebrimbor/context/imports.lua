local M = {}

local file = require('celebrimbor.context.file')

local MAX_FILES = 5

function M.parse_paths()
  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    return {}
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local paths = {}
  for node in root:iter_children() do
    if node:type() == 'import_declaration' then
      for child in node:iter_children() do
        if child:type() == 'import_spec_list' then
          for spec in child:iter_children() do
            if spec:type() == 'import_spec' then
              local path_node = spec:field('path')[1]
              if path_node then
                local path = vim.treesitter.get_node_text(path_node, bufnr)
                path = path:gsub('^"', ''):gsub('"$', '')
                table.insert(paths, path)
              end
            end
          end
        elseif child:type() == 'import_spec' then
          local path_node = child:field('path')[1]
          if path_node then
            local path = vim.treesitter.get_node_text(path_node, bufnr)
            path = path:gsub('^"', ''):gsub('"$', '')
            table.insert(paths, path)
          end
        end
      end
    end
  end

  return paths
end

function M.find_module_root()
  local current = vim.fn.expand('%:p:h')
  while current ~= '/' do
    if vim.fn.filereadable(current .. '/go.mod') == 1 then
      return current
    end
    current = vim.fn.fnamemodify(current, ':h')
  end
  return nil
end

function M.get_module_name(root)
  local go_mod = root .. '/go.mod'
  if vim.fn.filereadable(go_mod) ~= 1 then
    return nil
  end

  local f = io.open(go_mod, 'r')
  if not f then
    return nil
  end

  local first_line = f:read('*l')
  f:close()

  if first_line then
    return first_line:match('^module%s+(.+)$')
  end
  return nil
end

function M.get_local_files()
  local import_paths = M.parse_paths()
  local project_root = M.find_module_root()
  if not project_root then
    return {}
  end

  local module_name = M.get_module_name(project_root)
  if not module_name then
    return {}
  end

  local files = {}
  for _, import_path in ipairs(import_paths) do
    if #files >= MAX_FILES then
      break
    end

    if import_path:match('^' .. vim.pesc(module_name)) then
      local relative_path = import_path:gsub('^' .. vim.pesc(module_name) .. '/?', '')
      local pkg_dir = project_root .. '/' .. relative_path

      if vim.fn.isdirectory(pkg_dir) == 1 then
        local go_files = vim.fn.glob(pkg_dir .. '/*.go', false, true)
        for _, file_path in ipairs(go_files) do
          if #files >= MAX_FILES then
            break
          end
          if not file_path:match('_test%.go$') then
            local content = file.read(file_path)
            if content then
              table.insert(files, {
                path = file_path,
                name = vim.fn.fnamemodify(file_path, ':t'),
                package = import_path,
                content = content,
              })
            end
          end
        end
      end
    end
  end

  return files
end

return M
