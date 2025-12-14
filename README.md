# Celebrimbor

> **WIP**: This plugin is under active development. Features may change, bugs may appear, and your mileage may vary.

A Neovim plugin that brings Claude AI code generation directly into your editor workflow, powered by AWS Bedrock.

## The Legend

*"I made nothing alone. The Rings of Power were not created in solitude."* — Celebrimbor

In the depths of Eregion, the greatest elven smith of the Second Age labored at his forge. Celebrimbor crafted the Rings of Power—artifacts that could shape reality itself. He was deceived by Sauron, yes, but his craft was unmatched. The rings he forged without the Dark Lord's touch—the Three—remained pure and powerful.

*One does not simply write boilerplate.*

## Features

- **Ghost text suggestions** - AI-generated code appears as dimmed virtual text
- **Line-by-line acceptance** - Accept entire suggestions or one line at a time
- **Context-aware generation** - Uses Treesitter to understand function signatures, imports, types, and surrounding code
- **AWS Bedrock integration** - Leverages Claude via your existing AWS infrastructure

## Requirements

- Neovim 0.10+
- AWS CLI configured with Bedrock access
- nvim-treesitter 

## Installation

### lazy.nvim

```lua
{
  'amiraminb/celebrimbor',
  config = function()
    require('celebrimbor').setup()
  end,
}
```

## Configuration

Celebrimbor requires the following environment variables:

```bash
export AWS_PROFILE="your-aws-profile"
export AWS_REGION="us-west-2"
export CELEBRIMBOR_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
```

Optional:

```bash
export CELEBRIMBOR_MAX_TOKENS="5120"
export CELEBRIMBOR_AWS_CLI_PATH="/path/to/aws"  # Auto-detected if not set
```

### Custom Keymaps

```lua
require('celebrimbor').setup({
  keymaps = {
    trigger = '<C-g>',
    accept_all = '<Tab>',
    accept_line = '<C-l>',
    next_suggestion = '<C-]>',
    prev_suggestion = '<C-[>',
    dismiss = '<Esc>',
  },
})
```

## Usage

1. Write a function signature in a Go file
2. Position your cursor inside the empty function body
3. Press `<C-g>` to trigger code generation
4. Ghost text appears with the suggested implementation
5. Press `<Tab>` to accept all, `<C-l>` to accept line-by-line, or `<Esc>` to dismiss

## Commands

| Command | Description |
|---------|-------------|
| `:Celebrimbor` | Trigger code generation |
| `:CelerimborClear` | Clear current suggestion |
| `:CelerimborHealth` | Check plugin health |

## Health Check

Run `:checkhealth celebrimbor` to verify your setup.

