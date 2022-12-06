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
    },
		tooltip={
			name = "Tooltip",
      type = "group",
      args={
				ttKnownIndicator = {
				order = 1,
				name = "Known RE Icon",
				desc = "Add a green or red icon to item names depending on their known status.",
				type = "toggle"
				},
				ttEnable = {
				order = 2,
				name = "Enable Tooltip Info",
				desc = "Enable or disable tooltip information for Mystic Enchants.",
				type = "toggle"
				},
				ttLatestHeader = {
					order = 3,
					name = "Last Scan Values",
					type = "header"
				},
				ttMin = {
					order = 4,
					name = "Show Minimum",
					desc = "Show Minimum value in tooltip",
					type = "toggle"
				},
				ttGPO = {
					order = 5,
					name = "Show Gold Per Orb",
					desc = "Show Gold Per Orb value in tooltip",
					type = "toggle"
				},
				ttMed = {
					order = 6,
					name = "Show Median",
					desc = "Show Median value in tooltip",
					type = "toggle"
				},
				ttMean = {
					order = 7,
					name = "Show Mean",
					desc = "Show Mean value in tooltip",
					type = "toggle"
				},
				ttMax = {
					order = 8,
					name = "Show Maximum",
					desc = "Show Maximum value in tooltip",
					type = "toggle"
				},
				ttTenDayHeader = {
					order = 9,
					name = "10 Day Average Values",
					type = "header"
				},
				ttTENMin = {
					order = 10,
					name = "Show 10 day Minimum",
					desc = "Show 10 day Minimum value in tooltip",
					type = "toggle"
				},
				ttTENGPO = {
					order = 11,
					name = "Show 10 day Gold Per Orb",
					desc = "Show 10 day Gold Per Orb value in tooltip",
					type = "toggle"
				},
				ttTENMed = {
					order = 12,
					name = "Show 10 day Median",
					desc = "Show 10 day Median value in tooltip",
					type = "toggle"
				},
				ttTENMean = {
					order = 13,
					name = "Show 10 day Mean",
					desc = "Show 10 day Mean value in tooltip",
					type = "toggle"
				},
				ttTENMax = {
					order = 14,
					name = "Show 10 day Maximum",
					desc = "Show 10 day Maximum value in tooltip",
					type = "toggle"
				},
			}
		}
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Mystic Maestro")