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
- **Rich context gathering** - Current file, harpoon files, neighboring files, imported local packages
- **Partial function support** - Continue implementing functions with existing code
- **Docstring generation** - Generate Go doc comments for functions
- **Inline @ai generation** - Write `// @ai your instruction` and generate code to replace it
- **Diagnostic fix** - Fix LSP errors/warnings on the current line with AI
- **Multiple suggestions** - Cycle through alternative implementations
- **AWS Bedrock integration** - Leverages Claude via your existing AWS infrastructure

## Requirements

- Neovim 0.10+
- AWS CLI configured with Bedrock access
- nvim-treesitter
- harpoon (optional, for marked files context) 

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
export CELEBRIMBOR_MAX_TOKENS="1024"
export CELEBRIMBOR_AWS_CLI_PATH="/path/to/aws"  # Auto-detected if not set
```

### Custom Keymaps

```lua
require('celebrimbor').setup({
  keymaps = {
    trigger = '<leader>cg',
    accept_all = '<Tab>',
    accept_line = '<leader>cl',
    next_suggestion = '<leader>cn',
    prev_suggestion = '<leader>cp',
    dismiss = '<Esc>',
    docstring = '<leader>cd',
    inline = '<leader>ci',
    fix = '<leader>cf',
  },
})
```

## Usage

### Code Generation

1. Write a function signature in a Go file
2. Position your cursor inside the function body (empty or partial)
3. Press `<leader>cg` to trigger code generation
4. Ghost text appears with the suggested implementation
5. Press `<Tab>` to accept all, `<leader>cl` to accept line-by-line, or `<Esc>` to dismiss

### Inline @ai Generation

1. Write a comment with `@ai` followed by your instruction:
   ```go
   func fetchUser(id string) (*User, error) {
       // @ai fetch user from database by id and handle errors
   }
   ```
2. Position your cursor on the `@ai` line
3. Press `<leader>ci` to generate code
4. The generated code replaces the `@ai` comment line

### Diagnostic Fix

1. Position your cursor on a line with LSP diagnostics (errors/warnings)
2. Press `<leader>cf` to generate a fix
3. The AI analyzes the diagnostic messages and generates fixed code
4. The suggestion replaces the problematic line

## Commands

| Command | Description |
|---------|-------------|
| `:Celebrimbor` | Trigger code generation |
| `:CelebrimborDocstring` | Generate docstring for function |
| `:CelebrimborInline` | Generate code from @ai instruction |
| `:CelebrimborFix` | Fix diagnostic on current line |
| `:CelerimborClear` | Clear current suggestion |
| `:CelebrimborHealth` | Check plugin health |

## Health Check

Run `:checkhealth celebrimbor` to verify your setup.

## Roadmap

### Core Features
- [ ] Auto-suggest on typing pause (Copilot-style, opt-in)
- [ ] Embeddings for relevance ranking (smarter context selection)
- [ ] Smarter multiple suggestions

### Future Vision
- [ ] LSP server - Standalone Language Server Protocol implementation
- [ ] Multi-language support - Python, TypeScript, Rust, and more
- [ ] Multiple AI providers - OpenAI, Anthropic API, Ollama, and other backends

