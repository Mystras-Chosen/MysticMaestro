local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local MM = AceAddon:NewAddon("MysticMaestro", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceBucket-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local myOptionsTable = {
  name = "Mystic Maestro",
  handler = MM,
  type = "group",
  args = {
    enable = {
      name = "Enable",
      desc = "Enables / disables the addon",
      type = "toggle",
      set = function(info, val)
        MM.enabled = val
      end,
      get = function(info)
        return MM.enabled
      end
    }
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)

local defaults = {
  profile = {
    optionA = true,
    optionB = false,
    suboptions = {
      subOptionA = false,
      subOptionB = true
    }
  }
}

local GetSpellInfo = GetSpellInfo

local enchantMT = {
  __index = function(t, k)
    local newListing = {}
    t[k] = newListing
    return newListing
  end
}

function MM:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MysticMaestroDB")
  self.db.realm.RE_AH_LISTINGS = setmetatable(self.db.realm.RE_AH_LISTINGS or {}, enchantMT)
  self.db.realm.RE_AH_STATISTICS = setmetatable(self.db.realm.RE_AH_STATISTICS or {}, enchantMT)
  self.db.realm.FAVORITE_ENCHANTS = self.db.realm.FAVORITE_ENCHANTS or {}
  MM:RegisterMessage("ASC_COLLECTION_RE_UNLOCKED")
end

function MM:OnEnable()
  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")
end

function MM:ProcessSlashCommand(input)
  local lowerInput = input:lower()
  if lowerInput:match("^fullscan$") then
    MM:HandleFullScan()
  elseif lowerInput:match("^scan") then
    MM:HandleScan(input:match("^%w+%s+(.+)"))
  elseif lowerInput:match("^calc") then
    MM:CalculateAllStats()
  elseif input == "" then
    MM:HandleMenuSlashCommand()
  else
    MM:Print("Command not recognized")
    MM:Print("Valid input is scan, fullscan, calc")
    MM:Print("Scan Rarity includes all, uncommon, rare, epic, legendary")
  end
end

MM:RegisterChatCommand("mm", "ProcessSlashCommand")

MM.RE_LOOKUP = {}
MM.RE_NAMES = {}
MM.RE_ID = {}
for k, v in pairs(MYSTIC_ENCHANTS) do
  if v.spellID ~= 0 then
    local enchantName = GetSpellInfo(v.spellID)
    MM.RE_LOOKUP[enchantName] = v.enchantID
    MM.RE_NAMES[v.enchantID] = enchantName
    if v.spellID ~= v.enchantID then
      MM.RE_ID[v.spellID] = v.enchantID
    end
  end
end