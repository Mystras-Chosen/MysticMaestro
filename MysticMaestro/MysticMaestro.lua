local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local MM = AceAddon:NewAddon("MysticMaestro", "AceConsole-3.0")
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

MM:RegisterChatCommand("mm","OpenMenu")