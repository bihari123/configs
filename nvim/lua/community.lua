-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },

  -- language pack: C / C++ (clangd, inlay hints, switch source/header)
  { import = "astrocommunity.pack.cpp" },

  -- language pack: Java (nvim-jdtls, java-debug-adapter, java-test, lombok)
  { import = "astrocommunity.pack.java" },

  -- language pack: Typst (tinymist LSP, typst-preview, syntax) — for maths/econ notes -> PDF
  { import = "astrocommunity.pack.typst" },

  -- authoring course docs: render markdown inline
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },

  -- motion / editing
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.motion.harpoon" },

  -- diagnostics panel
  { import = "astrocommunity.diagnostics.trouble-nvim" },

  -- import/override with your plugins folder
}
