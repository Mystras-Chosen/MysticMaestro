local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local MM = AceAddon:NewAddon("MysticMaestro", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

local myOptionsTable = {
	name = "Mystic Maestro",
	handler = MM,
  type = "group",
  args = {
    enable = {
      name = "Enable",
      desc = "Enables / disables the addon",
      type = "toggle",
      set = function(info,val) MM.enabled = val end,
      get = function(info) return MM.enabled end
    } --,
    -- moreoptions={
    --   name = "More Options",
    --   type = "group",
    --   args={
    --     -- more options go here
    --   }
    -- }
  }
}

function MM:OpenMenu()
	if UnitAffectingCombat("player") then
			if Dialog.OpenFrames["Mystic Maestro"] then
					Dialog:Close("Mystic Maestro")
			end
			return
	end

	if Dialog.OpenFrames["Mystic Maestro"] then
			Dialog:Close("Mystic Maestro")
	else
			Dialog:Open("Mystic Maestro")
	end
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro",myOptionsTable)

--MM:RegisterChatCommand("mm","OpenMenu")

local defaults = {
  profile = {
    optionA = true,
    optionB = false,
    suboptions = {
      subOptionA = false,
      subOptionB = true,
    },
  }
}


function MM:RefreshConfig()
  -- would do some stuff here
end







local MYSTIC_ENCHANTS = MYSTIC_ENCHANTS

local enchantMT = {
  __index = function(t, k)
    return t[MYSTIC_ENCHANTS[k].spellName]
  end
}

local function cleanEnchantSpellName(spellName)
  if spellName:find("Effect$") and spellName ~= "Mpemba Effect" then
    return spellName:match("(.-) Effect$")
  end
  return spellName
end

local function initializeDB()
  local listings = {}
  local stats = {}
  for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
    local spellName = cleanEnchantSpellName(enchantData.spellName)
    listings[spellName] = {}
    stats[spellName] = {}
  end
  return listings, stats
end

local function injectDB(listings, statistics)
  for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
    local spellName = cleanEnchantSpellName(enchantData.spellName)
    if listings[spellName] == nil then
      listings[spellName] = {}
      statistics[spellName] = {}
    end
  end
end

function MM:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MysticMaestroDB")
  if not self.db.realm.RE_AH_LISTINGS then
    self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS = initializeDB()
  else
    injectDB(self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS)
  end
  setmetatable(self.db.realm.RE_AH_LISTINGS, enchantMT)
  setmetatable(self.db.realm.RE_AH_STATISTICS, enchantMT)
end

function MM:ProcessSlashCommand(input)
  input = input:lower()
  if input:match("^fullscan$") then
    MM:HandleFullScan()
  elseif input:match("^slowscan$") then
    MM:HandleSlowScan()
  else
    MM:Print("Command not recognized")
  end
end

MM:RegisterChatCommand("mm","ProcessSlashCommand")