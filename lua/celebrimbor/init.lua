local M = {}

local config = require('celebrimbor.config')
local bedrock = require('celebrimbor.bedrock')
local context = require('celebrimbor.context')
local prompt = require('celebrimbor.prompt')
local ghost = require('celebrimbor.ghost')
local spinner = require('celebrimbor.spinner')
local suggestions = require('celebrimbor.suggestions')

M.user_context = nil

function M.setup(opts)
  config.setup(opts)

  vim.env.AWS_PROFILE = config.options.aws.profile
  vim.env.AWS_REGION = config.options.aws.region

  vim.api.nvim_set_hl(0, 'CelebrimborGhost', {
    fg = '#6b7089',
    default = true,
  })

  M.setup_keymaps()

  vim.api.nvim_create_user_command('Celebrimbor', function()
    M.generate()
  end, { desc = 'Trigger Celebrimbor code generation' })

  vim.api.nvim_create_user_command('CelebrimborDocstring', function()
    M.generate_docstring()
  end, { desc = 'Generate docstring for function' })

  vim.api.nvim_create_user_command('CelerimborClear', function()
    M.clear()
  end, { desc = 'Clear Celebrimbor suggestion' })

  vim.api.nvim_create_user_command('CelebrimborHealth', function()
    vim.cmd('checkhealth celebrimbor')
  end, { desc = 'Check Celebrimbor health' })
end

function M.setup_keymaps()
  local keymaps = config.options.keymaps

  vim.keymap.set('n', keymaps.trigger, function()
    M.generate()
  end, { desc = 'Celebrimbor: Generate code' })

  vim.keymap.set('n', keymaps.accept_all, function()
    if ghost.is_active() then
      ghost.accept_all()
      suggestions.clear()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
    end
  end, { desc = 'Celebrimbor: Accept all' })

  vim.keymap.set('n', keymaps.accept_line, function()
    if ghost.is_active() then
      ghost.accept_line()
    end
  end, { desc = 'Celebrimbor: Accept line' })

  vim.keymap.set('n', keymaps.dismiss, function()
    if ghost.is_active() then
      ghost.clear()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
    end
  end, { desc = 'Celebrimbor: Dismiss' })

  vim.keymap.set('n', keymaps.next_suggestion, function()
    if ghost.is_active() then
      M.next_suggestion()
    end
  end, { desc = 'Celebrimbor: Next suggestion' })

  vim.keymap.set('n', keymaps.prev_suggestion, function()
    if ghost.is_active() then
      M.prev_suggestion()
    end
  end, { desc = 'Celebrimbor: Previous suggestion' })

  vim.keymap.set('n', keymaps.set_context, function()
    vim.ui.input({ prompt = 'Celebrimbor context: ', default = M.user_context or '' }, function(input)
      if input then
        M.user_context = input ~= '' and input or nil
        if M.user_context then
          vim.notify('Celebrimbor: Context set', vim.log.levels.INFO)
        else
          vim.notify('Celebrimbor: Context cleared', vim.log.levels.INFO)
        end
      end
    end)
  end, { desc = 'Celebrimbor: Set context' })

  vim.keymap.set('n', keymaps.docstring, function()
    M.generate_docstring()
  end, { desc = 'Celebrimbor: Generate docstring' })
end

function M.generate()
  local ctx, err = context.gather()
  if not ctx then
    vim.notify('Celebrimbor: ' .. (err or 'Could not gather context'), vim.log.levels.WARN)
    return
  end

  suggestions.clear()
  spinner.start()

  ctx.user_context = M.user_context
  local messages = prompt.generate.build_messages(ctx)

  bedrock.invoke_async(messages, {
    system = prompt.generate.system_prompt,
  }, function(result, api_err)
    spinner.stop()

    if api_err then
      vim.notify('Celebrimbor: ' .. tostring(api_err), vim.log.levels.ERROR)
      return
    end

    suggestions.add(result.content, ctx, { above = false }, 'generate')
    M.show_current_suggestion()
  end)
end

function M.show_current_suggestion()
  local content = suggestions.current()
  if not content then
    return
  end

  local opts = suggestions.get_opts() or {}
  opts.index = suggestions.get_index()
  opts.total = suggestions.count()

  ghost.show(content, opts)
end

function M.next_suggestion()
  if not suggestions.is_active() then
    return
  end

  local content, need_generate = suggestions.next()

  if need_generate then
    M.generate_alternative()
  elseif content then
    M.show_current_suggestion()
  end
end

function M.prev_suggestion()
  if not suggestions.is_active() then
    return
  end

  local content = suggestions.prev()
  if content then
    M.show_current_suggestion()
  end
end

function M.generate_alternative()
  local ctx = suggestions.get_context()
  if not ctx then
    return
  end

  spinner.start()

  local messages = prompt.generate.build_messages(ctx)
  table.insert(messages, {
    role = 'assistant',
    content = suggestions.current(),
  })
  table.insert(messages, {
    role = 'user',
    content = 'Generate a different implementation. Use a different approach or algorithm.',
  })

  bedrock.invoke_async(messages, {
    system = prompt.generate.system_prompt,
  }, function(result, api_err)
    spinner.stop()

    if api_err then
      vim.notify('Celebrimbor: ' .. tostring(api_err), vim.log.levels.ERROR)
      return
    end

    suggestions.add(result.content, ctx, suggestions.get_opts(), 'generate')
    M.show_current_suggestion()
  end)
end

function M.generate_docstring()
  local ctx, err = context.gather()
  if not ctx then
    vim.notify('Celebrimbor: ' .. (err or 'Could not gather context'), vim.log.levels.WARN)
    return
  end

  spinner.start()

  local messages = prompt.docstring.build_messages(ctx)

  bedrock.invoke_async(messages, {
    system = prompt.docstring.system_prompt,
  }, function(result, api_err)
    spinner.stop()

    if api_err then
      vim.notify('Celebrimbor: ' .. tostring(api_err), vim.log.levels.ERROR)
      return
    end

    local docstring = M.format_docstring(result.content)
    local func_row = ctx.func_node:start()

    ghost.show(docstring, { row = func_row, above = true })
  end)
end

function M.format_docstring(docstring)
  local lines = vim.split(docstring, '\n')

  local cleaned = {}
  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= '' then
      if not trimmed:match('^//') then
        trimmed = '// ' .. trimmed
      end
      table.insert(cleaned, trimmed)
    end
  end

  return table.concat(cleaned, '\n')
end

function M.clear()
  ghost.clear()
  suggestions.clear()
end

return M
