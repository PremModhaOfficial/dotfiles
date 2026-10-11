-- Central markdown kill-switch. `false` disables every markdown-related piece
-- of this config (conceallevel, treesitter parser, markview, markdownlint,
-- dropbar markdown source, image.nvim markdown rendering, diagrams, theme
-- markdown highlights). Flip to `true` to bring the whole stack back.
vim.g.markdown_enabled = false

require("core")
