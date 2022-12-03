local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local myOptionsTable = {
  name = "Mystic Maestro",
  handler = MM,
  type = "group",
  args = {
    enable = {
      name = "Enable",
      desc = "Enables / disables the addon",
      type = "toggle",
      set = function(info, val) MM.enabled = val end,
      get = function(info) return MM.enabled end
    },
    moreoptions={
      name = "More Options",
      type = "group",
      args={
				tester = {
					name = "Tester",
					desc = "Test if this option saves properly",
					type = "toggle",
					set = function(info,val) MM.db.realm[info[#info]] = val end,
					get = function(info) return MM.db.realm[info[#info]] end
				}
      }
    }
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Mystic Maestro")