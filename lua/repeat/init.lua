local M = {}

local plug = vim.api.nvim_replace_termcodes("<Plug>", true, false, true)
local plug_repeat_operation = plug .. "__repeat_operation__"
local plug_repeat_motion = plug .. "__repeat_motion__"

local repeat_operation
local repeat_operation_count
local repeat_motion
local repeat_motion_count
local repeat_register = { "", "" }

local repeat_tick = -1

local function is_non_zero_number(count)
  return count and (type(count) == "number") and count ~= 0
end

local function is_number(count)
  return count and (type(count) == "number")
end

local function update_repeat_tick()
  repeat_tick = vim.b.changedtick
end

local function is_default_register(register)
  local clipboard = vim.opt.clipboard:get()
  if vim.tbl_contains(clipboard, "unnamedplus") then
    return register == "+"
  end
  if vim.tbl_contains(clipboard, "unnamed") then
    return register == "*"
  end
  return register == '"'
end

local function get_register_sequence()
  local reg = ""
  if (repeat_register[1] == repeat_operation) and repeat_register[2] ~= "" then
    local reg_name = is_default_register(vim.v.register) and repeat_register[2] or vim.v.register
    if reg_name == "=" then
      reg = '"=' .. vim.fn.getreg("=", 1) .. "\\<CR>"
    else
      reg = '"' .. reg_name
    end
  end
  return reg
end

--- @param count? integer
function M.operation(count)
  if repeat_operation and repeat_tick == vim.b.changedtick then
    count = is_non_zero_number(count) and count or repeat_operation_count
    local reg = get_register_sequence()
    local seq = ""
    if type(repeat_operation) == "function" then
      seq = plug_repeat_operation
    elseif type(repeat_operation) == "string" then
      seq = repeat_operation --[[@as string]]
    end
    vim.api.nvim_feedkeys(seq, "i", true)
    vim.api.nvim_feedkeys(reg .. (count == 0 and "" or tostring(count)), "ni", false)
  else
    vim.api.nvim_feedkeys((count == 0 and "" or count) .. ".", "ni", false)
  end
end

--- @param count? integer
function M.motion(count)
  count = is_non_zero_number(count) and count or repeat_motion_count
  --- @type string
  local seq = ""
  if type(repeat_motion) == "function" then
    seq = plug_repeat_motion
  elseif type(repeat_motion) == "string" then
    seq = repeat_motion --[[@as string]]
  end
  vim.api.nvim_feedkeys(seq, "i", true)
  vim.api.nvim_feedkeys(count == 0 and "" or tostring(count), "ni", false)
end

--- @param command string
--- @param count? integer
function M.wrap(command, count)
  local cnt = is_non_zero_number(count) and tostring(count) or ""
  local preserve = (repeat_tick == vim.b.changedtick) and "<Plug>__repeat_wrap__" or ""
  local foldopen = vim.o.foldopen
  local fo = (foldopen == "undo" or foldopen == "all") and "zv" or ""
  return cnt .. command .. preserve .. fo
end

--- @param operation string|fun()
--- @param count? integer
function M.set_operation(operation, count)
  repeat_operation_count = is_number(count) and count or vim.v.count
  repeat_operation = operation
  update_repeat_tick()
end

--- @param motion string|fun()
--- @param count? integer
function M.set_motion(motion, count)
  repeat_motion_count = is_number(count) and count or vim.v.count
  repeat_motion = motion
end

--- @param operation string|fun()
--- @param register string
function M.set_register(operation, register)
  repeat_register = { operation, (register and (type(register) == "string")) and register or "" }
end

--- @class Repeat.Config.Keymap
--- @field operation? string
--- @field motion? string
--- @field undo? string
--- @field undoline? string
--- @field redo? string

--- @class Repeat.Config
--- @field keymap? Repeat.Config.Keymap

--- @param config? Repeat.Config
function M.setup(config)
  --- @type Repeat.Config
  local default_config = {
    keymap = {
      operation = ".",
      motion = ",",
      undo = "u",
      undoline = "U",
      redo = "<C-r>",
    },
  }

  config = vim.tbl_deep_extend("force", default_config, config or {})
  vim.keymap.set("n", config.keymap.operation, function()
    M.operation(vim.v.count)
  end, {
    desc = "Repeat operation",
  })
  vim.keymap.set("n", config.keymap.motion, function()
    M.motion(vim.v.count)
  end, {
    desc = "Repeat motion",
  })
  vim.keymap.set("n", config.keymap.undo, function()
    return M.wrap("u", vim.v.count)
  end, {
    expr = true,
  })
  vim.keymap.set("n", config.keymap.undoline, function()
    return M.wrap("U", vim.v.count)
  end, {
    expr = true,
  })
  vim.keymap.set("n", config.keymap.redo, function()
    return M.wrap("<C-r>", vim.v.count)
  end, {
    expr = true,
  })
  vim.keymap.set("n", "<Plug>__repeat_motion__", function()
    repeat_motion()
  end)
  vim.keymap.set("n", "<Plug>__repeat_operation__", function()
    repeat_operation()
  end)
  vim.keymap.set("n", "<Plug>__repeat_wrap__", function()
    update_repeat_tick()
  end)
end

return M
