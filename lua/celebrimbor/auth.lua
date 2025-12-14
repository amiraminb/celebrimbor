local M = {}

local config = require('celebrimbor.config')

M.cached_credentials = nil
M.cache_expiry = nil

function M.get_credentials()
  if M.cached_credentials and M.cache_expiry then
    local now = os.time()
    if now < (M.cache_expiry - 300) then
      return M.cached_credentials
    end
  end

  local profile = config.options.aws.profile
  local aws_cli = config.options.aws.cli_path

  local result = vim.system({
    aws_cli, 'configure', 'export-credentials',
    '--profile', profile,
  }, { text = true }):wait()

  if result.code ~= 0 then
    error('Failed to get AWS credentials. Run: aws sso login --profile ' .. profile)
  end

  local creds = vim.json.decode(result.stdout)

  M.cached_credentials = {
    access_key = creds.AccessKeyId,
    secret_key = creds.SecretAccessKey,
    session_token = creds.SessionToken,
  }

  if creds.Expiration then
    local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
    local y, m, d, h, min, s = creds.Expiration:match(pattern)
    if y then
      M.cache_expiry = os.time({
        year = y, month = m, day = d,
        hour = h, min = min, sec = s
      })
    end
  end

  return M.cached_credentials
end

function M.clear_cache()
  M.cached_credentials = nil
  M.cache_expiry = nil
end

return M
