return {
    -- add gruvbox
    {
        "abhidahal/onsetGlaze.nvim",
    },
    {
        "catppuccin/nvim",
        lazy = true,
        name = "catppuccin",
        require("notify").setup({
            background_colour = "#000000",
        }),
    },

    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "moon" },
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "onsetGlaze",
            lazy = false,
            name = "onsetGlaze",
        },
    },

    install = { colorscheme = { "tokyonight", "habamax" } },
    -- Configure LazyVim to load gruvbox
    --
}
