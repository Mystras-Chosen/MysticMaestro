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
				confirmHeader = {
					order = 1,
					name = "Confirmations",
					type = "header"
				},
				confirmList = {
					order = 2,
					name = "Confirm Listing",
					desc = "Enables a confirmation before making a listing.",
					type = "toggle"
				},
				confirmBuyout = {
					order = 3,
					name = "Confirm Buyout",
					desc = "Enables a confirmation before buying an auction.",
					type = "toggle"
				},
				confirmCancel = {
					order = 4,
					name = "Confirm Cancel",
					desc = "Enables a confirmation before canceling your auction.",
					type = "toggle"
				},
				limitsHeader = {
					order = 10,
					name = "Item Limits",
					type = "header"
				},
				allowEpic = {
					order = 11,
					name = "Allow Epic",
					desc = "Allow epic items to be considered for listing.",
					type = "toggle"
				},
				limitIlvl = {
					order = 12,
					name = "Limit by Item Level",
					desc = "Define the highest allowable item level that is considered for listing.",
					type = "range",
					step = 1,
					min = 15,
					max = 999,
					softMin = 15,
					softMax = 120
				},
				limitGold = {
					order = 13,
					name = "Limit by Vendor Value",
					desc = "Define the highest allowable vendor value that is considered for listing.",
					type = "range",
					step = .1,
					min = 0,
					max = 15,
					softMin = 1,
					softMax = 10
				},
				myHeader = {
					order = 20,
					name = "My Auctions",
					type = "header"
				},
				myTimeout = {
					order = 21,
					name = "Timeout Scan Validity",
					desc = "Set the duration the addon will wait before considering the last scan old.",
					type = "range",
					step = 1,
					min = 1,
					max = 60,
					softMin = 5,
					softMax = 30
				},
				mySortAlpha = {
					order = 22,
					name = "Sort My Auctions Alphabetically",
					desc = "Enable to sort alphabetically, disable to sort based on the number of listed enchants.",
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
					name = "Included rarities in scan",
					type = "header"
				},
				rarityMagic = {
					order = 2,
					name = "Uncommon",
					desc = "Include Uncommon enchants during scan.",
					type = "toggle"
				},
				rarityRare = {
					order = 3,
					name = "Rare",
					desc = "Include Rare enchants during scan.",
					type = "toggle"
				},
				rarityEpic = {
					order = 4,
					name = "Epic",
					desc = "Include Epic enchants during scan.",
					type = "toggle"
				},
				rarityLegendary = {
					order = 5,
					name = "Legendary",
					desc = "Include Legendary enchants during scan.",
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