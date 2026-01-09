return {
  "stevearc/conform.nvim",
  lazy = false,
  keys = {
    {
      "<leader>DF",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "[F]ormat buffer",
    },
  },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true, rust = true }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "eslint", "prettierd", "prettier", stop_after_first = true },
      typrscript = { "prettierd", "prettier", "eslint", stop_after_first = true },
    },
  },
}
