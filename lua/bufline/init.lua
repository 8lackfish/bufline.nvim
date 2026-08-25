local lum = {}
lum.color = require 'lum.color'

local defaults = {
  separator = '',
  section_separator = '',
  modified_indicator = '[M]',

  highlights = {
    normal = 'TabLine',
    focused = 'TabLineSel',
    fill = 'TabLineFill'
  }
}

---@class BufLineHighLights
---@field normal? string|table Highlight group name or highlight spec for buffer labels (default: 'TabLine')
---@field focused? string|table Highlight group name or highlight spec for focused buffer label (default: 'TabLineSel')
---@field fill? string|table Highlight group name or highlight spec for remaining line area (default: 'TabLineFill')

---@class BufLineOpts
---@field separator? string Separator between buffer labels (default: '')
---@field section_separator? string Separator between sections of buffer labels (default: '')
---@field modified_indicator? string Indicator when buffer is modified (default: '[M]')
---@field highlights? BufLineHighLights Highlight options

---@param opts? BufLineOpts Options table
---@return string
local function build(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  local sep = opts.separator
  local sec_sep = opts.section_separator
  local mod_ind = opts.modified_indicator
  local hl_normal = opts.highlights.normal
  local hl_focused = opts.highlights.focused
  local hl_fill = opts.highlights.fill

  if type(hl_normal) == 'string' then
    hl_normal = vim.fn.hlexists(hl_normal) == 1 and hl_normal or defaults.highlights.normal
  elseif type(hl_normal) == 'table' then
    vim.api.nvim_set_hl(0, 'BufLine', hl_normal)
    hl_normal = 'BufLine'
  end

  if type(hl_focused) == 'string' then
    hl_focused = vim.fn.hlexists(hl_focused) == 1 and hl_focused or defaults.highlights.focused
  elseif type(hl_focused) == 'table' then
    vim.api.nvim_set_hl(0, 'BufLineSel', hl_focused)
    hl_focused = 'BufLineSel'
  end

  if type(hl_fill) == 'string' then
    hl_fill = vim.fn.hlexists(hl_fill) == 1 and hl_fill or defaults.highlights.fill
  elseif type(hl_fill) == 'table' then
    vim.api.nvim_set_hl(0, 'BufLineFill', hl_fill)
    hl_fill = 'BufLineFill'
  end

  --[[

  When the width of the displayed content exceeds the window width,
  the tabline option automatically truncates the displayed content from
  the beginning of each tabline label until the remaining content fits
  within the window width.

  The focused buffer item should always stay in a non-truncated scope.
  That should be the minimum requirement.

  The simplest way to meet the minimal requirement based on the
  automatic-truncation mechanism is to always display content that begins
  or ends at the focused item whenever it exceeds the window width.
  However, this approach limits how intuitive it feels to navigate focus.
  Therefore, still based on the automatic-truncation mechanism, a better
  approach is to always display content that expands outward from the
  focused item in both directions until it fills the available window
  width.

  The content consists of three main sections:
  left | focused | right, with two cases: basic case and overflow case.

  In the overflow case:

  Determine the planned width of the left section as half of the
  available window width after reserving the focused section. If the
  real width of the left section is smaller than the planned left width,
  the planned left width is set to the real width. The total width
  should also be recalculated using the planned width of the left
  section. If the new total still exceeds the window width:

    planned_left_width + focused_width + right_width > nvim_win_width

  Then:

    right_width > nvim_win_width - planned_left_width - focused_width
    <=> right_width > expected_right_width

  ]]

  local current_buf = vim.api.nvim_get_current_buf()
  local bufls = vim.api.nvim_list_bufs()

  local left = ""
  local right = ""
  local focused = ""
  local finished_left = false

  -- a section always starts and ends with one space
  for _, buf_id in ipairs(bufls) do
    if vim.bo[buf_id].buflisted then
      local buf_name = vim.api.nvim_buf_get_name(buf_id)
      buf_name = vim.fn.fnamemodify(buf_name, ":t")
      if buf_name == "" then buf_name = "[No Name]" end
      local label_text = " " .. buf_name .. " " .. (vim.bo[buf_id].modified and mod_ind .. " " or "")

      if finished_left then
        right = right .. (right ~= "" and sep or "") .. label_text
      else
        if buf_id == current_buf then
          focused = label_text
          finished_left = true
        else
          left = left .. (left ~= "" and sep or "") .. label_text
        end
      end
    end
  end

  local nvim_win_width = vim.o.columns
  local left_width = vim.fn.strdisplaywidth(left)
  local focused_width = vim.fn.strdisplaywidth(focused)
  local right_width = vim.fn.strdisplaywidth(right)

  -- sec_sep labels
  local ss_width = vim.fn.strdisplaywidth(sec_sep)

  local normal_bg = lum.color.hlcolor(hl_normal, 'bg')
  local focused_bg = lum.color.hlcolor(hl_focused, 'bg')
  local fill_bg = lum.color.hlcolor(hl_fill, 'bg')
  vim.api.nvim_set_hl(0, 'bufline_left_-_focused_ss', { fg = normal_bg, bg = focused_bg })
  vim.api.nvim_set_hl(0, 'bufline_focused_-_right_ss', { fg = focused_bg, bg = normal_bg })
  vim.api.nvim_set_hl(0, 'bufline_right_-_empty_ss', { fg = normal_bg, bg = fill_bg })
  vim.api.nvim_set_hl(0, 'bufline_focused_-_empty_ss', { fg = focused_bg, bg = fill_bg })

  local left_ss_label, focused_ss_label, right_ss_label = "","",""

  if left_width ~= 0 then
    left_width = left_width + ss_width
    if focused_width ~= 0 then
      left_ss_label = "%#bufline_left_-_focused_ss#" .. sec_sep
    else
      left_ss_label = "%#bufline_right_-_empty_ss#" .. sec_sep
    end
  end

  if focused_width ~= 0 then
    focused_width = focused_width + ss_width
    if right_width ~= 0 then
      focused_ss_label = "%#bufline_focused_-_right_ss#" .. sec_sep
    else
      focused_ss_label = "%#bufline_focused_-_empty_ss#" .. sec_sep
    end
  end

  if right_width ~= 0 then
    right_width = right_width + ss_width
    right_ss_label = "%#bufline_right_-_empty_ss#" .. sec_sep
  end

  local function line()
    return "%#" .. hl_normal .. "#" .. left
    .. left_ss_label
    .. "%#" .. hl_focused .. "#" .. focused
    .. focused_ss_label
    .. "%#" .. hl_normal .. "#" .. right
    .. right_ss_label
    .. "%#" .. hl_fill .. "#"
  end

  -- The basic case
  if (left_width + focused_width + right_width) <= nvim_win_width then
    return line()
  end

  -- The overflow case
  local planned_left_width = math.floor((nvim_win_width - focused_width)/2)

  planned_left_width = math.min(left_width, planned_left_width)

  if planned_left_width + focused_width + right_width <= nvim_win_width then
    return line()
  end

  local expected_right_width = nvim_win_width - planned_left_width - focused_width
  local right_length = vim.fn.strchars(right)
  local tbl = {}

  for i = 0, right_length - 1 do
    tbl[#tbl+1] = vim.fn.strcharpart(right, i, 1)
    local get_right = table.concat(tbl)
    if vim.fn.strdisplaywidth(get_right) >= expected_right_width - ss_width then
      local right_arrow = ">" -- 1 cell
      right = vim.fn.strcharpart(get_right, 0, vim.fn.strchars(get_right) - 1)
      local n_space = (expected_right_width - ss_width) - vim.fn.strdisplaywidth(right) - 1 -- 1 = vim.fn.strdisplaywidth(right_arrow)
      local spaces = string.rep(" ", n_space)
      right = right .. spaces .. right_arrow

      -- print(vim.fn.strdisplaywidth(right .. sec_sep) .. "|" .. (expected_right_width))

      break
    end
  end

  return line()
end

local M = {}

---@param opts? BufLineOpts Options table
function M.setup(opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})

  ---@private
  function _G._bufline_nvim_lua_bufline_build_entry_point()
    return build(opts)
  end

  vim.o.tabline = "%!v:lua._bufline_nvim_lua_bufline_build_entry_point()"
  vim.o.showtabline = 2
end

return M
