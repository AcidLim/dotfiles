return {
  {
    "goolord/alpha-nvim",

    event = "VimEnter",

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    config = function()

      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.config.layout = {
        { type = "padding", val = 12 },
        dashboard.section.header,
        { type = "padding", val = 4 },
        dashboard.section.buttons,
        { type = "padding", val = 2 },
        dashboard.section.footer,
      }

      -- 标题
      dashboard.section.header.val = {
        "",
        "██╗   ██╗ ██████╗  ██████╗ ██╗  ██╗██╗██╗     ███████╗███╗   ██╗",
        "╚██╗ ██╔╝██╔═══██╗██╔═══██╗╚██╗██╔╝██║██║     ██╔════╝████╗  ██║",
        " ╚████╔╝ ██║   ██║██║   ██║ ╚███╔╝ ██║██║     █████╗  ██╔██╗ ██║",
        "  ╚██╔╝  ██║   ██║██║   ██║ ██╔██╗ ██║██║     ██╔══╝  ██║╚██╗██║",
        "   ██║   ╚██████╔╝╚██████╔╝██╔╝ ██╗██║███████╗███████╗██║ ╚████║",
        "   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝",
        "",
      }

      -- 横向渐变
      local header_length = 72

      dashboard.section.header.opts.hl = {
        { "AlphaBlue", 0, 0, 0, 18 },
        { "AlphaSapphire", 0, 0, 18, 36 },
        { "AlphaMauve", 0, 0, 36, 54 },
        { "AlphaPink", 0, 0, 54, 72 },

        { "AlphaBlue", 1, 1, 0, 18 },
        { "AlphaSapphire", 1, 1, 18, 36 },
        { "AlphaMauve", 1, 1, 36, 54 },
        { "AlphaPink", 1, 1, 54, 72 },

        { "AlphaBlue", 2, 2, 0, 18 },
        { "AlphaSapphire", 2, 2, 18, 36 },
        { "AlphaMauve", 2, 2, 36, 54 },
        { "AlphaPink", 2, 2, 54, 72 },

        { "AlphaBlue", 3, 3, 0, 18 },
        { "AlphaSapphire", 3, 3, 18, 36 },
        { "AlphaMauve", 3, 3, 36, 54 },
        { "AlphaPink", 3, 3, 54, 72 },

        { "AlphaBlue", 4, 4, 0, 18 },
        { "AlphaSapphire", 4, 4, 18, 36 },
        { "AlphaMauve", 4, 4, 36, 54 },
        { "AlphaPink", 4, 4, 54, 72 },

        { "AlphaBlue", 5, 5, 0, 18 },
        { "AlphaSapphire", 5, 5, 18, 36 },
        { "AlphaMauve", 5, 5, 36, 54 },
        { "AlphaPink", 5, 5, 54, 72 },
      }


      -- 快捷按钮
      dashboard.section.buttons.val = {

        dashboard.button(
          "e",
          "  新建文件",
          ":ene <BAR> startinsert <CR>"
        ),

        dashboard.button(
          "f",
          "󰱼  查找文件",
          ":Telescope find_files<CR>"
        ),

        dashboard.button(
          "r",
          "󰄉  最近文件",
          ":Telescope oldfiles<CR>"
        ),

        dashboard.button(
          "g",
          "󰊢  Git 文件",
          ":Telescope git_files<CR>"
        ),

        dashboard.button(
          "l",
          "󰒲  插件管理",
          ":Lazy<CR>"
        ),

        dashboard.button(
          "q",
          "󰅚  退出",
          ":qa<CR>"
        ),

      }


      -- 底部信息
      dashboard.section.footer.val = {
        "󰣇 CachyOS  •  󰍹 Niri  •  󰘧 Yooxilen",
      }


      -- Catppuccin Mocha 配色
      vim.api.nvim_set_hl(0, "AlphaHeader", {
        fg = "#89b4fa",
      })

      vim.api.nvim_set_hl(0, "AlphaBlue", {
        fg = "#89b4fa",
      })

      vim.api.nvim_set_hl(0, "AlphaSapphire", {
        fg = "#74c7ec",
      })

      vim.api.nvim_set_hl(0, "AlphaMauve", {
        fg = "#cba6f7",
      })

      vim.api.nvim_set_hl(0, "AlphaPink", {
        fg = "#f5c2e7",
      })

      vim.api.nvim_set_hl(0, "AlphaPeach", {
        fg = "#fab387",
      })


      -- 透明背景
      vim.cmd([[
        hi AlphaHeader guibg=NONE
        hi AlphaButtons guibg=NONE
        hi AlphaShortcut guibg=NONE
        hi AlphaFooter guibg=NONE
      ]])


      alpha.setup(dashboard.config)

    end,
  },
}