-- dooing: minimalist to-do list manager
-- https://github.com/atiladefreitas/dooing
-- Default keymaps:
--   <Leader>td  toggle global to-do window
--   <Leader>tD  toggle project-specific to-do window
--   <Leader>tN  show due items window

---@type LazySpec
return {
  "atiladefreitas/dooing",
  event = "VeryLazy",
  opts = {
    -- custom config goes here (works with sensible defaults if left empty)
  },
}
