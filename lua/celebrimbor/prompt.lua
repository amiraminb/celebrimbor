local M = {}

M.system_prompt = [[You are an expert Go developer implementing function bodies. You receive a function signature and context, and return ONLY the implementation code.

Output rules:
- Return ONLY the code that goes inside the function braces
- NO markdown, NO explanations, NO comments unless essential
- NO function signature, NO opening/closing braces
- Start directly with the first line of implementation

Go patterns to follow:
- Handle errors immediately after they occur: if err != nil { return ..., err }
- Use early returns to reduce nesting
- Initialize variables close to their usage
- Use meaningful variable names (not single letters except for loops/receivers)
- Prefer table-driven tests patterns when applicable
- Use context.Context as first parameter when passed
- Return zero values with errors: return nil, err or return "", err]]

function M.build(ctx)
  local parts = {}

  table.insert(parts, string.format('Package: %s | File: %s', ctx.package_name or 'unknown', ctx.file_name))
  table.insert(parts, '')

  if ctx.imports then
    table.insert(parts, 'Imports:')
    table.insert(parts, ctx.imports)
    table.insert(parts, '')
  end

  if ctx.type_definition then
    table.insert(parts, 'Type definition:')
    table.insert(parts, ctx.type_definition)
    table.insert(parts, '')
  end

  if ctx.other_functions and #ctx.other_functions > 0 then
    table.insert(parts, 'Related functions:')
    for _, sig in ipairs(ctx.other_functions) do
      table.insert(parts, sig)
    end
    table.insert(parts, '')
  end

  if ctx.comment then
    table.insert(parts, 'Documentation:')
    table.insert(parts, ctx.comment)
    table.insert(parts, '')
  end

  if ctx.user_context then
    table.insert(parts, 'Ultimate Goal (not for this function but in general):')
    table.insert(parts, ctx.user_context)
    table.insert(parts, '')
  end

  table.insert(parts, 'Implement:')
  table.insert(parts, ctx.signature)

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
