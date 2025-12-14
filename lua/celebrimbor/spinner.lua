local M = {}

M.ns = vim.api.nvim_create_namespace('celebrimbor_spinner')

M.state = {
  frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
  current = 1,
  timer = nil,
  bufnr = nil,
  row = nil,
  extmark_id = nil,
}

function M.start()
  M.stop()

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1

  M.state.bufnr = bufnr
  M.state.row = row
  M.state.current = 1

  local function update()
    if not M.state.timer then
      return
    end

    if not vim.api.nvim_buf_is_valid(M.state.bufnr) then
      M.stop()
      return
    end

    if M.state.extmark_id then
      pcall(vim.api.nvim_buf_del_extmark, M.state.bufnr, M.ns, M.state.extmark_id)
    end

    local frame = M.state.frames[M.state.current]
    M.state.extmark_id = vim.api.nvim_buf_set_extmark(M.state.bufnr, M.ns, M.state.row, 0, {
      virt_lines = { { { frame .. ' Generating...', 'CelebrimborGhost' } } },
      virt_lines_above = false,
    })

    M.state.current = M.state.current % #M.state.frames + 1
  end

  update()

  M.state.timer = vim.uv.new_timer()
  M.state.timer:start(0, 80, vim.schedule_wrap(update))
end

function M.stop()
  if M.state.timer then
    M.state.timer:stop()
    M.state.timer:close()
    M.state.timer = nil
  end

  if M.state.extmark_id and M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
    pcall(vim.api.nvim_buf_del_extmark, M.state.bufnr, M.ns, M.state.extmark_id)
    M.state.extmark_id = nil
  end
end

function M.is_active()
  return M.state.timer ~= nil
end

return M
