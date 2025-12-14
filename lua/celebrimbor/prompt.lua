local M = {}

M.system_prompt = [[You are an expert Go developer implementing function bodies. You receive a function signature and context, and return ONLY the implementation code.

Output rules:
- Return ONLY the code that goes inside the function braces
- NO markdown, NO explanations, NO comments unless essential
- NO function signature, NO opening/closing braces
- Start directly with the first line of implementation
- If existing code is provided, return ONLY the NEW code to add (continuation)
- Do NOT repeat existing code

Go patterns to follow:
- Handle errors immediately after they occur: if err != nil { return ..., err }
- Use early returns to reduce nesting
- Initialize variables close to their usage
- Use meaningful variable names (not single letters except for loops/receivers)
- Prefer table-driven tests patterns when applicable
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
    add_section(parts, 'Documentation', ctx.comment)
  end

  if ctx.user_context then
    add_section(parts, 'Ultimate Goal', ctx.user_context)
  end

  if ctx.body_content then
    table.insert(parts, 'Complete this function (continue from existing code):')
    table.insert(parts, ctx.signature)
    table.insert(parts, '')
    table.insert(parts, 'Existing code in function body:')
    table.insert(parts, ctx.body_content)
    table.insert(parts, '')
    table.insert(parts, 'Continue implementation from here (do NOT repeat existing code):')
  else
    table.insert(parts, 'Implement this function:')
    table.insert(parts, ctx.signature)
  end

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
