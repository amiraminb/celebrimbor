local M = {}

M.system_prompt = [[You are an expert Go developer. Your task is to implement function bodies based on the signature and context provided.

Rules:
- Return ONLY the function body code (the content that goes inside the braces)
- Do NOT include the function signature or braces
- Do NOT include markdown code fences or explanations
- Match the coding style of the surrounding code
- Use proper error handling patterns
- Keep implementations concise but complete]]

function M.build(ctx)
  local parts = {}

  table.insert(parts, string.format('File: %s', ctx.file_name))
  table.insert(parts, string.format('Package: %s', ctx.package_name or 'unknown'))
  table.insert(parts, '')

  if ctx.imports then
    table.insert(parts, '// Available imports:')
    table.insert(parts, ctx.imports)
    table.insert(parts, '')
  end

  if ctx.type_definition then
    table.insert(parts, '// Receiver type:')
    table.insert(parts, ctx.type_definition)
    table.insert(parts, '')
  end

  if ctx.other_functions and #ctx.other_functions > 0 then
    table.insert(parts, '// Other functions in this file:')
    for _, sig in ipairs(ctx.other_functions) do
      table.insert(parts, '// ' .. sig)
    end
    table.insert(parts, '')
  end

  if ctx.comment then
    table.insert(parts, '// Documentation:')
    table.insert(parts, ctx.comment)
    table.insert(parts, '')
  end

  table.insert(parts, '// Implement this function:')
  table.insert(parts, ctx.signature .. ' {')
  table.insert(parts, '  // YOUR IMPLEMENTATION HERE')
  table.insert(parts, '}')

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

function M.get_system_prompt()
  return M.system_prompt
end

return M
