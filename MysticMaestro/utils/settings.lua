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
				confirmList = {
					order = 1,
					name = "Confirm Listing",
					desc = "Enables a confirmation before making a listing.",
					type = "toggle"
				},
				confirmBuyout = {
					order = 2,
					name = "Confirm Buyout",
					desc = "Enables a confirmation before buying an auction.",
					type = "toggle"
				},
				confirmCancel = {
					order = 3,
					name = "Confirm Cancel",
					desc = "Enables a confirmation before canceling your auction.",
					type = "toggle"
				},
      }
    },
    scan={
      name = "Scan",
      type = "group",
      args={
				rarityHeader = {
					order = 1,
					name = "Included rarities in full scan",
					type = "header"
				},
				rarityMagic = {
					order = 2,
					name = "Uncommon",
					desc = "Include Uncommon enchants during full scan.",
					type = "toggle"
				},
				rarityRare = {
					order = 3,
					name = "Rare",
					desc = "Include Rare enchants during full scan.",
					type = "toggle"
				},
				rarityEpic = {
					order = 4,
					name = "Epic",
					desc = "Include Epic enchants during full scan.",
					type = "toggle"
				},
				rarityLegendary = {
					order = 5,
					name = "Legendary",
					desc = "Include Legendary enchants during full scan.",
					type = "toggle"
				},
      }
    }
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Mystic Maestro")