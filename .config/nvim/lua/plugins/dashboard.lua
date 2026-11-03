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

      -- ── 标题：LIMEVANILLA，每个字母一种颜色 ─────────────────────────────
      -- 5×5 点阵字模（只列用得到的字母），每个字形 5 列宽、5 行高
      local glyphs = {
        L = { "█    ", "█    ", "█    ", "█    ", "█████" },
        I = { "█████", "  █  ", "  █  ", "  █  ", "█████" },
        M = { "█   █", "██ ██", "█ █ █", "█   █", "█   █" },
        E = { "█████", "█    ", "████ ", "█    ", "█████" },
        V = { "█   █", "█   █", "█   █", " █ █ ", "  █  " },
        A = { " ███ ", "█   █", "█████", "█   █", "█   █" },
        N = { "█   █", "██  █", "█ █ █", "█  ██", "█   █" },
      }

      -- Catppuccin Mocha 里挑 11 个颜色，按字母顺序分配
      local logo_colors = {
        "#89b4fa", -- blue
        "#74c7ec", -- sapphire
        "#94e2d5", -- teal
        "#a6e3a1", -- green
        "#f9e2af", -- yellow
        "#fab387", -- peach
        "#eba0ac", -- maroon
        "#f38ba8", -- red
        "#cba6f7", -- mauve
        "#f5c2e7", -- pink
        "#f2cdcd", -- flamingo
      }

      local word = "LIMEVANILLA"
      local rows = #glyphs.L
      local sep = " "

      for i, color in ipairs(logo_colors) do
        vim.api.nvim_set_hl(0, "AlphaLogo" .. i, { fg = color })
      end

      -- 逐行拼字，并按「字节列」算出每个字母的高亮区间
      -- alpha 的高亮格式：hl[行] = { { 组名, 起始字节列, 结束字节列 }, ... }
      local logo_lines = {}
      local logo_hl = {}
      for row = 1, rows do
        local cells, sections = {}, {}
        local col = 0
        for i = 1, #word do
          local glyph = glyphs[word:sub(i, i)][row]
          cells[#cells + 1] = glyph
          sections[#sections + 1] = {
            "AlphaLogo" .. ((i - 1) % #logo_colors + 1),
            col,
            col + #glyph,
          }
          col = col + #glyph + #sep
        end
        logo_lines[row] = table.concat(cells, sep)
        logo_hl[row] = sections
      end

      dashboard.config.layout = {
        { type = "padding", val = 10 },
        dashboard.section.header,
        { type = "padding", val = 3 },
        dashboard.section.buttons,
        { type = "padding", val = 2 },
        dashboard.section.footer,
      }

      dashboard.section.header.val = logo_lines
      dashboard.section.header.opts.hl = logo_hl

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

      -- 底部：插件加载耗时（每次重绘都重新取，避免停留旧数字）
      dashboard.section.footer.val = function()
        local ok, lazy = pcall(require, "lazy")
        if not ok then
          return "LIMEVANILLA"
        end
        local stats = lazy.stats()
        return string.format(
          "⚡ %d 个插件 · 加载耗时 %.2f ms",
          stats.loaded or 0,
          stats.startuptime or 0
        )
      end

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

      vim.api.nvim_set_hl(0, "AlphaFooter", {
        fg = "#7f849c",
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
