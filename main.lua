local mod = RegisterMod("Whats My DPS [Fixed]", 1)
WhatsMyDPSFixed = mod
mod.VersionString = "1.0"

local json = require("json")

-- 状态
local dataTable
local screenSize
local totalDamage = 0
local frames = 0
local seconds = 0

-- 设置默认值
local defaultSettings = {
  ShowDPSAboveIsaac = false,
  ShowDPSInStats = true,
  ShowAdditionalStats = true,
  HudOpacity = 0.4,
  DisplayLanguage = "Auto",
}

local opacitySteps = {0.1, 0.175, 0.25, 0.3, 0.4, 0.5, 0.6, 0.75, 0.8, 0.9, 1}

local textTable = {
  en = {
    ["Total Damage"] = "Total Damage",
    ["Functional DPS"] = "Functional DPS",
    ["DPS"] = "DPS",
  },
  zh = {
    ["Total Damage"] = "总伤害",
    ["Functional DPS"] = "理论DPS",
    ["DPS"] = "DPS",
  },
}

mod.Settings = mod.Settings or {}

-- 存档读写
local function saveDataTable(tbl)
  local data = json.encode(tbl)
  mod:SaveData(data)
end

local function loadDataTable()
  if mod:HasData() then
    local raw = mod:LoadData()
    if raw ~= nil and raw ~= "" then
      local ok, decoded = pcall(json.decode, raw)
      if ok and type(decoded) == "table" then
        return decoded
      end
    end
  end

  return {}
end

-- 语言
local function GetRuntimeLanguage()
  if mod.Settings.DisplayLanguage == "Auto" then
    local MCM = ModConfigMenu
    if MCM ~= nil and MCM.i18n == "Chinese" then
      return "zh"
    end
    return "en"
  end

  if mod.Settings.DisplayLanguage == "中文" then
    return "zh"
  end

  return "en"
end

local function T(key)
  local lang = GetRuntimeLanguage()
  if textTable[lang] and textTable[lang][key] then
    return textTable[lang][key]
  end
  return textTable.en[key] or key
end

-- 字体
local function GetCurrentModPath()
  if debug then
    local source = string.gsub(debug.getinfo(GetCurrentModPath).source, "^@", "")
    source = string.gsub(source, "\\", "/")
    return string.gsub(source, "[^/]+$", "")
  end

  -- 回退
  local _, err = pcall(require, "")
  local _, basePathStart = string.find(err, "no file '", 1)
  local _, modPathStart = string.find(err, "no file '", basePathStart)
  local modPathEnd, _ = string.find(err, ".lua'", modPathStart)
  local modPath = string.sub(err, modPathStart + 1, modPathEnd - 1)
  modPath = string.gsub(modPath, "\\", "/")
  return modPath
end

-- 中英文使用同一款字体
-- 在加载时缓存本 mod 的路径
local modPath = GetCurrentModPath()

local hudFont

local function LoadHudFont()
  local font = Font()
  local fontPath = modPath .. "resources/font/pftempestasevencondensed.fnt"
  font:Load(fontPath)

  if not font:IsLoaded() then
    print("[WhatsMyDPSFixed] font load failed: " .. fontPath)
  end

  if font:IsLoaded() then
    font:SetMissingCharacter(2)
    return font
  end

  return nil
end

local function GetHudFont()
  if hudFont == nil then
    hudFont = LoadHudFont()
  end
  return hudFont
end

