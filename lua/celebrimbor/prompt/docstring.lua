local M = {}

M.system_prompt = [[You are an expert Go developer writing documentation comments.

Output rules:
- Return ONLY the Go doc comment (lines starting with //)
- Follow Go documentation conventions
- Start with the function/method name
- Be concise but informative
- NO markdown, NO code blocks
- Do NOT include the function signature]]

function M.build(ctx)
  local parts = {}

  table.insert(parts, string.format('Package: %s', ctx.package_name or 'unknown'))
  table.insert(parts, '')

  table.insert(parts, 'Function signature:')
  table.insert(parts, ctx.signature)
  table.insert(parts, '')

  if ctx.body_content then
    table.insert(parts, 'Function implementation:')
    table.insert(parts, ctx.body_content)
    table.insert(parts, '')
  end

  if ctx.type_definition then
    table.insert(parts, 'Type definition:')
    table.insert(parts, ctx.type_definition)
    table.insert(parts, '')
  end

  table.insert(parts, 'Generate a Go doc comment for this function:')

  return table.concat(parts, '\n')
end

function M.build_messages(ctx)
  return {
    {
      role = 'user',
      content = M.build(ctx),
    },
  }
end

return M
