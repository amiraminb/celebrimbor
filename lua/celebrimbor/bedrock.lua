local M = {}

local config = require('celebrimbor.config')
local auth = require('celebrimbor.auth')

function M.invoke(messages, opts)
  opts = opts or {}

  auth.get_credentials()

  local aws_cli = config.options.aws.cli_path
  local profile = config.options.aws.profile
  local region = config.options.aws.region
  local model = opts.model or config.options.model
  local max_tokens = opts.max_tokens or config.options.max_tokens

  local request = {
    anthropic_version = 'bedrock-2023-05-31',
    max_tokens = max_tokens,
    messages = messages,
  }

  if opts.system then
    request.system = opts.system
  end

  local body = vim.json.encode(request)
  local tmpfile = os.tmpname()

  local result = vim.system({
    aws_cli, 'bedrock-runtime', 'invoke-model',
    '--model-id', model,
    '--body', body,
    '--profile', profile,
    '--region', region,
    '--cli-binary-format', 'raw-in-base64-out',
    tmpfile,
  }, { text = true }):wait()

  if result.code ~= 0 then
    os.remove(tmpfile)
    error('Bedrock API error: ' .. (result.stderr or 'unknown error'))
  end

  local file = io.open(tmpfile, 'r')
  if not file then
    os.remove(tmpfile)
    error('Failed to read Bedrock response')
  end

  local response_text = file:read('*a')
  file:close()
  os.remove(tmpfile)

  local response = vim.json.decode(response_text)

  return {
    content = response.content[1].text,
    usage = {
      input_tokens = response.usage.input_tokens,
      output_tokens = response.usage.output_tokens,
    },
    stop_reason = response.stop_reason,
  }
end

function M.complete(prompt, opts)
  local messages = {
    { role = 'user', content = prompt }
  }
  return M.invoke(messages, opts)
end

return M