-- 设置规范化与持久化
local function NormalizeSettings(source)
  local merged = {}

  for key, value in pairs(defaultSettings) do
    if source ~= nil and source[key] ~= nil then
      merged[key] = source[key]
    else
      merged[key] = value
    end
  end

  if type(merged.ShowDPSAboveIsaac) ~= "boolean" then
    merged.ShowDPSAboveIsaac = defaultSettings.ShowDPSAboveIsaac
  end
  if type(merged.ShowDPSInStats) ~= "boolean" then
    merged.ShowDPSInStats = defaultSettings.ShowDPSInStats
  end
  if type(merged.ShowAdditionalStats) ~= "boolean" then
    merged.ShowAdditionalStats = defaultSettings.ShowAdditionalStats
  end
  if type(merged.DisplayLanguage) ~= "string" then
    merged.DisplayLanguage = defaultSettings.DisplayLanguage
  end
  if merged.DisplayLanguage ~= "Auto" and merged.DisplayLanguage ~= "English" and merged.DisplayLanguage ~= "中文" then
    -- 不符合当前格式的旧存档值直接恢复默认
    merged.DisplayLanguage = defaultSettings.DisplayLanguage
  end
  if type(merged.HudOpacity) ~= "number" then
    merged.HudOpacity = defaultSettings.HudOpacity
  end
  if merged.HudOpacity < opacitySteps[1] then
    merged.HudOpacity = opacitySteps[1]
  end
  if merged.HudOpacity > opacitySteps[#opacitySteps] then
    merged.HudOpacity = opacitySteps[#opacitySteps]
  end

  return merged
end

local function SyncMenuConfig()
  if ModConfigMenu == nil or ModConfigMenu.Config == nil then
    return
  end

  ModConfigMenu.Config["Whats My DPS [Fixed]"] = ModConfigMenu.Config["Whats My DPS [Fixed]"] or {}

  for key, value in pairs(defaultSettings) do
    if mod.Settings[key] ~= nil then
      ModConfigMenu.Config["Whats My DPS [Fixed]"][key] = mod.Settings[key]
    end
  end
end

function LoadSettings()
  dataTable = loadDataTable()
  mod.Settings = NormalizeSettings(dataTable)
  SyncMenuConfig()
  return mod.Settings
end

function SaveSettings()
  mod.Settings = NormalizeSettings(mod.Settings)
  dataTable = mod.Settings
  saveDataTable(dataTable)
  SyncMenuConfig()
end

-- 配置持久化：游戏开始加载配置，退出游戏时再保存一次
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, LoadSettings)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveSettings)

-- 公开访问器
function mod:GetShowDPSAboveIsaac()
  return self.Settings.ShowDPSAboveIsaac
end

function mod:GetShowDPSInStats()
  return self.Settings.ShowDPSInStats
end

function mod:GetShowAdditionalStats()
  return self.Settings.ShowAdditionalStats
end

function mod:GetHudOpacity()
  return self.Settings.HudOpacity
end

function mod:SetShowDPSAboveIsaac(value)
  self.Settings.ShowDPSAboveIsaac = value
  SaveSettings()
end

function mod:SetShowDPSInStats(value)
  self.Settings.ShowDPSInStats = value
  SaveSettings()
end

function mod:SetShowAdditionalStats(value)
  self.Settings.ShowAdditionalStats = value
  SaveSettings()
end

function mod:SetHudOpacity(value)
  self.Settings.HudOpacity = value
  SaveSettings()
end

