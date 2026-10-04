local theme = require("util.theme")
local context = describe

theme.setup("default")

describe("Feature: OS-follow colorscheme", function()
  local orig = {}

  before_each(function()
    orig.system = vim.fn.system
    orig.os_uname = vim.loop.os_uname
    orig.expand = vim.fn.expand
    orig.isdirectory = vim.fn.isdirectory
    orig.filereadable = vim.fn.filereadable
    orig.fs_readlink = vim.loop.fs_readlink
    orig.fnamemodify = vim.fn.fnamemodify
    orig.readfile = vim.fn.readfile
    vim.fn.expand = function(path)
      return (path:gsub("^~", "/home/u"))
    end
    vim.fn.filereadable = function() return 0 end
    vim.g.theme_locked = false
    vim.g._theme_applying = false
  end)

  after_each(function()
    vim.fn.system = orig.system
    vim.loop.os_uname = orig.os_uname
    vim.fn.expand = orig.expand
    vim.fn.isdirectory = orig.isdirectory
    vim.fn.filereadable = orig.filereadable
    vim.loop.fs_readlink = orig.fs_readlink
    vim.fn.fnamemodify = orig.fnamemodify
    vim.fn.readfile = orig.readfile
  end)

  describe("Scenario: detecting system appearance", function()
    context("Given macOS reports Dark mode", function()
      it("Then detect() should return 'dark'", function()
        vim.loop.os_uname = function() return { sysname = "Darwin" } end
        vim.fn.system = function() return "Dark\n" end
        assert.are.equal("dark", theme.detect())
      end)
    end)

    context("Given macOS reports Light mode", function()
      it("Then detect() should return 'light'", function()
        vim.loop.os_uname = function() return { sysname = "Darwin" } end
        vim.fn.system = function() return "" end
        assert.are.equal("light", theme.detect())
      end)
    end)

    context("Given omarchy's current theme.name is a Latte variant", function()
      it("Then detect() should return 'light'", function()
        vim.loop.os_uname = function() return { sysname = "Linux" } end
        vim.fn.filereadable = function(path)
          return path:match("theme%.name$") and 1 or 0
        end
        vim.fn.readfile = function() return { "catppuccin-latte" } end
        assert.are.equal("light", theme.detect())
      end)
    end)

    context("Given omarchy's current theme.name is a non-light variant", function()
      it("Then detect() should return 'dark'", function()
        vim.loop.os_uname = function() return { sysname = "Linux" } end
        vim.fn.filereadable = function(path)
          return path:match("theme%.name$") and 1 or 0
        end
        vim.fn.readfile = function() return { "tokyo-night" } end
        assert.are.equal("dark", theme.detect())
      end)
    end)

    context("Given theme.name is missing but the legacy theme symlink points to a Latte variant", function()
      it("Then detect() should return 'light'", function()
        vim.loop.os_uname = function() return { sysname = "Linux" } end
        vim.fn.isdirectory = function() return 0 end
        vim.fn.filereadable = function(path)
          return (not path:match("theme%.name$")) and path:match("theme$") and 1 or 0
        end
        vim.loop.fs_readlink = function() return "/themes/catppuccin-latte" end
        vim.fn.fnamemodify = function() return "catppuccin-latte" end
        assert.are.equal("light", theme.detect())
      end)
    end)

    context("Given no OS appearance signal is available", function()
      it("Then detect() should fall back to 'dark'", function()
        vim.loop.os_uname = function() return { sysname = "Linux" } end
        vim.fn.isdirectory = function() return 0 end
        vim.fn.filereadable = function() return 0 end
        assert.are.equal("dark", theme.detect())
      end)
    end)
  end)

  describe("Scenario: manual colorscheme override", function()
    context("Given the user runs :colorscheme <name>", function()
      it("Then OS-follow should become locked", function()
        vim.g.theme_locked = false
        vim.g._theme_applying = false
        pcall(vim.cmd.colorscheme, "default")
        assert.is_true(vim.g.theme_locked)
      end)
    end)

    context("Given the module re-applies its own scheme", function()
      it("Then OS-follow should remain unlocked", function()
        vim.g.theme_locked = false
        theme.apply()
        assert.is_false(vim.g.theme_locked)
      end)
    end)

    context("Given the manual lock is active", function()
      it("Then FocusGained should not overwrite the user's scheme", function()
        pcall(vim.cmd.colorscheme, "default")
        theme.lock()
        local before = vim.g.colors_name
        vim.api.nvim_exec_autocmds("FocusGained", {})
        assert.are.equal(before, vim.g.colors_name)
      end)
    end)
  end)

  describe("Scenario: :ThemeAuto command", function()
    context("Given setup() has completed", function()
      it("Then the :ThemeAuto command should be registered", function()
        assert.are.equal(2, vim.fn.exists(":ThemeAuto"))
      end)
    end)

    context("Given the manual lock is active", function()
      it("Then invoking :ThemeAuto should clear the lock and re-sync to the OS scheme", function()
        theme.lock()
        assert.is_true(vim.g.theme_locked)
        vim.cmd("ThemeAuto")
        assert.is_false(vim.g.theme_locked)
      end)
    end)
  end)
end)
