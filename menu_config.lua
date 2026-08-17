-- Whats My DPS [Fixed] - Mod Config Menu

local mod = WhatsMyDPSFixed
local MCM = ModConfigMenu
local categoryName = "Whats My DPS [Fixed]"
local subcategory = "Settings"

if mod and MCM then
  local opacitySteps = {0.1, 0.175, 0.25, 0.3, 0.4, 0.5, 0.6, 0.75, 0.8, 0.9, 1}
  local languageOptions = {"Auto", "English", "中文"}

  -- 信息页
  MCM.SetCategoryInfo(categoryName, "Shows your real-time DPS in game.")
  MCM.AddSpace(categoryName, "Info")
  MCM.AddText(categoryName, "Info", "Whats My DPS [Fixed]")
  MCM.AddSpace(categoryName, "Info")
  MCM.AddText(categoryName, "Info", function()
    return "Version " .. mod.VersionString
  end)
  MCM.AddSpace(categoryName, "Info")
  MCM.AddText(categoryName, "Info", "By Lulo")
  MCM.AddSpace(categoryName, "Info")
  MCM.AddText(categoryName, "Info", "Original author: SpikeHD")

  -- 辅助函数
  local function getOpacityIndex()
    local current = mod.Settings.HudOpacity or 0.4
    for i, value in ipairs(opacitySteps) do
      if math.abs(current - value) < 0.0001 then
        return i - 1
      end
    end
    return 4
  end

  local function getLanguageIndex()
    local current = mod.Settings.DisplayLanguage or "Auto"
    for i, value in ipairs(languageOptions) do
      if current == value then
        return i - 1
      end
    end
    return 0
  end

  -- 当前实际生效的语言名称（用该语言自己的名称）
  local function getCurrentLanguageName()
    if MCM.i18n == "Chinese" then
      return "中文"
    end
    if MCM.i18n == "English" then
      return "English"
    end
    return MCM.i18n or "English"
  end

  local function getLanguageLabel()
    local current = mod.Settings.DisplayLanguage or "Auto"
    if current == "Auto" then
      -- 自动：括号内显示当前实际生效的语言。
      -- 中文模式 "Auto(中文)"，其他语言 "Auto (English)"。
      if MCM.i18n == "Chinese" then
        return "Auto(" .. getCurrentLanguageName() .. ")"
      end
      return "Auto (" .. getCurrentLanguageName() .. ")"
    end
    -- 直接显示选项自身的名称
    return current
  end

  local function addBooleanOption(key, defaultValue, label, infoText)
    MCM.AddSetting(categoryName, subcategory, {
      Type = MCM.OptionType.BOOLEAN,
      Default = defaultValue,
      CurrentSetting = function()
        return mod.Settings[key]
      end,
      Display = function()
        return label .. ": " .. (mod.Settings[key] and "On" or "Off")
      end,
      OnChange = function(value)
        mod.Settings[key] = value
        SaveSettings()
      end,
      Info = { infoText },
    })
  end

  -- 设置页
  addBooleanOption("ShowDPSAboveIsaac", false, "Show DPS Above Isaac", "Display the current DPS over Isaac's head.")
  addBooleanOption("ShowDPSInStats", false, "Show DPS in stats side area", "Display the DPS in the stats side area.")
  addBooleanOption("ShowAdditionalStats", true, "Show additional stats in bottom left", "Display the extra total damage and functional DPS info in the bottom left.")

  MCM.AddSpace(categoryName, subcategory)

  -- 语言
  MCM.AddSetting(categoryName, subcategory, {
    Type = MCM.OptionType.NUMBER,
    Minimum = 0,
    Maximum = #languageOptions - 1,
    ModifyBy = 1,
    Default = 0,
    CurrentSetting = function()
      return getLanguageIndex()
    end,
    Display = function()
      return "Language: " .. getLanguageLabel()
    end,
    OnChange = function(value)
      mod.Settings.DisplayLanguage = languageOptions[value + 1] or "Auto"
      SaveSettings()
    end,
    Info = { "Choose the display language. Auto uses the menu language." },
  })

  -- 不透明度
  MCM.AddSetting(categoryName, subcategory, {
    Type = MCM.OptionType.SCROLL,
    Default = getOpacityIndex(),
    CurrentSetting = function()
      return getOpacityIndex()
    end,
    Display = function()
      return "Opacity: $scroll" .. tostring(getOpacityIndex()) .. " " .. tostring(mod.Settings.HudOpacity)
    end,
    OnChange = function(value)
      mod.Settings.HudOpacity = opacitySteps[value + 1] or 0.4
      SaveSettings()
    end,
    Info = { "Adjust the opacity of the HUD text." },
  })

  -- i18n
  if MCM.i18n == "Chinese" then
    -- 信息页
    MCM.SetSubcategoryNameTranslate(categoryName, "Info", "信息")
    MCM.TranslateOptionsDisplayTextWithTable(categoryName, "Info", {
      ["Whats My DPS [Fixed]"] = "我的DPS是多少?",
      ["By Lulo"] = "作者: Lulo",
      ["Original author: SpikeHD"] = "原作者: SpikeHD",
    })
    MCM.TranslateOptionsDisplayWithTable(categoryName, "Info", {
      { "Version", "版本" },
    })

    -- 设置页
    MCM.SetCategoryNameTranslate(categoryName, "我的DPS是多少?")
    MCM.SetSubcategoryNameTranslate(categoryName, subcategory, "设置")
    MCM.SetCategoryInfoTranslate(categoryName, "在游戏中显示实时 DPS 信息。")
    MCM.TranslateOptionsDisplayWithTable(categoryName, subcategory, {
      { "Show DPS Above Isaac", "在角色头顶显示 DPS" },
      { "Show DPS in stats side area", "在右侧属性栏显示 DPS" },
      { "Show additional stats in bottom left", "在左下角显示额外属性" },
      { "Language", "语言" },
      { "Opacity", "不透明度" },
      { "On", "开" },
      { "Off", "关" },
    })
    MCM.TranslateOptionsInfoTextWithTable(categoryName, subcategory, {
      ["Display the current DPS over Isaac's head."] = "在角色头顶显示当前 DPS。",
      ["Display the DPS in the stats side area."] = "在右侧属性栏显示当前 DPS。",
      ["Display the extra total damage and functional DPS info in the bottom left."] = "在左下角显示总伤害和理论 DPS 等额外信息。",
      ["Choose the display language. Auto uses the menu language."] = "选择界面语言。自动会跟随菜单语言。",
      ["Adjust the opacity of the HUD text."] = "调整 HUD 文字不透明度。",
    })
  end
end