-- 伤害统计
function ToFixed(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function mod:Timer()
  if not Game():IsPaused() then
    -- The game runs at a locked 60fps, so we can calculate the time based on the number of frames that have passed
    -- 游戏以 60fps 锁帧运行，所以我们可以根据经过的帧数来计算时间
    frames = frames + 1

    -- Reset the timer every second
    -- 每秒重置一次计时器
    if frames % 60 == 0 then
      seconds = seconds + 1
      frames = 0
    end
  end
end

function mod:Reset()
  frames = 0
  seconds = 0
  totalDamage = 0
end

function mod:OnDamageHit(target, amount, source, _dealer)
  if (
      source == 0 or
      -- 这个条件用来计算硫磺火等激光伤害；同时也会计算非以撒造成的激光伤害，但我们需要接受这个限制
      -- This will also count other lasers that do not come from Isaac, but we will just have to live with it
      source == DamageFlag.DAMAGE_LASER or
      -- 这个条件用来计算爆炸伤害；同时也会计算非以撒造成的爆炸伤害，但我们需要接受这个限制
      -- Also counts explosions from other sources, but again, we will just have to live with it
      source == DamageFlag.DAMAGE_EXPLOSION
    ) and -- If the player caused the damage / 如果伤害是由玩家造成的
    target:IsActiveEnemy() and -- If the target entity is an enemy NPC / 如果目标是敌对 NPC
    not target:IsInvincible() then
    totalDamage = ToFixed(totalDamage + amount, 2)
  end
end

-- Get the number to subtract from the G and B values (1 is the max, the range is 0 - 1)
-- 获取要从 RGB 中的 G 和 B 值中减去的数字（1 是最大值，范围是 0 - 1）
function GetColorSubtraction(damage)
  -- Scale a damage range of 10 - 100 to a color range of 0 - 1
  -- 将 10 - 100 的伤害范围按比例映射到 0 - 1 的颜色范围
  local colorSub = (damage - 10) / 90

  if colorSub < 0 then
    return 0
  end

  return colorSub
end

-- Get actual DPS
-- 获取实测的 DPS
function CalculateDPS()
  if seconds == 0 or totalDamage == 0 then
    return 0
  end

  return ToFixed(totalDamage / seconds, 2)
end

-- This function calculates the player's "functional" DPS based on their Damage and Fire Rate stat.
-- It does NOT account for things like poison, bomb damage, etc.
-- 这个函数根据玩家的攻击力和射速属性计算"理论" DPS。它不计入毒伤、炸弹伤害等额外加成。
function FunctionalDPS()
  -- This is not the fire rate, but rather the delay in between each shot. The lower the number, the faster the fire rate
  -- 这并非攻速属性，而是每次射击之间的间隔（延迟）。数值越低，攻击频率越快。
  local firedelay = 30 / (Isaac.GetPlayer(0).MaxFireDelay + 1)
  local damage = Isaac.GetPlayer(0).Damage

  return ToFixed(damage * firedelay, 2)
end

-- 渲染
function mod:Render()
  if screenSize == nil then
    screenSize = (Isaac.WorldToScreen(Vector(320, 280)) - Game():GetRoom():GetRenderScrollOffset() - Game().ScreenShakeOffset) * 2
  end

  local dps = CalculateDPS()
  local functionalDPS = FunctionalDPS()
  local dpsColorSub = GetColorSubtraction(dps)
  local fDPSColorSub = GetColorSubtraction(functionalDPS)
  local hudOpacity = mod.Settings.HudOpacity

  local font = GetHudFont()
  if font == nil then
    return
  end

  -- X 文字左对齐
  local textScale = 0.8
  local leftEdgeX = 8 + Options.HUDOffset * 20

  local function drawStatsLine(text, y, color)
    font:DrawStringScaledUTF8(text, leftEdgeX, y, textScale, textScale, color)
  end

  if mod.Settings.ShowAdditionalStats then
    drawStatsLine(T("Total Damage") .. ": " .. totalDamage, screenSize.Y - 30, KColor(1, 1, 1, hudOpacity))
    drawStatsLine(T("Functional DPS") .. ": " .. functionalDPS, screenSize.Y - 40, KColor(1, 1 - fDPSColorSub, 1 - fDPSColorSub, hudOpacity))
  end

  -- Draw the DPS on top of Isaac's head
  -- 在角色头顶绘制 DPS
  local p = Isaac.GetPlayer(0).Position
  local room = Game():GetRoom()
  local px = room:WorldToScreenPosition(p).X
  local py = room:WorldToScreenPosition(p).Y

  if mod.Settings.ShowDPSAboveIsaac then
    -- px - 10 is a weird offset, but it works
    -- px - 10 这个偏移量有点奇怪，但能用
    font:DrawStringUTF8(tostring(dps), px - 10, py - 40, KColor(1, 1 - dpsColorSub, 1 - dpsColorSub, hudOpacity), 20, true)
  end

  if mod.Settings.ShowDPSInStats then
    drawStatsLine(T("DPS") .. ": " .. tostring(dps), screenSize.Y - 60, KColor(1, 1 - dpsColorSub, 1 - dpsColorSub, hudOpacity))
  end
end

-- 回调注册
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamageHit)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.Render)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.Timer)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.Reset)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.Reset)

LoadSettings()

if ModConfigMenu ~= nil then
  require("menu_config")
end
