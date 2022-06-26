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







local GetSpellInfo = GetSpellInfo

local enchantMT = {
  __index = function(t, k)
    if type(k) == "number" then
      return t[GetSpellInfo(k)]
    elseif type(k) == "string" then
      local newListing = {}
      t[k] = newListing
      return newListing
    end
  end
}

function MM:InitializeDatabase()
  local listings = {}
  local stats = {}
  for _, enchantData in pairs(MYSTIC_ENCHANTS) do
    local spellID = enchantData.spellID
    if spellID ~= 0 then
      local spellName = GetSpellInfo(spellID)
      listings[spellName] = {}
      stats[spellName] = {}
    end
  end
  self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS = listings, stats
  setmetatable(self.db.realm.RE_AH_LISTINGS, enchantMT)
  setmetatable(self.db.realm.RE_AH_STATISTICS, enchantMT)
end

function MM:InjectDatabase()
  local listings, statistics = self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS
  for _, enchantData in pairs(MYSTIC_ENCHANTS) do
    local spellID = enchantData.spellID
    if spellID ~= 0 then
      local spellName = GetSpellInfo(spellID)
      if listings[spellName] == nil then
        listings[spellName] = {}
        statistics[spellName] = {}
      end
    end
  end
  setmetatable(self.db.realm.RE_AH_LISTINGS, enchantMT)
  setmetatable(self.db.realm.RE_AH_STATISTICS, enchantMT)
end


function MM:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MysticMaestroDB")
  if db.realm.RE_AH_LISTINGS then
    self:InjectDatabase()
  end
end

function MM:ProcessSlashCommand(input)
  local lowerInput = input:lower()
  if lowerInput:match("^fullscan$") then
    MM:HandleFullScan()
  elseif lowerInput:match("^slowscan$") then
    MM:HandleSlowScan()
  elseif lowerInput:match("^graph") then
    MM:HandleGraph(input:match("^%w+%s+(.+)"))
  else
    MM:Print("Command not recognized")
  end
end

MM:RegisterChatCommand("mm","ProcessSlashCommand")