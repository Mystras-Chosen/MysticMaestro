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
				confirmCraft = {
					order = 5,
					name = "Confirm Craft",
					desc = "Enables a confirmation before crafting an enchant onto a trinket.",
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
					name = "Recent Scan Timeout",
					desc = "Set the duration the addon will wait before considering the last scan old, this will turn the color from green/red to yellow.",
					type = "range",
					step = 1,
					min = 1,
					max = 15,
					softMin = 5,
					softMax = 15
				},
				myCutoff = {
					order = 22,
					name = "Recent Scan Cutoff",
					desc = "Set the duration the addon will wait before considering the last scan completely stale, this will turn the color from yellow to red.",
					type = "range",
					step = 1,
					min = 16,
					max = 60,
					softMin = 20,
					softMax = 40
				},
				mySortAlpha = {
					order = 23,
					name = "Sort Alphabetically",
					desc = "Enable to sort alphabetically, disable to sort based on the number of listed enchants.",
					type = "toggle"
				},
				notificationHeader = {
					order = 30,
					name = "Notifications",
					type = "header"
				},
				notificationLearned = {
					order = 31,
					name = "Enchant Learned",
					desc = "Enable chat output when you learn an enchant, or if you use an epic or legendary mystic scroll.",
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
					name = "Included rarities in normal scan",
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
				getallHeader = {
					order = 10,
					name = "Scan type",
					type = "header"
				},
				useGetall = {
					order = 11,
					name = "Enable GetAll mode",
					desc = "Enable to get all auctions in one quick batch scan.",
					type = "toggle"
				},
				useGetallDescription = {
					order = 12,
					name = "Typical GetAll scan will take 10-15 seconds, "
					.. "but can last 10 - 15 minutes after any server update or patch."
					.. "\n\nThis has a 15 minute cooldown."
					.. "\n\nDisabled on the seasonal server.",
					type = "description"
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
		},
		posting={
			name = "Posting",
			type = "group",
			args={
				postHeader = {
					order = 1,
					name = "Post Values",
					type = "header"
				},
				postMin = {
					order = 2,
					name = "Minimum Value",
					desc = "Define the minimum value which will be considered a valid price.",
					type = "range",
					step = 1,
					min = 0,
					max = 30,
					softMin = 1,
					softMax = 20
				},
				postMax = {
					order = 3,
					name = "Maximum Value",
					desc = "Define the maximum value which will be considered a valid price.",
					type = "range",
					step = 1,
					min = 100,
					max = 600,
					softMin = 100,
					softMax = 500
				},
				postDefault = {
					order = 4,
					name = "Default Value",
					desc = "Define the default value which will be used for enchants without any listings.",
					type = "range",
					step = 1,
					min = 30,
					max = 600,
					softMin = 100,
					softMax = 300
				},
				postIfUnder = {
					order = 5,
					name = "When Under Min",
					desc = "Decide how to post when the value is under your minimum.",
					type = "select",
					values = {
						["UNDERCUT"] = "Undercut anyways",
						["IGNORE"] = "Undercut next listing above min",
						["DEFAULT"] = "Post at Default price",
						["MAX"] = "Post at Maximum price",
						["KEEP"] = "Do not post",
					}
				},
				postIfOver = {
					order = 6,
					name = "When Over Max",
					desc = "Decide how to post when the value is over your maximum.",
					type = "select",
					values = {
						["UNDERCUT"] = "Undercut anyways",
						["DEFAULT"] = "Post at Default price",
						["MAX"] = "Post at Maximum price",
					}
				},
			}
		}
  }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Mystic Maestro")