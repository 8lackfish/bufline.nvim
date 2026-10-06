# bufline.nvim

A minimal, fast, and smart bufferline plugin for Neovim written in Lua.

It features a smart auto-truncation mechanism that automatically balances left and right buffer sections, ensuring your currently focused buffer always stays visible even when opening many files.

## ✨ Features

- 🚀 **Lightweight & Fast**: Built purely in Lua with zero overhead.
- 🎯 **Smart Auto-Truncation**: Intelligent center-focused calculation algorithm to keep active buffers visible.
- 🎨 **Flexible Highlighting**: Easy customization for active, inactive, and fill tabline areas.
- ✂️ **Custom Separators**: Full support for section separators and status indicators.

## ⚡ Requirements

- Neovim >= 0.8.0

## 📦 Installation

### Using [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
{
  "8lackfish/bufline.nvim",
  config = function()
    require("bufline").setup({
      -- Optional configuration options
    })
  end,
}


**Using packer.nvim**
use {
  '8lackfish/bufline.nvim',
  config = function()
    require('bufline').setup()
  end
}

**Configuration**
require("bufline").setup({
  separator = '',                -- Separator between buffer labels
  section_separator = '',        -- Separator between sections (left/focused/right)
  modified_indicator = '[M]',    -- Indicator when buffer is modified

  highlights = {
    normal = 'TabLine',          -- Highlight group for inactive buffers
    focused = 'TabLineSel',      -- Highlight group for active/focused buffer
    fill = 'TabLineFill',        -- Highlight group for the remaining tabline space
  }
})
