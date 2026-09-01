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

-- Filetypes snacks.image treats as "documents" (the ones its queries cover).
local doc_filetypes = { "markdown", "typst", "tex", "latex", "html", "norg", "markdown_inline" }

local is_doc_filetype = {}
for _, ft in ipairs(doc_filetypes) do
  is_doc_filetype[ft] = true
end

-- snacks places conceal extmarks over math expressions (see its `doc.conceal`
-- default), but Neovim ignores conceal extmarks while `conceallevel` is 0 —
-- which is the default in these buffers. Without this the rendered image is
-- drawn over the start of the line and the raw source trails off to the right.
-- `conceallevel` is window-local, so this has to run per window, not per buffer.
local function enable_conceal()
  local ok, image = pcall(require, "snacks.image")
  if not ok or not image.config.enabled then return end
  if vim.wo.conceallevel < 2 then vim.wo.conceallevel = 2 end
  -- leave `concealcursor` empty so the raw source reappears on the cursor line
end

-- Fix ```math fenced blocks.
--
-- snacks captures the whole `fenced_code_block` as the image range and relies
-- on one conceal extmark spanning that range to hide the source. But it skips
-- creating that extmark when the range's first row is already concealed
-- (`is_concealed` in snacks/image/placement.lua), and Neovim's bundled
-- markdown highlights set `conceal_lines` on `fenced_code_block_delimiter`.
-- So at conceallevel>=2 the conceal is skipped, the content line is never
-- hidden, and the LaTeX source trails out past the rendered image.
--
-- Capturing `code_fence_content` as the range instead points it at the
-- content line, which carries no `conceal_lines`, so snacks conceals it and
-- draws the image exactly as it does for $$...$$. The delimiter lines are
-- hidden by Neovim's own query.
--
-- This replaces snacks' markdown "images" query wholesale, because an
-- `; extends` query file can only add rules, never correct one. The mermaid
-- rule is therefore carried over verbatim. Revisit if snacks changes
-- queries/markdown/images.scm upstream.
local markdown_images_query = [[
(fenced_code_block
  (info_string (language) @lang)
  (#eq? @lang "math")
  (code_fence_content) @image.content @image
  (#set! image.lang "latex")
  (#set! image.ext "math.tex"))

(fenced_code_block
  (info_string (language) @lang)
  (#eq? @lang "mermaid")
  (code_fence_content) @image.content
  (#set! injection.language "mermaid")
  (#set! image.ext "chart.mmd")
) @image
]]

local query_patched = false
local function patch_markdown_query()
  if query_patched then return end
  query_patched = true
  pcall(vim.treesitter.query.set, "markdown", "images", markdown_images_query)
end

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
            pattern = doc_filetypes,
            desc = "Bootstrap snacks.image inline rendering for doc buffers",
            callback = function(args)
              local ok, image = pcall(require, "snacks.image")
              if not ok or not image.config.enabled then return end
              patch_markdown_query() -- must run before the buffer is scanned for images
              image.setup() -- idempotent; registers snacks' own FileType->attach autocmd
              -- attach THIS buffer with its real bufnr (snacks' autocmd registered
              -- during setup() above won't fire for the already-open buffer)
              require("snacks.image.doc").attach(args.buf)
              enable_conceal()
            end,
          },
        },
        -- FileType only fires once per buffer, so a later `:split`/`:vsplit` would
        -- get a fresh window still at conceallevel=0. BufWinEnter covers every
        -- window the buffer is displayed in.
        snacks_image_conceal = {
          {
            event = "BufWinEnter",
            desc = "Enable conceal so snacks.image can hide math source",
            callback = function(args)
              if is_doc_filetype[vim.bo[args.buf].filetype] then enable_conceal() end
            end,
          },
        },
      },
    },
  },
}
