-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "astrodark",
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    highlights = {
      init = { -- this table overrides highlights in all themes
        -- Better contrast for small fonts in dark environments
        Normal = { bg = "#0d0d0d", fg = "#d4d4d4" }, -- Slightly darker background, softer foreground
        CursorLine = { bg = "#1a1a1a" }, -- Subtle cursor line
        LineNr = { fg = "#565656" }, -- Dimmed line numbers
        CursorLineNr = { fg = "#878787", bold = true }, -- Current line number more visible
        Comment = { fg = "#808080", italic = true }, -- More readable comments
        -- Better visibility for important elements
        Search = { bg = "#3d3d00", fg = "#ffff87" }, -- Yellow search highlights
        IncSearch = { bg = "#5f5f00", fg = "#ffff87" }, -- Current search
        Visual = { bg = "#2d2d3d" }, -- Selection background
        -- Softer colors for less eye strain
        String = { fg = "#87d787" }, -- Soft green
        Function = { fg = "#87afff" }, -- Soft blue
        Keyword = { fg = "#ff87af" }, -- Soft pink
        Type = { fg = "#87d7ff" }, -- Soft cyan
        Constant = { fg = "#d7af87" }, -- Soft orange
        -- Error and warning colors that don't hurt
        Error = { fg = "#ff8787", bg = "NONE" },
        Warning = { fg = "#ffd787", bg = "NONE" },
        -- Better diff colors
        DiffAdd = { bg = "#1c2c1c" },
        DiffDelete = { bg = "#2c1c1c" },
        DiffChange = { bg = "#1c1c2c" },
        DiffText = { bg = "#2c2c3c" },
      },
      astrodark = { -- a table of overrides/changes when applying the astrotheme theme
        -- Additional overrides specific to astrodark
      },
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
