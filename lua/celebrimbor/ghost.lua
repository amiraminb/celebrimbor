local M = {}

M.ns = vim.api.nvim_create_namespace('celebrimbor_ghost')

M.state = {
  active = false,
  lines = {},
  accepted_count = 0,
  bufnr = nil,
  start_row = nil,
  extmark_id = nil,
  above = false,
  indent = '',
}

function M.clear()
  if M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
    vim.api.nvim_buf_clear_namespace(M.state.bufnr, M.ns, 0, -1)
  end

  M.state = {
    active = false,
    lines = {},
    accepted_count = 0,
    bufnr = nil,
    start_row = nil,
    extmark_id = nil,
    above = false,
    indent = '',
  }
end

function M.get_base_indent(row, above)
  local lines = vim.api.nvim_buf_get_lines(0, row, row + 2, false)
  local current_line = lines[1] or ''
  local next_line = lines[2] or ''

  local current_indent = current_line:match('^(%s*)') or ''

  if above then
    return current_indent
  end

  if current_line:match('{%s*$') then
    local next_indent = next_line:match('^(%s*)') or ''
    if #next_indent > #current_indent then
      return next_indent
    else
      return current_indent .. '\t'
    end
  end

  return current_indent
end

function M.show(text, opts)
  M.clear()

  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local row = opts.row or (vim.api.nvim_win_get_cursor(0)[1] - 1)
  local above = opts.above or false
  local index = opts.index
  local total = opts.total
  local base_indent = opts.indent or M.get_base_indent(row, above)

  local lines = vim.split(text, '\n', { plain = true })

  for i, line in ipairs(lines) do
    if line ~= '' then
      lines[i] = base_indent .. line
    end
  end

  while #lines > 0 and lines[#lines] == '' do
    table.remove(lines)
  end

  if #lines == 0 then
    vim.notify('Celebrimbor: No content to display', vim.log.levels.DEBUG)
    return
  end

  local virt_lines = {}

  if index and total and total > 1 and index < total then
    local indicator = string.format('[%d/%d]', index, total)
    table.insert(virt_lines, { { indicator, 'CelebrimborGhost' } })
  end

  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { line, 'CelebrimborGhost' } })
  end

  M.state.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.ns, row, 0, {
    virt_lines = virt_lines,
    virt_lines_above = above,
  })

  M.state.active = true
  M.state.lines = lines
  M.state.accepted_count = 0
  M.state.bufnr = bufnr
  M.state.start_row = row
  M.state.above = above
  M.state.indent = base_indent
end

function M.accept_all()
  if not M.state.active or #M.state.lines == 0 then
    return false
  end

  local bufnr = M.state.bufnr
  local insert_row = M.state.above and M.state.start_row or (M.state.start_row + 1)

  local remaining = {}
  for i = M.state.accepted_count + 1, #M.state.lines do
    table.insert(remaining, M.state.lines[i])
  end

  if #remaining > 0 then
    vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, remaining)
  end

  M.clear()
  return true
end

function M.accept_line()
  if not M.state.active or M.state.accepted_count >= #M.state.lines then
    M.clear()
    return false
  end

  local bufnr = M.state.bufnr
  local insert_row
  if M.state.above then
    insert_row = M.state.start_row + M.state.accepted_count
  else
    insert_row = M.state.start_row + 1 + M.state.accepted_count
  end

  local next_line = M.state.lines[M.state.accepted_count + 1]

  vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, { next_line })

  M.state.accepted_count = M.state.accepted_count + 1
  M.state.start_row = M.state.start_row + 1

  if M.state.accepted_count >= #M.state.lines then
    M.clear()
  else
    M.refresh_display()
  end

  return true
end

function M.refresh_display()
  if not M.state.active then
    return
  end

  local bufnr = M.state.bufnr

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

  local virt_lines = {}
  for i = M.state.accepted_count + 1, #M.state.lines do
    table.insert(virt_lines, { { M.state.lines[i], 'CelebrimborGhost' } })
  end

  if #virt_lines == 0 then
    M.clear()
    return
  end

  local row = M.state.start_row

  M.state.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M.ns, row, 0, {
    virt_lines = virt_lines,
    virt_lines_above = M.state.above,
  })
end

function M.is_active()
  return M.state.active
end

function M.remaining_count()
  return #M.state.lines - M.state.accepted_count
end

return M
