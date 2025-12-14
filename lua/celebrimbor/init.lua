local M = {}

local config = require('celebrimbor.config')
local bedrock = require('celebrimbor.bedrock')
local context = require('celebrimbor.context')
local prompt = require('celebrimbor.prompt')
local ghost = require('celebrimbor.ghost')

function M.setup(opts)
    config.setup(opts)

    vim.env.AWS_PROFILE = config.options.aws.profile
    vim.env.AWS_REGION = config.options.aws.region

    vim.api.nvim_set_hl(0, 'CelebrimborGhost', {
        fg = '#6b7089',
        italic = false
    })

    M.setup_keymaps()

    vim.api.nvim_create_user_command('Celebrimbor', function()
        M.generate()
    end, { desc = 'Trigger Celebrimbor code generation' })

    vim.api.nvim_create_user_command('CelerimborClear', function()
      M.clear()
    end, { desc = 'Clear Celebrimbor suggestion' })

    vim.api.nvim_create_user_command('CelebrimborHealth', function()
        vim.cmd('checkhealth celebrimbor')
    end, { desc = 'Check Celebrimbor health' })
end

function M.setup_keymaps()
    local keymaps = config.options.keymaps

    -- Trigger generation
    vim.keymap.set('n', keymaps.trigger, function()
      M.generate()
    end, { desc = 'Celebrimbor: Generate code' })

    -- Accept all (only when ghost is active)
    vim.keymap.set('n', keymaps.accept_all, function()
      if ghost.is_active() then
        ghost.accept_all()
      else
        -- Fall back to default Tab behavior
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
      end
    end, { desc = 'Celebrimbor: Accept all' })

    -- Accept line
    vim.keymap.set('n', keymaps.accept_line, function()
      if ghost.is_active() then
        ghost.accept_line()
      end
    end, { desc = 'Celebrimbor: Accept line' })

    -- Dismiss
    vim.keymap.set('n', keymaps.dismiss, function()
      if ghost.is_active() then
        ghost.clear()
      else
        -- Fall back to default Esc behavior
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      end
    end, { desc = 'Celebrimbor: Dismiss' })
end

function M.generate()
    -- Gather context
    local ctx, err = context.gather()
    if not ctx then
      vim.notify('Celebrimbor: ' .. (err or 'Could not gather context'), vim.log.levels.WARN)
      return
    end

    -- Check if function body is empty
    if not ctx.is_empty then
      vim.notify('Celebrimbor: Function body is not empty', vim.log.levels.INFO)
      return
    end

    vim.notify('Celebrimbor: Generating...', vim.log.levels.INFO)

    -- Build prompt
    local messages = prompt.build_messages(ctx)

    -- Call Bedrock (this blocks - we'll make it async later if needed)
    local ok, result = pcall(function()
      return bedrock.invoke(messages, {
        system = prompt.get_system_prompt(),
      })
    end)

    if not ok then
      vim.notify('Celebrimbor: ' .. tostring(result), vim.log.levels.ERROR)
      return
    end

    -- Display as ghost text
    ghost.show(result.content)

    vim.notify(string.format('Celebrimbor: Generated %d lines (Tab=accept all, Ctrl-L=accept line, Esc=dismiss)',
      #vim.split(result.content, '\n')), vim.log.levels.INFO)
end

function M.clear()
    ghost.clear()
end

return M

