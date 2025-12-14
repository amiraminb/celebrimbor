local M = {}

function M.check()
  vim.health.start('Celebrimbor')

  if vim.fn.has('nvim-0.10') == 1 then
    vim.health.ok('Neovim 0.10+')
  else
    vim.health.error('Neovim 0.10+ required')
  end

  local aws_check = vim.fn.executable('aws')
  if aws_check == 1 then
    vim.health.ok('AWS CLI found')
  else
    vim.health.error('AWS CLI not found', { 'Install AWS CLI: https://aws.amazon.com/cli/' })
  end

  local config = require('celebrimbor.config')
  local aws_cli = config.options.aws and config.options.aws.cli_path or 'aws'
  local profile = config.options.aws and config.options.aws.profile or 'default'

  local result = vim.system({
    aws_cli, 'configure', 'export-credentials',
    '--profile', profile,
  }, { text = true }):wait()

  if result.code == 0 then
    vim.health.ok('AWS credentials available for profile: ' .. profile)
  else
    vim.health.warn('AWS credentials not available', {
      'Run: aws sso login --profile ' .. profile,
    })
  end

  local ts_ok = pcall(require, 'nvim-treesitter')
  if ts_ok then
    vim.health.ok('nvim-treesitter found')
  else
    vim.health.warn('nvim-treesitter not found', {
      'Treesitter improves context detection',
    })
  end
end

return M
