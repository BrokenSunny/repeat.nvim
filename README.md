# repeat.nvim

借鉴 vim-repeat

```lua
require("repeat").setup({
  keymap = {
    operation = ".",
    motion = ",",
    undo = "u",
    undoline = "U",
    redo = "<C-r>",
  }
})

local function rhs()
  vim.api.nvim_feedkeys("diw", "nx", true) -- or vim.cmd("norm! diw") 
  require('repeat').set_operation(rhs)
end

vim.keymap.set("n", "<leader>1", rhs)

vim.keymap.set("n", "<Plug>Rhs", "diw<cmd>lua require('repeat').set_operation('<Plug>Rhs')<cr>")
vim.keymap.set("n", "<leader>2", "<Plug>Rhs")
```
