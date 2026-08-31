-- Inline image / math rendering in Markdown & Typst via the kitty graphics
-- protocol. Uses the snacks.nvim `image` module (snacks is already installed
-- by AstroNvim), so no new plugin is pulled in.
--
-- External deps: imagemagick (`magick`) for image conversion, `typst` for
-- typst math (already installed), `tectonic`/`latex` for LaTeX math (optional).
--
-- NOTE on the bootstrap autocmd below: snacks only calls `Snacks.image.setup()`
-- (which registers the FileType -> doc.attach autocmd that actually renders
-- doc images) when you open an *image file*. Opening a .md/.typ from a cold
-- start therefore never attaches and nothing renders. We fix that by running
-- setup ourselves on the first doc FileType and attaching the current buffer
-- with its real bufnr (attach(0) breaks snacks' win_findbuf lookup).

---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = {
          -- render image references (![](foo.png)) inline in the buffer
          inline = true,
          -- floating-window fallback when inline isn't possible
          float = true,
          max_width = 80,
          max_height = 40,
        },
        -- render math blocks ($...$, latex, typst) as images
        math = { enabled = true },
      },
    },
  },

  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        snacks_image_bootstrap = {
          {
            event = "FileType",
            pattern = { "markdown", "typst", "tex", "latex", "html", "norg", "markdown_inline" },
            desc = "Bootstrap snacks.image inline rendering for doc buffers",
            callback = function(args)
              local ok, image = pcall(require, "snacks.image")
              if not ok or not image.config.enabled then return end
              image.setup() -- idempotent; registers snacks' own FileType->attach autocmd
              -- attach THIS buffer with its real bufnr (snacks' autocmd registered
              -- during setup() above won't fire for the already-open buffer)
              require("snacks.image.doc").attach(args.buf)
            end,
          },
        },
      },
    },
  },
}
