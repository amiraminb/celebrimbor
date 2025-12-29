local M = {}

M.system_prompt = [[You are an expert Go developer implementing code based on inline @ai instructions. You receive function context with a special @ai directive that describes what code should replace that comment line.

Output rules:
- Return ONLY raw Go code, nothing else
- NEVER wrap code in markdown code blocks (no ```go or ``` or any backticks)
- NO markdown formatting of any kind
- NO explanations, NO extra comments
- Match the indentation level of the surrounding code
- The code should integrate seamlessly with the existing function body
- Do NOT include the @ai comment in your output
- Do NOT repeat any existing code
- Start directly with the first line of Go code

Go patterns to follow:
- Handle errors immediately after they occur: if err != nil { return ..., err }
- Use early returns to reduce nesting
- Initialize variables close to their usage
- Use meaningful variable names (not single letters except for loops/receivers)
- Use context.Context as first parameter when passed
- Return zero values with errors: return nil, err or return "", err]]

local function add_section(parts, title, content)
  if content and content ~= '' then
    table.insert(parts, title .. ':')
    table.insert(parts, content)
    table.insert(parts, '')
  end
end

local function add_file_section(parts, title, files)
  if not files or #files == 0 then
    return
  end

  table.insert(parts, title .. ':')
  for _, f in ipairs(files) do
    table.insert(parts, string.format('--- %s ---', f.name))
    table.insert(parts, f.content)
    table.insert(parts, '')
  end
end

function M.build(ctx)
  local parts = {}

  table.insert(parts, string.format('Package: %s | File: %s', ctx.package_name or 'unknown', ctx.file_name))
  table.insert(parts, '')

  add_section(parts, 'Current file', ctx.current_file)

  add_file_section(parts, 'Harpoon files', ctx.harpoon_files)
  add_file_section(parts, 'Neighboring files', ctx.neighboring_files)
  add_file_section(parts, 'Imported local packages', ctx.imported_files)

  if ctx.type_definition then
    add_section(parts, 'Type definition', ctx.type_definition)
  end

  if ctx.other_functions and #ctx.other_functions > 0 then
    table.insert(parts, 'Other functions in file:')
    for _, sig in ipairs(ctx.other_functions) do
      table.insert(parts, sig)
    end
    table.insert(parts, '')
  end

  if ctx.comment then
    add_section(parts, 'Function documentation', ctx.comment)
  end

  table.insert(parts, 'Current function:')
  table.insert(parts, ctx.signature)
  table.insert(parts, '')

  if ctx.body_content then
    table.insert(parts, 'Current function body (contains @ai instruction to replace):')
    table.insert(parts, ctx.body_content)
    table.insert(parts, '')
  end

  table.insert(parts, '@ai instruction to implement:')
  table.insert(parts, ctx.ai_instruction)
  table.insert(parts, '')

  table.insert(parts, 'Generate ONLY the raw Go code that should replace the @ai comment line. No markdown, no ```go blocks, no backticks, just pure Go code:')

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
