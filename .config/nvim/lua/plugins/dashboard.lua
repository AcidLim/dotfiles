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

      -- ── 标题：LIMEVANILLA，figlet "big" 风格，逐字母上色 ─────────────────
      -- 字模只写需要的字母；行尾空格不用手写，下面按显示宽度自动补齐
      local glyphs = {
        L = { "██╗", "██║", "██║", "██║", "███████╗", "╚══════╝" },
        I = { "██╗", "██║", "██║", "██║", "██║", "╚═╝" },
        M = {
          "███╗   ███╗",
          "████╗ ████║",
          "██╔████╔██║",
          "██║╚██╔╝██║",
          "██║ ╚═╝ ██║",
          "╚═╝     ╚═╝",
        },
        E = { "███████╗", "██╔════╝", "█████╗", "██╔══╝", "███████╗", "╚══════╝" },
        V = {
          "██╗   ██╗",
          "██║   ██║",
          "██║   ██║",
          "╚██╗ ██╔╝",
          " ╚████╔╝",
          "  ╚═══╝",
        },
        A = { " █████╗", "██╔══██╗", "███████║", "██╔══██║", "██║  ██║", "╚═╝  ╚═╝" },
        N = {
          "███╗   ██╗",
          "████╗  ██║",
          "██╔██╗ ██║",
          "██║╚██╗██║",
          "██║ ╚████║",
          "╚═╝  ╚═══╝",
        },
      }

      -- 按显示宽度把每个字形补齐成等宽
      local function pad_glyph(rows)
        local width = 0
        for _, row in ipairs(rows) do
          width = math.max(width, vim.fn.strdisplaywidth(row))
        end
        for i, row in ipairs(rows) do
          rows[i] = row .. string.rep(" ", width - vim.fn.strdisplaywidth(row))
        end
        return rows
      end

      for _, rows in pairs(glyphs) do
        pad_glyph(rows)
      end

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

      -- ── 时间问候 ────────────────────────────────────────────────────────
      local function greeting()
        local hour = tonumber(os.date("%H")) or 0
        local who = vim.env.USER or "you"
        local text
        if hour < 5 then
          text = "夜深了"
        elseif hour < 11 then
          text = "早上好"
        elseif hour < 13 then
          text = "中午好"
        elseif hour < 18 then
          text = "下午好"
        else
          text = "晚上好"
        end
        return string.format("%s，%s", text, who)
      end

      -- ── 会话保存 / 恢复（不依赖额外插件，用内置 :mksession）─────────────
      local function session_file()
        return vim.fn.stdpath("state") .. "/session.vim"
      end

      local function save_session()
        -- 只剩 dashboard 这种空 buffer 时没必要存
        local has_content = false
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if
            vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].buftype == ""
            and vim.api.nvim_buf_get_name(buf) ~= ""
          then
            has_content = true
            break
          end
        end
        if not has_content then
          return
        end
        vim.fn.mkdir(vim.fn.stdpath("state"), "p")
        vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file()))
      end

      local function restore_session()
        local file = session_file()
        if vim.fn.filereadable(file) == 1 then
          vim.cmd("silent! source " .. vim.fn.fnameescape(file))
        else
          vim.notify("还没有保存过会话", vim.log.levels.WARN)
        end
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("dashboard_session", { clear = true }),
        callback = save_session,
      })

      -- 布局稍后拼（最近文件那块要按有无决定是否加入）
      dashboard.section.header.val = logo_lines
      dashboard.section.header.opts.hl = logo_hl

      -- ── 按钮 ────────────────────────────────────────────────────────────
      local buttons = {

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
          "s",
          "󰆓  恢复上次会话",
          restore_session
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

      -- ── 最近文件：取 v:oldfiles 里仍然存在的前 5 个 ─────────────────────
      local recent_buttons = {}
      do
        local devicons = require("nvim-web-devicons")
        local seen = {}
        for _, file in ipairs(vim.v.oldfiles) do
          if #recent_buttons >= 5 then
            break
          end
          if file:sub(1, 4) ~= "term" and vim.fn.filereadable(file) == 1 and not seen[file] then
            seen[file] = true

            local name = vim.fn.fnamemodify(file, ":t")
            local dir = vim.fn.fnamemodify(file, ":h:t")
            local icon = devicons.get_icon(name, vim.fn.fnamemodify(file, ":e"), { default = true })
              or "󰈔"

            local label = string.format("%s  %s", icon, name)
            if dir ~= "" and dir ~= "." and dir ~= "~" then
              label = string.format("%s  %s/", label, dir)
            end
            label = vim.fn.strcharpart(label, 0, 34)

            local item = dashboard.button(
              tostring(#recent_buttons + 1),
              label,
              ":edit " .. vim.fn.fnameescape(file) .. "<CR>"
            )
            -- 最近文件比主按钮暗一点，读起来有层级
            item.opts.hl = "AlphaRecent"

            recent_buttons[#recent_buttons + 1] = item
          end
        end
      end

      dashboard.section.buttons.val = buttons

      -- ── 组装布局 ────────────────────────────────────────────────────────
      -- 小节标题：── 最近文件 ──（按显示宽度居中，CJK 也算 2 列）
      local function section_title(text)
        local label = "  " .. text .. "  "
        local width = 44
        local pad = math.max(2, math.floor((width - vim.fn.strdisplaywidth(label)) / 2))
        return string.rep("─", pad) .. label .. string.rep("─", pad)
      end

      -- 先排内容，最后按窗口高度补「顶部留白」，
      -- 免得底部那行耗时被顶到屏幕外面、还要翻页才看得到
      local body = {
        dashboard.section.header,
        { type = "padding", val = 2 },
        {
          type = "text",
          val = greeting,
          opts = { position = "center", hl = "AlphaGreeting" },
        },
        { type = "padding", val = 2 },
        dashboard.section.buttons,
      }

      -- 没有最近文件就整块（标题 + 分隔 + 列表）都不出现
      if #recent_buttons > 0 then
        body[#body + 1] = { type = "padding", val = 2 }
        body[#body + 1] = {
          type = "text",
          val = section_title("最近文件"),
          opts = { position = "center", hl = "AlphaSection" },
        }
        body[#body + 1] = { type = "padding", val = 1 }
        body[#body + 1] = {
          type = "group",
          val = recent_buttons,
          opts = { spacing = 1 },
        }
      end

      body[#body + 1] = { type = "padding", val = 1 }
      body[#body + 1] = dashboard.section.footer

      -- 估算每块占几行（padding/text/group/button）
      local function element_height(el)
        if el.type == "padding" then
          return el.val or 0
        elseif el.type == "text" then
          local val = el.val
          if type(val) == "function" then
            local ok, res = pcall(val)
            val = ok and res or ""
          end
          if type(val) == "table" then
            return #val
          end
          return 1
        elseif el.type == "group" then
          local spacing = (el.opts and el.opts.spacing) or 0
          local height = 0
          for _, child in ipairs(el.val) do
            height = height + element_height(child) + spacing
          end
          return height
        elseif el.type == "button" then
          return 1
        end
        return 0
      end

      local content_height = 0
      for _, el in ipairs(body) do
        content_height = content_height + element_height(el)
      end

      -- 放得下时留一点上边距（最多 8 行，且偏上），放不下就贴顶
      local available = vim.o.lines - vim.o.cmdheight
      local slack = math.max(0, available - content_height)
      local top = math.min(8, math.max(1, math.floor(slack / 2)))

      local layout = { { type = "padding", val = top } }
      vim.list_extend(layout, body)

      dashboard.config.layout = layout

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

      vim.api.nvim_set_hl(0, "AlphaGreeting", {
        fg = "#7f849c",
      })

      -- 小节标题（── 最近文件 ──）
      vim.api.nvim_set_hl(0, "AlphaSection", {
        fg = "#6c7086",
      })

      -- 最近文件的条目，比主按钮暗一档
      vim.api.nvim_set_hl(0, "AlphaRecent", {
        fg = "#9399b2",
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
