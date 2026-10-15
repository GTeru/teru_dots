return {
  "GCBallesteros/jupytext.nvim",
  lazy = false, -- must load before the .ipynb buffer opens
  opts = {
    style = "hydrogen", -- `# %%` cells
    output_extension = "auto",
  },
}
