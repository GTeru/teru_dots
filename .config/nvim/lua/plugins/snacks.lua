-- lazy.nvim
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = { hidden = true, ignored = true },
      },
    },
    explorer = {},
  },
  keys = {
    {
      "<leader><space>",
      function()
        Snacks.picker.files({ hidden = true, ignored = true })
      end,
      desc = "Find files",
    },
  },
}
