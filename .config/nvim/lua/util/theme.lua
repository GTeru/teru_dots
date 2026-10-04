local M = {}

local light_theme_patterns = {
  "latte",
  "light",
  "dawn",
  "day",
  "gruvbox%-light",
}

local state = {
  scheme = nil,
  timer = nil,
  interval = 3000,
}

function M.detect()
  local uname = vim.loop.os_uname().sysname
  if uname == "Darwin" then
    local out = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")
    return out:match("Dark") and "dark" or "light"
  end
  -- Current Omarchy versions atomically `mv` the resolved theme directory into
  -- place at ~/.config/omarchy/current/theme (a real directory, not a
  -- symlink), so resolving its name via fs_readlink always fails and falls
  -- back to the literal "theme" path segment. theme.name holds the actual
  -- selected theme's name instead.
  local theme_name_file = vim.fn.expand("~/.config/omarchy/current/theme.name")
  if vim.fn.filereadable(theme_name_file) == 1 then
    local name = (vim.fn.readfile(theme_name_file)[1] or ""):lower()
    for _, pat in ipairs(light_theme_patterns) do
      if name:match(pat) then
        return "light"
      end
    end
    return "dark"
  end
  local theme_link = vim.fn.expand("~/.config/omarchy/current/theme")
  if vim.fn.isdirectory(theme_link) == 1 or vim.fn.filereadable(theme_link) == 1 then
    local target = vim.loop.fs_readlink(theme_link) or theme_link
    local name = vim.fn.fnamemodify(target, ":t"):lower()
    for _, pat in ipairs(light_theme_patterns) do
      if name:match(pat) then
        return "light"
      end
    end
    return "dark"
  end
  return "dark"
end

function M.apply()
  local mode = M.detect()
  if vim.o.background ~= mode then
    vim.o.background = mode
  end
  vim.g._theme_applying = true
  pcall(vim.cmd.colorscheme, state.scheme)
  vim.g._theme_applying = false
end

local function start_timer()
  if state.timer then
    return
  end
  state.timer = vim.uv.new_timer()
  state.timer:start(state.interval, state.interval, vim.schedule_wrap(function()
    if not vim.g.theme_locked then
      M.apply()
    end
  end))
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

function M.lock()
  vim.g.theme_locked = true
  stop_timer()
end

function M.unlock()
  vim.g.theme_locked = false
  M.apply()
  start_timer()
end

-- Builds a lazy.nvim spec for a colorscheme plugin. All theme plugins install
-- and remain browsable via :colorscheme, but only the one whose `name` matches
-- lua/config/theme.lua wires itself into OS-follow via M.setup.
function M.plugin(spec)
  local name = assert(spec.name, "theme plugin spec requires 'name'")
  local is_active = require("config.theme") == name
  spec.priority = spec.priority or 1000
  spec.dependencies = spec.dependencies or { "LazyVim/LazyVim" }
  if is_active and spec.lazy == nil then
    -- lazy.nvim auto-detects colorscheme plugins and lazy-loads them on the
    -- first `:colorscheme <name>` call. If the name is already resolvable via
    -- 'runtimepath' completion at that point, it skips calling this plugin's
    -- `config` entirely and sources colors/<name>.lua directly instead - so
    -- M.setup() (and the manual-lock wiring) silently never runs. Force the
    -- active theme to load eagerly so config() is guaranteed to run.
    spec.lazy = false
  end
  if not spec.config then
    spec.config = function(_, opts)
      local ok, mod = pcall(require, name)
      if ok and type(mod.setup) == "function" then
        mod.setup(opts)
      end
      if is_active then
        M.setup(name)
      end
    end
  end
  return spec
end

function M.setup(scheme)
  state.scheme = scheme
  M.apply()
  start_timer()

  local group = vim.api.nvim_create_augroup("UtilTheme", { clear = true })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      if not vim.g.theme_locked then
        M.apply()
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if vim.g._theme_applying then
        return
      end
      M.lock()
    end,
  })

  vim.api.nvim_create_user_command("ThemeAuto", function()
    M.unlock()
  end, { desc = "Resume OS-follow colorscheme (clears manual lock)", force = true })
end

return M
