-- vercel.lua — a Neovim colorscheme port of Vercel's Geist design system.
-- Pure-black canvas, crisp #ededed text, and Vercel's signature accents.
-- Ported/customized for Neovim from the Vercel (VSCode) aesthetic.
--
-- Usage: `:colorscheme vercel`  (or set it in your config)

vim.cmd.highlight("clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd.syntax("reset")
end

vim.g.colors_name = "vercel"
vim.o.termguicolors = true
vim.o.background = "dark"

-- ── Palette ────────────────────────────────────────────────────────────────
-- Grayscale follows Geist's dark scale; accents are the Vercel brand colors.
local c = {
  bg       = "#000000", -- Vercel pure black canvas
  bg_alt   = "#0a0a0a", -- raised panels / floats
  bg_float = "#111111", -- popups, menus
  bg_sel   = "#1f1f1f", -- selection / cursorline
  bg_hl    = "#161616", -- subtle highlight (current line bg)
  border   = "#333333", -- window separators, borders

  fg       = "#ededed", -- primary text  (geist gray-1000)
  fg_dim   = "#a1a1a1", -- secondary text (geist gray-900)
  fg_muted = "#808080", -- comments / disabled (brightened for contrast on black)
  fg_faint = "#444444", -- line numbers, whitespace

  blue     = "#3291ff", -- Vercel blue — functions, links (brightened for contrast on black)
  cyan     = "#50e3c2", -- strings
  teal     = "#79ffe1", -- properties / escapes / accents
  purple   = "#bd34fe", -- types (brightened for contrast on black)
  magenta  = "#ff0080", -- keywords / control flow
  red      = "#ff4d4f", -- errors
  orange   = "#f5a623", -- numbers / constants
  yellow   = "#f5d90a", -- warnings
  green    = "#0cce6b", -- success / diff add / git add
  white    = "#ffffff",
  none     = "NONE",
}

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- ── Editor UI ──────────────────────────────────────────────────────────────
local ui = {
  Normal        = { fg = c.fg, bg = c.bg },
  NormalNC      = { fg = c.fg, bg = c.bg },
  NormalFloat   = { fg = c.fg, bg = c.bg_float },
  NormalSB      = { fg = c.fg, bg = c.bg },
  FloatBorder   = { fg = c.border, bg = c.bg_float },
  FloatTitle    = { fg = c.fg, bg = c.bg_float, bold = true },
  ColorColumn   = { bg = c.bg_alt },
  Cursor        = { fg = c.bg, bg = c.fg },
  lCursor       = { fg = c.bg, bg = c.fg },
  CursorIM      = { fg = c.bg, bg = c.fg },
  CursorLine    = { bg = c.bg_hl },
  CursorColumn  = { bg = c.bg_hl },
  CursorLineNr  = { fg = c.fg, bold = true },
  LineNr        = { fg = c.fg_faint },
  LineNrAbove   = { fg = c.fg_faint },
  LineNrBelow   = { fg = c.fg_faint },
  SignColumn    = { fg = c.fg_muted, bg = c.bg },
  FoldColumn    = { fg = c.fg_muted, bg = c.bg },
  Folded        = { fg = c.fg_dim, bg = c.bg_alt },
  Conceal       = { fg = c.fg_muted },
  NonText       = { fg = c.fg_faint },
  Whitespace    = { fg = c.fg_faint },
  SpecialKey    = { fg = c.fg_faint },
  EndOfBuffer   = { fg = c.bg },
  MatchParen    = { fg = c.magenta, bold = true },
  WinSeparator  = { fg = c.border },
  VertSplit     = { fg = c.border },

  Visual        = { bg = c.bg_sel },
  VisualNOS     = { bg = c.bg_sel },
  Search        = { fg = c.bg, bg = c.orange },
  IncSearch     = { fg = c.bg, bg = c.yellow },
  CurSearch     = { fg = c.bg, bg = c.yellow },
  Substitute    = { fg = c.bg, bg = c.magenta },

  Pmenu         = { fg = c.fg_dim, bg = c.bg_float },
  PmenuSel      = { fg = c.fg, bg = c.bg_sel, bold = true },
  PmenuKind     = { fg = c.blue, bg = c.bg_float },
  PmenuKindSel  = { fg = c.blue, bg = c.bg_sel },
  PmenuExtra    = { fg = c.fg_muted, bg = c.bg_float },
  PmenuExtraSel = { fg = c.fg_dim, bg = c.bg_sel },
  PmenuSbar     = { bg = c.bg_alt },
  PmenuThumb    = { bg = c.border },
  WildMenu      = { fg = c.bg, bg = c.blue },

  StatusLine    = { fg = c.fg_dim, bg = c.bg_alt },
  StatusLineNC  = { fg = c.fg_muted, bg = c.bg_alt },
  TabLine       = { fg = c.fg_muted, bg = c.bg_alt },
  TabLineFill   = { bg = c.bg },
  TabLineSel    = { fg = c.fg, bg = c.bg, bold = true },
  WinBar        = { fg = c.fg_dim, bg = c.bg },
  WinBarNC      = { fg = c.fg_muted, bg = c.bg },

  ModeMsg       = { fg = c.fg_dim, bold = true },
  MoreMsg       = { fg = c.blue },
  Question      = { fg = c.blue },
  MsgArea       = { fg = c.fg_dim },
  ErrorMsg      = { fg = c.red },
  WarningMsg    = { fg = c.yellow },
  Title         = { fg = c.fg, bold = true },
  Directory     = { fg = c.blue },
  QuickFixLine  = { bg = c.bg_sel, bold = true },
}
for g, s in pairs(ui) do hl(g, s) end

-- ── Syntax (legacy vim groups) ─────────────────────────────────────────────
local syntax = {
  Comment        = { fg = c.fg_muted, italic = true },

  Constant       = { fg = c.orange },
  String         = { fg = c.cyan },
  Character      = { fg = c.cyan },
  Number         = { fg = c.orange },
  Float          = { fg = c.orange },
  Boolean        = { fg = c.orange },

  Identifier     = { fg = c.fg },
  Function       = { fg = c.blue },

  Statement      = { fg = c.magenta },
  Conditional    = { fg = c.magenta },
  Repeat         = { fg = c.magenta },
  Label          = { fg = c.magenta },
  Operator       = { fg = c.fg_dim },
  Keyword        = { fg = c.magenta },
  Exception      = { fg = c.magenta },

  PreProc        = { fg = c.teal },
  Include        = { fg = c.magenta },
  Define         = { fg = c.teal },
  Macro          = { fg = c.teal },
  PreCondit      = { fg = c.teal },

  Type           = { fg = c.purple },
  StorageClass   = { fg = c.magenta },
  Structure      = { fg = c.purple },
  Typedef        = { fg = c.purple },

  Special        = { fg = c.teal },
  SpecialChar    = { fg = c.teal },
  Tag            = { fg = c.blue },
  Delimiter      = { fg = c.fg_dim },
  SpecialComment = { fg = c.fg_dim, italic = true },
  Debug          = { fg = c.red },

  Underlined     = { fg = c.blue, underline = true },
  Ignore         = { fg = c.fg_muted },
  Error          = { fg = c.red },
  Todo           = { fg = c.bg, bg = c.yellow, bold = true },
}
for g, s in pairs(syntax) do hl(g, s) end

-- ── Treesitter ─────────────────────────────────────────────────────────────
local ts = {
  ["@comment"]              = { link = "Comment" },
  ["@comment.error"]        = { fg = c.red },
  ["@comment.warning"]      = { fg = c.yellow },
  ["@comment.todo"]         = { link = "Todo" },
  ["@comment.note"]         = { fg = c.blue },

  ["@variable"]             = { fg = c.fg },
  ["@variable.builtin"]     = { fg = c.magenta },
  ["@variable.parameter"]   = { fg = c.fg_dim },
  ["@variable.member"]      = { fg = c.teal },

  ["@constant"]             = { fg = c.orange },
  ["@constant.builtin"]     = { fg = c.orange },
  ["@constant.macro"]       = { fg = c.teal },

  ["@module"]               = { fg = c.fg },
  ["@label"]                = { fg = c.magenta },

  ["@string"]               = { link = "String" },
  ["@string.escape"]        = { fg = c.teal },
  ["@string.special"]       = { fg = c.teal },
  ["@string.regexp"]        = { fg = c.teal },
  ["@character"]            = { link = "Character" },

  ["@number"]               = { link = "Number" },
  ["@boolean"]              = { link = "Boolean" },
  ["@float"]                = { link = "Float" },

  ["@function"]             = { fg = c.blue },
  ["@function.builtin"]     = { fg = c.blue },
  ["@function.call"]        = { fg = c.blue },
  ["@function.macro"]       = { fg = c.teal },
  ["@function.method"]      = { fg = c.blue },
  ["@function.method.call"] = { fg = c.blue },
  ["@constructor"]          = { fg = c.purple },

  ["@keyword"]              = { fg = c.magenta },
  ["@keyword.function"]     = { fg = c.magenta },
  ["@keyword.operator"]     = { fg = c.magenta },
  ["@keyword.return"]       = { fg = c.magenta },
  ["@keyword.conditional"]  = { fg = c.magenta },
  ["@keyword.repeat"]       = { fg = c.magenta },
  ["@keyword.import"]       = { fg = c.magenta },
  ["@keyword.exception"]    = { fg = c.magenta },

  ["@operator"]             = { fg = c.fg_dim },
  ["@punctuation.delimiter"]= { fg = c.fg_dim },
  ["@punctuation.bracket"]  = { fg = c.fg_muted },
  ["@punctuation.special"]  = { fg = c.teal },

  ["@type"]                 = { fg = c.purple },
  ["@type.builtin"]         = { fg = c.purple },
  ["@type.definition"]      = { fg = c.purple },
  ["@attribute"]            = { fg = c.orange },
  ["@property"]             = { fg = c.teal },
  ["@field"]                = { fg = c.teal },

  ["@tag"]                  = { fg = c.magenta },
  ["@tag.builtin"]          = { fg = c.magenta },
  ["@tag.attribute"]        = { fg = c.blue },
  ["@tag.delimiter"]        = { fg = c.fg_muted },

  -- Headings. A terminal cannot vary glyph size, so hierarchy is carried by
  -- colour instead: H1/H2 use the bright accents, and later levels step down
  -- toward the body text. Applies to markdown and typst alike -- the typst
  -- parser emits @markup.heading.1 .. .6 the same way markdown does.
  ["@markup.heading"]       = { fg = c.blue, bold = true },
  ["@markup.heading.1"]     = { fg = c.blue, bold = true },
  ["@markup.heading.2"]     = { fg = c.purple, bold = true },
  ["@markup.heading.3"]     = { fg = c.teal, bold = true },
  ["@markup.heading.4"]     = { fg = c.green, bold = true },
  ["@markup.heading.5"]     = { fg = c.orange, bold = true },
  ["@markup.heading.6"]     = { fg = c.fg_dim, bold = true },
  ["@markup.strong"]        = { fg = c.fg, bold = true },
  ["@markup.italic"]        = { fg = c.fg, italic = true },
  ["@markup.strikethrough"] = { fg = c.fg_muted, strikethrough = true },
  ["@markup.link"]          = { fg = c.blue, underline = true },
  ["@markup.link.label"]    = { fg = c.teal },
  ["@markup.raw"]           = { fg = c.cyan },
  ["@markup.list"]          = { fg = c.magenta },
  ["@markup.quote"]         = { fg = c.fg_dim, italic = true },

  ["@diff.plus"]            = { fg = c.green },
  ["@diff.minus"]           = { fg = c.red },
  ["@diff.delta"]           = { fg = c.orange },
}
for g, s in pairs(ts) do hl(g, s) end

-- ── LSP semantic tokens ────────────────────────────────────────────────────
local lsp = {
  ["@lsp.type.namespace"]     = { link = "@module" },
  ["@lsp.type.type"]          = { link = "@type" },
  ["@lsp.type.class"]         = { link = "@type" },
  ["@lsp.type.enum"]          = { link = "@type" },
  ["@lsp.type.interface"]     = { link = "@type" },
  ["@lsp.type.struct"]        = { link = "@type" },
  ["@lsp.type.parameter"]     = { link = "@variable.parameter" },
  ["@lsp.type.variable"]      = { link = "@variable" },
  ["@lsp.type.property"]      = { link = "@property" },
  ["@lsp.type.enumMember"]    = { link = "@constant" },
  ["@lsp.type.function"]      = { link = "@function" },
  ["@lsp.type.method"]        = { link = "@function.method" },
  ["@lsp.type.macro"]         = { link = "@function.macro" },
  ["@lsp.type.keyword"]       = { link = "@keyword" },
  ["@lsp.type.comment"]       = { link = "@comment" },
  ["@lsp.type.decorator"]     = { link = "@attribute" },
  LspInlayHint                = { fg = c.fg_muted, bg = c.bg_alt },
  LspReferenceText            = { bg = c.bg_sel },
  LspReferenceRead            = { bg = c.bg_sel },
  LspReferenceWrite           = { bg = c.bg_sel, underline = true },
  LspSignatureActiveParameter = { fg = c.blue, bold = true },
  LspCodeLens                 = { fg = c.fg_muted },
}
for g, s in pairs(lsp) do hl(g, s) end

-- ── Diagnostics ────────────────────────────────────────────────────────────
local diag = {
  DiagnosticError            = { fg = c.red },
  DiagnosticWarn             = { fg = c.yellow },
  DiagnosticInfo             = { fg = c.blue },
  DiagnosticHint             = { fg = c.teal },
  DiagnosticOk               = { fg = c.green },
  DiagnosticUnderlineError   = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn    = { undercurl = true, sp = c.yellow },
  DiagnosticUnderlineInfo    = { undercurl = true, sp = c.blue },
  DiagnosticUnderlineHint    = { undercurl = true, sp = c.teal },
  DiagnosticVirtualTextError = { fg = c.red, bg = c.bg_alt },
  DiagnosticVirtualTextWarn  = { fg = c.yellow, bg = c.bg_alt },
  DiagnosticVirtualTextInfo  = { fg = c.blue, bg = c.bg_alt },
  DiagnosticVirtualTextHint  = { fg = c.teal, bg = c.bg_alt },
}
for g, s in pairs(diag) do hl(g, s) end

-- ── Diff / Git ─────────────────────────────────────────────────────────────
local git = {
  DiffAdd      = { bg = "#04361f" },
  DiffChange   = { bg = "#1a1a1a" },
  DiffDelete   = { bg = "#3a0d0d" },
  DiffText     = { bg = "#0a3d24" },
  Added        = { fg = c.green },
  Changed      = { fg = c.orange },
  Removed      = { fg = c.red },
  GitSignsAdd    = { fg = c.green },
  GitSignsChange = { fg = c.orange },
  GitSignsDelete = { fg = c.red },
  diffAdded    = { fg = c.green },
  diffRemoved  = { fg = c.red },
  diffChanged  = { fg = c.orange },
  diffLine     = { fg = c.blue },
  diffFile     = { fg = c.fg_dim },
}
for g, s in pairs(git) do hl(g, s) end

-- ── Plugin accents (Telescope, Neo-tree, WhichKey, cmp, indent) ────────────
local plugins = {
  -- render-markdown.nvim heading bands.
  -- Its defaults link these to the diff groups (H1Bg=DiffText, H2Bg=DiffAdd,
  -- H3Bg=DiffChange, H4Bg=DiffDelete), which on this theme paints headings
  -- green and red for no reason. Use neutral dark bands instead and let the
  -- level colour come from the foreground, as everywhere else in this theme.
  -- The band colour is also what the ▄/▀ border rows are drawn in.
  RenderMarkdownH1Bg     = { fg = c.blue, bg = c.bg_sel, bold = true },
  RenderMarkdownH2Bg     = { fg = c.purple, bg = c.bg_sel, bold = true },
  RenderMarkdownH3Bg     = { fg = c.teal, bg = c.bg_hl, bold = true },
  RenderMarkdownH4Bg     = { fg = c.green, bg = c.bg_hl, bold = true },
  RenderMarkdownH5Bg     = { fg = c.orange, bg = c.bg_hl, bold = true },
  RenderMarkdownH6Bg     = { fg = c.fg_dim, bg = c.bg_hl, bold = true },

  -- Telescope
  TelescopeNormal        = { fg = c.fg_dim, bg = c.bg_float },
  TelescopeBorder        = { fg = c.border, bg = c.bg_float },
  TelescopePromptNormal  = { fg = c.fg, bg = c.bg_alt },
  TelescopePromptBorder  = { fg = c.border, bg = c.bg_alt },
  TelescopePromptTitle   = { fg = c.bg, bg = c.blue, bold = true },
  TelescopePreviewTitle  = { fg = c.bg, bg = c.green, bold = true },
  TelescopeResultsTitle  = { fg = c.bg, bg = c.magenta, bold = true },
  TelescopeSelection     = { fg = c.fg, bg = c.bg_sel, bold = true },
  TelescopeMatching      = { fg = c.blue, bold = true },

  -- Neo-tree / NvimTree
  NeoTreeNormal          = { fg = c.fg_dim, bg = c.bg },
  NeoTreeNormalNC        = { fg = c.fg_dim, bg = c.bg },
  NeoTreeRootName        = { fg = c.fg, bold = true },
  NeoTreeGitModified     = { fg = c.orange },
  NeoTreeGitAdded        = { fg = c.green },
  NeoTreeGitDeleted      = { fg = c.red },
  NeoTreeIndentMarker    = { fg = c.fg_faint },
  NvimTreeNormal         = { fg = c.fg_dim, bg = c.bg },
  NvimTreeFolderIcon     = { fg = c.blue },
  NvimTreeRootFolder     = { fg = c.fg, bold = true },

  -- nvim-cmp
  CmpItemAbbr            = { fg = c.fg_dim },
  CmpItemAbbrMatch       = { fg = c.blue, bold = true },
  CmpItemAbbrMatchFuzzy  = { fg = c.blue },
  CmpItemAbbrDeprecated  = { fg = c.fg_muted, strikethrough = true },
  CmpItemKindFunction    = { fg = c.blue },
  CmpItemKindMethod      = { fg = c.blue },
  CmpItemKindVariable    = { fg = c.fg },
  CmpItemKindKeyword     = { fg = c.magenta },
  CmpItemKindText        = { fg = c.fg_dim },
  CmpItemKindSnippet     = { fg = c.teal },
  CmpItemKindClass       = { fg = c.purple },
  CmpItemMenu            = { fg = c.fg_muted },

  -- WhichKey
  WhichKey               = { fg = c.blue },
  WhichKeyGroup          = { fg = c.magenta },
  WhichKeyDesc           = { fg = c.fg_dim },
  WhichKeySeparator      = { fg = c.fg_muted },
  WhichKeyFloat          = { bg = c.bg_float },

  -- indent-blankline v3
  IblIndent              = { fg = c.fg_faint },
  IblScope               = { fg = c.border },

  -- notify / noice
  NotifyINFOBorder       = { fg = c.blue },
  NotifyWARNBorder       = { fg = c.yellow },
  NotifyERRORBorder      = { fg = c.red },

  -- misc
  FloatShadow            = { bg = c.bg },
  Bold                   = { bold = true },
  Italic                 = { italic = true },
}
for g, s in pairs(plugins) do hl(g, s) end

-- ── Terminal colors ────────────────────────────────────────────────────────
vim.g.terminal_color_0  = c.bg
vim.g.terminal_color_1  = c.red
vim.g.terminal_color_2  = c.green
vim.g.terminal_color_3  = c.yellow
vim.g.terminal_color_4  = c.blue
vim.g.terminal_color_5  = c.magenta
vim.g.terminal_color_6  = c.cyan
vim.g.terminal_color_7  = c.fg
vim.g.terminal_color_8  = c.fg_muted
vim.g.terminal_color_9  = c.red
vim.g.terminal_color_10 = c.green
vim.g.terminal_color_11 = c.orange
vim.g.terminal_color_12 = c.blue
vim.g.terminal_color_13 = c.purple
vim.g.terminal_color_14 = c.teal
vim.g.terminal_color_15 = c.white
