-- Heading presentation for markdown docs.
--
-- A terminal cannot render text at more than one size: every cell is a fixed
-- glyph box, so a heading physically cannot be taller than body text. (kitty
-- 0.40+ does have a text-sizing protocol, but Neovim's TUI never emits it and
-- there is no per-highlight font size in Neovim.)
--
-- What we can do is give headings more *space* and weight. `border` draws the
-- half-block rows above and below the heading, so an H1/H2 occupies three
-- rows and reads as a banner rather than one more line of text.
--
-- Per-level heading colours live in colors/vercel.lua (@markup.heading.1..6)
-- so that typst headings get the same hierarchy -- render-markdown only
-- handles markdown.

---@type LazySpec
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    heading = {
      -- Three-row banner (▄ above, heading, ▀ below) for H1/H2 only. Deeper
      -- levels stay single-line so a doc full of H3s is not mostly padding.
      -- `border` accepts a per-level list; it is read with
      -- list.clamp(config.border, level) in render/markdown/heading.lua.
      border = { true, true, false, false, false, false },
      -- draw the border on real rows rather than virtual lines, so the
      -- banner survives yanking and does not shift line numbers
      border_virtual = false,
      -- band hugs the text instead of spanning the whole window
      width = "block",
      min_width = 40,
      left_pad = 1,
      right_pad = 2,
    },
  },
}
