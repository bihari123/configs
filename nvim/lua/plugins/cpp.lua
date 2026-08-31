-- C/C++ debugging: generic codelldb launch/attach DAP configs.
--
-- clangd, clangd_extensions, cmake-tools and the codelldb install already come
-- from astrocommunity.pack.cpp (imported in community.lua), and nvim-dap /
-- dap-ui / debug keymaps come from AstroNvim. The only gap that pack leaves is
-- a way to debug a *plain compiled binary* (cmake-tools already covers CMake
-- projects), so this adds two DAP configurations for that.
--
-- Registered via an astrocore FileType autocmd rather than a nvim-dap `config`
-- override, so nvim-dap's own setup (signs, dap-ui listeners) is never clobbered.

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        cpp_codelldb_dap = {
          {
            event = "FileType",
            pattern = { "c", "cpp" },
            desc = "Register codelldb launch/attach DAP configs for C/C++",
            callback = function()
              if vim.g.cpp_codelldb_registered then return end
              local ok, dap = pcall(require, "dap")
              if not ok then return end
              vim.g.cpp_codelldb_registered = true

              -- Register the adapter if mason-nvim-dap hasn't already.
              if not dap.adapters.codelldb then
                local codelldb = vim.fn.stdpath "data"
                  .. "/mason/packages/codelldb/extension/adapter/codelldb"
                dap.adapters.codelldb = {
                  type = "server",
                  port = "${port}",
                  executable = { command = codelldb, args = { "--port", "${port}" } },
                }
              end

              local cfg = {
                {
                  name = "Launch (codelldb)",
                  type = "codelldb",
                  request = "launch",
                  program = function()
                    return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
                  end,
                  cwd = "${workspaceFolder}",
                  stopOnEntry = false,
                  args = {},
                },
                {
                  name = "Attach to process",
                  type = "codelldb",
                  request = "attach",
                  pid = require("dap.utils").pick_process,
                  args = {},
                },
              }

              -- Extend rather than replace, so anything mason-nvim-dap set stays.
              dap.configurations.c = dap.configurations.c or {}
              dap.configurations.cpp = dap.configurations.cpp or {}
              vim.list_extend(dap.configurations.c, cfg)
              vim.list_extend(dap.configurations.cpp, cfg)
            end,
          },
        },
      },
    },
  },
}
