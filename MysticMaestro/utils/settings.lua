local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local myOptionsTable = {
  name = "Mystic Maestro Options",
  handler = MM,
  type = "group",
	set = function(info,val) MM.db.realm.OPTIONS[info[#info]] = val end,
	get = function(info) return MM.db.realm.OPTIONS[info[#info]] end,
  args = {
    general={
      name = "General",
      type = "group",
      args={
				subGeneral = {
					name = "Tester",
					desc = "Test if this option saves properly",
					type = "toggle"
				}
      }
    },
    scan={
      name = "Scan",
      type = "group",
      args={
				subScan = {
					name = "Tester",
					desc = "Test if this option saves properly",
					type = "toggle"
				}
      }
    }
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Mystic Maestro")