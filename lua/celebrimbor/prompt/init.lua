local generate = require('celebrimbor.prompt.generate')
local docstring = require('celebrimbor.prompt.docstring')
local inline = require('celebrimbor.prompt.inline')
local diagnostic = require('celebrimbor.prompt.diagnostic')

return {
  generate = generate,
  docstring = docstring,
  inline = inline,
  diagnostic = diagnostic,
}
