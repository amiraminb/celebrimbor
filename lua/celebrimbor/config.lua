local M = {}

local REQUIRED_ENV = {
  'AWS_PROFILE',
  'AWS_REGION',
  'CELEBRIMBOR_MODEL',
}

local function find_aws_cli()
  local result = vim.system({ 'which', 'aws' }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    return vim.trim(result.stdout)
  end
  return 'aws'
end

M.defaults = {
  aws = {
    profile = nil,
    region = nil,
    cli_path = nil,
  },
  model = nil,
  max_tokens = tonumber(vim.env.CELEBRIMBOR_MAX_TOKENS) or 1024,
  keymaps = {
    trigger = '<leader>cg',
    accept_all = '<Tab>',
    accept_line = '<leader>cl',
    next_suggestion = '<leader>cn',
    prev_suggestion = '<leader>cp',
    dismiss = '<Esc>',
    set_context = '<leader>cs',
  },
}

M.options = {}

function M.validate_env()
  local missing = {}
  for _, var in ipairs(REQUIRED_ENV) do
    if not vim.env[var] or vim.env[var] == '' then
      table.insert(missing, var)
    end
  end
  return missing
end

function M.setup(opts)
  local missing = M.validate_env()
  if #missing > 0 then
    error('Celebrimbor: Missing required environment variables: ' .. table.concat(missing, ', '))
  end

  M.defaults.aws.profile = vim.env.AWS_PROFILE
  M.defaults.aws.region = vim.env.AWS_REGION
  M.defaults.aws.cli_path = vim.env.CELEBRIMBOR_AWS_CLI_PATH or find_aws_cli()
  M.defaults.model = vim.env.CELEBRIMBOR_MODEL

  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get(key)
  return M.options[key]
end

return M
