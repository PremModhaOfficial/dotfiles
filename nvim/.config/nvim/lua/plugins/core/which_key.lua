return {
  "folke/which-key.nvim",
  event = "VimEnter",
  config = function()
    require("which-key").setup({
      win = { border = require("lib.utils").border("WhichKeyBorder") },
    })
    require("which-key").add({
      { "<leader>c", "[C]ode" },
      { "<leader>d", "[D]ocument" },
      { "<leader>r", "[R]ename" },
      { "<leader>s", "[S]earch" },
      { "<leader>w", "[W]orkspace" },
      { "<leader>t", "[T]oggle" },
      { "<leader>ca", "[C]ode [A]ction" },
      { "<leader>ci", "[C]all [I]ncoming" },
      { "<leader>co", "[C]all [O]utgoing" },
      { "<leader>ws", "[W]orkspace [S]ymbols" },
      { "<leader>P", "[P]eek type definition" },
      { "<leader>rn", "[R]e[n]ame" },
      { "<leader>rN", "[R]e[n]ame project" },
      { "<leader>th", "[T]oggle inlay [H]ints" },
      { "<leader>wd", "[W]orkspace [D]iagnostics" },
    })
  end,
}