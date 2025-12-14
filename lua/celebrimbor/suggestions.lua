local M = {}

M.state = {
  items = {},
  index = 0,
  context = nil,
  opts = nil,
  type = nil,
}

function M.clear()
  M.state = {
    items = {},
    index = 0,
    context = nil,
    opts = nil,
    type = nil,
  }
end

function M.add(content, ctx, opts, suggestion_type)
  table.insert(M.state.items, content)
  M.state.index = #M.state.items
  M.state.context = ctx
  M.state.opts = opts
  M.state.type = suggestion_type or 'generate'
end

function M.current()
  if M.state.index == 0 or #M.state.items == 0 then
    return nil
  end
  return M.state.items[M.state.index]
end

function M.has_next()
  return M.state.index < #M.state.items
end

function M.has_prev()
  return M.state.index > 1
end

function M.next()
  if M.has_next() then
    M.state.index = M.state.index + 1
    return M.current(), false
  end
  return nil, true
end

function M.prev()
  if M.has_prev() then
    M.state.index = M.state.index - 1
    return M.current(), false
  end
  return nil, false
end

function M.get_context()
  return M.state.context
end

function M.get_opts()
  return M.state.opts
end

function M.get_type()
  return M.state.type
end

function M.count()
  return #M.state.items
end

function M.get_index()
  return M.state.index
end

function M.is_active()
  return #M.state.items > 0
end

return M
