-- Typst quality-of-life: auto-export PDF on save + buffer-local shortcuts.
-- Keymaps use the localleader (",") and only apply in .typ files, so they
-- don't collide with the global <Leader>t* (terminal/dooing) maps.

---@type LazySpec
return {
  -- 1) tinymist: write a PDF next to the file on every save
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        tinymist = {
          settings = {
            exportPdf = "onSave", -- "never" | "onSave" | "onType"
            outputPath = "$dir/$name", -- foo.typ -> foo.pdf beside it
          },
        },
      },
    },
  },

  -- 2) shortcuts inside Typst buffers (localleader = ",")
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        typst_shortcuts = {
          {
            event = "FileType",
            pattern = "typst",
            desc = "Typst preview/compile shortcuts",
            callback = function(args)
              local map = function(lhs, rhs, desc)
                vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
              end
              -- ,p  toggle live preview (watch)
              map("<LocalLeader>p", "<Cmd>TypstPreviewToggle<CR>", "Typst: toggle preview")
              -- ,s  sync preview to cursor
              map("<LocalLeader>s", "<Cmd>TypstPreviewSyncCursor<CR>", "Typst: sync preview to cursor")
              -- ,c  compile this file to PDF now (one-shot, via the typst binary)
              map("<LocalLeader>c", function()
                vim.cmd "silent! write"
                local file = vim.fn.expand "%:p"
                vim.system({ "typst", "compile", file }, {}, function(res)
                  vim.schedule(function()
                    if res.code == 0 then
                      vim.notify("Typst: compiled " .. vim.fn.expand "%:t:r" .. ".pdf", vim.log.levels.INFO)
                    else
                      vim.notify("Typst compile failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
                    end
                  end)
                end)
              end, "Typst: compile to PDF")
            end,
          },
        },
      },
    },
  },
}
