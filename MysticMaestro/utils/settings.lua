local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")
local registered = false

local function createConfig()
	local options = {}
	options.type = "group"
	options.name = "Mystic Maestro"
	options.args = {}
	local function get(info) return MM.db.realm.OPTIONS[info[#info]] end
	local function set(info,val) MM.db.realm.OPTIONS[info[#info]] = val end
	local function greenG(info) return MM.db.realm.OPTIONS.green[info[#info]] end
	local function greenS(info,val) MM.db.realm.OPTIONS.green[info[#info]] = val end
	-- General
	options.args.general = {
		name = "General",
		type = "group",
		order = 1,
		get = get,
		set = set,
		args = {
			minimap = {
				order = 1,
				name = "Hide Minimap Button",
				desc = "Hides the minimap button",
				type = "toggle",
				width = 1,
				get = function() return MM.db.realm.OPTIONS.minimap.hide end,
				set = function() MM:ToggleMinimap() end
			},
			confirmHeader = {
				order = 2,
				name = "Confirmations",
				type = "header"
			},
			confirmDescription = {
				order = 3,
				name = "Check the box for each type of confirmation you would like to enable.",
				type = "description"
			},
			confirmList = {
				order = 4,
				name = "Listing",
				desc = "Enables a confirmation before making a listing.",
				type = "toggle",
				width = 0.5,
			},
			confirmBuyout = {
				order = 5,
				name = "Buyout",
				desc = "Enables a confirmation before buying an auction.",
				type = "toggle",
				width = 0.5,
			},
			confirmCancel = {
				order = 6,
				name = "Cancel",
				desc = "Enables a confirmation before canceling your auction.",
				type = "toggle",
				width = 0.5,
			},
			confirmCraft = {
				order = 7,
				name = "Craft",
				desc = "Enables a confirmation before crafting an enchant onto a trinket.",
				type = "toggle",
				width = 0.5,
			},
			durationHeader = {
				order = 8,
				name = "Auction Duration",
				type = "header"
			},
			listDuration = {
				order = 9,
				name = "Listing Duration Index",
				desc = "The duration to create listings. A value of 1 is 12 hours, 2 is 24 hours, 3 is 48 hours.",
				type = "range",
				step = 1,
				min = 1,
				max = 3,
				width = 2
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
			reforgeStandaloneHeader = {
				order = 35,
				name = "Standalone Reforge Button",
				type = "header"
			},
			reforgeStandaloneEnable = {
				order = 36,
				name = "Show",
				desc = "Show standalone Reforge Button",
				type = "toggle",
				width = .4,
				get = function() return MM.sbSettings.Enable end,
				set = function() MM:StandaloneCityReforgeToggle("enable") end
			},
			reforgeStandaloneCitys = {
				order = 38,
				name = "Only In Major Citys",
				desc = "Only show while in major citys",
				type = "toggle",
				width = 1,
				get = function() return MM.sbSettings.Citys end,
				set = function() MM:StandaloneCityReforgeToggle("city") end
			},
		}
	}
	-- Scan
	options.args.scan = {
		name = "Scan",
		type = "group",
		order = 2,
		get = get,
		set = set,
		args = {
			rarityHeader = {
				order = 1,
				name = "Included rarities in normal scan",
				type = "header"
			},
			rarityMagic = {
				order = 2,
				name = "Uncommon",
				desc = "Include Uncommon enchants during scan.",
				type = "toggle",
				width = 0.7,
			},
			rarityRare = {
				order = 3,
				name = "Rare",
				desc = "Include Rare enchants during scan.",
				type = "toggle",
				width = 0.7,
			},
			rarityEpic = {
				order = 4,
				name = "Epic",
				desc = "Include Epic enchants during scan.",
				type = "toggle",
				width = 0.7,
			},
			rarityLegendary = {
				order = 5,
				name = "Legendary",
				desc = "Include Legendary enchants during scan.",
				type = "toggle",
				width = 0.7,
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
	}
	-- Posting
	options.args.posting = {
		name = "Posting",
		type = "group",
		order = 3,
		get = get,
		set = set,
		args = {
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
				step = 0.1,
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
			postUnderOverDesc = {
				order = 5,
				type = "description",
				name = "Determine posting behavior when competition is outside your set price bounds. Options calling for unavailable data will fall back to one of the above settings.",
				width = "full",
			},
			postIfUnder = {
				order = 6,
				name = "When Under Min",
				desc = "Decide how to post when the value is under your minimum.",
				type = "select",
				values = {
					["UNDERCUT"] = "Undercut anyways",
					["IGNORE"] = "Undercut listing above min",
					["DEFAULT"] = "Post at Default price",
					["MAX"] = "Post at Maximum price",
					["KEEP"] = "Do not post",
					["MEAN10"] = "Post at 10 day Mean",
					["MEDIAN10"] = "Post at 10 day Median",
					["MAX10"] = "Post at 10 day Maximum",
				},
				sorting = {"UNDERCUT","IGNORE","DEFAULT","MAX","KEEP","MEAN10","MEDIAN10","MAX10"},
			},
			postIfOver = {
				order = 7,
				name = "When Over Max",
				desc = "Decide how to post when the value is over your maximum.",
				type = "select",
				values = {
					["UNDERCUT"] = "Undercut anyways",
					["DEFAULT"] = "Post at Default price",
					["MAX"] = "Post at Maximum price",
					["MEAN10"] = "Post at 10 day Mean",
					["MEDIAN10"] = "Post at 10 day Median",
					["MAX10"] = "Post at 10 day Maximum",
				},
				sorting = {"UNDERCUT","DEFAULT","MAX","MEAN10","MEDIAN10","MAX10"},
			},
		}
	}
	-- Tooltip
	options.args.tooltip = {
		name = "Tooltip",
		type = "group",
		order = 3,
		get = get,
		set = set,
		args = {
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
			worldforgedTooltip = {
				order = 2,
				name = "Missing Worldforged Tooltip",
				desc = "Shows a list of missing rare worldforged enchants on spell tooltips also checks inventory to see if there is one there unlearned",
				type = "toggle",
				width = 1
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
			ttGuildHeader = {
				order = 15,
				name = "Guild Tooltips",
				type = "header"
			},
			ttGuildEnable = {
				order = 16,
				name = "Enable",
				desc = "Shows in the tooltips of mystic enchants who in your guild has this enchant if they also have the addon",
				type = "toggle",
				func = function() MM:EnableGuildTooltips() end,
			},
			ttGuildDisplayName = {
				order = 17,
				name = "Set Display Name",
				desc = "Lets you set the display name sent if you have more then one character in the guild.",
				type = "select",
				values = MM.guildTooltips.Accounts[MM.guildName].charList,
				get =  function()
					MM.guildTooltips.Accounts[MM.guildName].displayName = MM.guildTooltips.Accounts[MM.guildName].charList[MM.db.realm.OPTIONS.ttGuildDisplayName]
					MM:GuildTooltipsBroadcast("MAESTRO_GUILD_DISPLAYNAME_UPDATE", true)
					return MM.db.realm.OPTIONS.ttGuildDisplayName
				end,
			},
		}
	}
	-- Reforge
	options.args.reforge = {
		name = "Reforge",
		type = "group",
		order = 3,
		get = get,
		set = set,
		args = {
			stopIfNoRunes = {
				order = 1,
				name = "Stop Without Runes",
				desc = "Stop reforging when you have run out of Mystic Runes",
				type = "toggle"
			},
			stopForNothing = {
				order = 2,
				name = "The Rune Waster",
				desc = "Continue to spam reforge until you run out of runes. This will ignore all the options below and just roll on the first scroll in your inventory.",
				type = "toggle"
			},
			qualityHeader = {
				order = 33,
				name = "Stop for specific qualities of enchants",
				type = "header"
			},
			qualityUncommon = {
				order = 34,
				name = "Uncommon",
				desc = "Stop reforging items with any uncommon quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[2] = val end
			},
			qualityRare = {
				order = 35,
				name = "Rare",
				desc = "Stop reforging items with any rare quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[3] = val end
			},
			qualityEpic = {
				order = 35,
				name = "Epic",
				desc = "Stop reforging items with any epic quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[4] = val end
			},
			qualityLegendary = {
				order = 36,
				name = "Legendary",
				desc = "Stop reforging items with any legendary quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[5] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[5] = val end
			},
			unknownHeader = {
				order = 40,
				name = "Stop for specific qualities of unknown enchants",
				type = "header"
			},
			unknownEnabled = {
				order = 41,
				name = "Enabled",
				desc = "Stop reforging items with an unknown enchant of any enabled quality",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown.enabled = val end
			},
			unknownExtract = {
				order = 42,
				name = "Extract",
				desc = "Automatically extract any unknown enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown.extract end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown.extract = val end
			},
			spacer2 = {
				order = 43,
				type = "description",
				name = " "
			},
			unknownUncommon = {
				order = 44,
				name = "Uncommon",
				desc = "Stop reforging items with any unknown uncommon quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[2] = val end
			},
			unknownRare = {
				order = 45,
				name = "Rare",
				desc = "Stop reforging items with any unknown rare quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[3] = val end
			},
			unknownEpic = {
				order = 46,
				name = "Epic",
				desc = "Stop reforging items with any unknown epic quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[4] = val end
			},
			unknownLegendary = {
				order = 47,
				name = "Legendary",
				desc = "Stop reforging items with any unknown legendary quality enchant",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[5] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[5] = val end
			},
			priceHeader = {
				order = 50,
				name = "Stop for enchants above a price",
				type = "header"
			},
			priceEnabled = {
				order = 51,
				name = "Enabled",
				desc = "Stop reforging items with an enchant above the set value",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice.enabled = val end
			},
			priceValue = {
				order = 52,
				name = "Value",
				desc = "Set the minimum price to stop for",
				type = "range",
				step = 0.1,
				min = 0,
				max = 30,
				softMin = 1,
				softMax = 20,
				width = 1.5,
				get = function(info) return MM.db.realm.OPTIONS.stopPrice.value end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice.value = val end
			},
			spacer3 = {
				order = 53,
				type = "description",
				name = " "
			},
			priceUncommon = {
				order = 54,
				name = "Uncommon",
				desc = "Stop reforging items with an uncommon quality enchant above the price value",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[2] = val end
			},
			priceRare = {
				order = 55,
				name = "Rare",
				desc = "Stop reforging items with a rare quality enchant above the price value",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[3] = val end
			},
			priceEpic = {
				order = 56,
				name = "Epic",
				desc = "Stop reforging items with an epic quality enchant above the price value",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[4] = val end
			},
			priceLegendary = {
				order = 57,
				name = "Legendary",
				desc = "Stop reforging items with a legendary quality enchant above the price value",
				type = "toggle",
				width = "half",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[5] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[5] = val end
			},
			greenHeader = {
				order = 60,
				name = "Stop for Green enchants of a Catagory",
				type = "header"
			},
			greenEnabled = {
				order = 61,
				name = "Enabled",
				desc = "Stop reforging items when you match a selected catagory of green",
				type = "toggle",
				width = 0.7,
				get = function(info) return MM.db.realm.OPTIONS.green.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.green.enabled = val end
			},
			greenUnknown = {
				order = 62,
				name = "Unknown",
				desc = "Only Stop when matched enchant of the selected catagory of green is unknown",
				type = "toggle",
				width = 0.7,
				get = function(info) return MM.db.realm.OPTIONS.green.unknown end,
				set = function(info,val) MM.db.realm.OPTIONS.green.unknown = val end
			},
			greenExtract = {
				order = 63,
				name = "Extract",
				desc = "Automatically extract unknown enchants of the selected green catagories",
				type = "toggle",
				width = 0.7,
				get = function(info) return MM.db.realm.OPTIONS.green.extract end,
				set = function(info,val) MM.db.realm.OPTIONS.green.extract = val end
			},
			spacer4 = {
				order = 64,
				type = "description",
				name = "Enable Green catagories"
			},
			Focused = {
				order = 65,
				name = "Focused",
				desc = "Stop for Green enchants with the Focused Prefix. These increase the bonus scaling of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Concentrated = {
				order = 66,
				name = "Concentrated",
				desc = "Stop for Green enchants with the Concentrated Prefix. These reduce the mana cost of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Taunting = {
				order = 67,
				name = "Taunting",
				desc = "Stop for Green enchants with the Taunting Prefix. These increase the threat of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Accurate = {
				order = 68,
				name = "Accurate",
				desc = "Stop for Green enchants with the Accurate Prefix. These increase the hit chance of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Subtle = {
				order = 69,
				name = "Subtle",
				desc = "Stop for Green enchants with the Subtle Prefix. These reduce the threat of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Quick = {
				order = 70,
				name = "Quick",
				desc = "Stop for Green enchants with the Quick Prefix. These reduce the casting time of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Accrual = {
				order = 71,
				name = "Accrual",
				desc = "Stop for Green enchants with the Accrual Prefix. These increase the damage over time of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Brutal = {
				order = 72,
				name = "Brutal",
				desc = "Stop for Green enchants with the Brutal Prefix. These increase the critical strike damage of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Critical = {
				order = 73,
				name = "Critical",
				desc = "Stop for Green enchants with the Critical Prefix. These increase the critical strike chance of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Lengthy = {
				order = 74,
				name = "Lengthy",
				desc = "Stop for Green enchants with the Lengthy Prefix. These increase the duration of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Hardy = {
				order = 75,
				name = "Hardy",
				desc = "Stop for Green enchants with the Hardy Prefix. These increase the dispel resistance of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Steady = {
				order = 76,
				name = "Steady",
				desc = "Stop for Green enchants with the Steady Prefix. These reduces the pushback of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Powerful = {
				order = 77,
				name = "Powerful",
				desc = "Stop for Green enchants with the Powerful Prefix. These increase the damage of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Hasty = {
				order = 78,
				name = "Hasty",
				desc = "Stop for Green enchants with the Hasty Prefix. These reduces the cooldown of an ability.",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
			Other = {
				order = 79,
				name = "Other",
				desc = "Stop for the 12 remaining assorted greens: Speedy, Improved, Defensive, Energizing, Camouflage, Debbie, Meating, Dispersing",
				type = "toggle",
				width = 0.7,
				get = greenG,
				set = greenS
			},
		}
	}
	-- Share settings
	options.args.share = {
		name = "Share",
		type = "group",
		order = 3,
		get = get,
		set = set,
		args = {
			enableShare = {
				order = 1,
				name = "Enable Shopping list sharing",
				desc = "Enable shopping list sharing",
				type = "toggle",
				width = 6
			},
			enableShareCombat = {
				order = 2,
				name = "Auto reject in combat",
				desc = "Auto reject in combat",
				type = "toggle",
				width = 6
			},
		}
	}
	return options
end

local options
local function createBlizzOptions()
	options = createConfig()

	config:RegisterOptionsTable("MysticMaestro-Bliz", {
		name = "Mystic Maestro",
		type = "group",
		args = {
			help = {
				type = "description",
				name = "Mystic Maestro is a multifunctional addon which handles several aspects of the enchanting altar.",
			},
		},
	})
	dialog:SetDefaultSize("MysticMaestro-Bliz", 600, 400)
	dialog:AddToBlizOptions("MysticMaestro-Bliz", "Mystic Maestro")
	-- General
	config:RegisterOptionsTable("MysticMaestro-General", options.args.general)
	dialog:AddToBlizOptions("MysticMaestro-General", options.args.general.name, "Mystic Maestro")
	-- Scan
	config:RegisterOptionsTable("MysticMaestro-Scan", options.args.scan)
	dialog:AddToBlizOptions("MysticMaestro-Scan", options.args.scan.name, "Mystic Maestro")
	-- Posting
	config:RegisterOptionsTable("MysticMaestro-Posting", options.args.posting)
	dialog:AddToBlizOptions("MysticMaestro-Posting", options.args.posting.name, "Mystic Maestro")
	-- Tooltip
	config:RegisterOptionsTable("MysticMaestro-Tooltip", options.args.tooltip)
	dialog:AddToBlizOptions("MysticMaestro-Tooltip", options.args.tooltip.name, "Mystic Maestro")
	-- Reforge
	config:RegisterOptionsTable("MysticMaestro-Reforge", options.args.reforge)
	dialog:AddToBlizOptions("MysticMaestro-Reforge", options.args.reforge.name, "Mystic Maestro")
	-- Share
	config:RegisterOptionsTable("MysticMaestro-Share", options.args.share)
	dialog:AddToBlizOptions("MysticMaestro-Share", options.args.share.name, "Mystic Maestro")
end

function MM:OpenConfig(panel)
	if MM.AutomationManager:IsRunning() then return end
	if not registered then
		createBlizzOptions()
		registered = true
	end
	InterfaceAddOnsList_Update()
	InterfaceOptionsFrame_OpenToCategory(panel)
end

function MM:ProcessSlashCommand(input)
	local lowerInput = input:lower()
	if lowerInput:match("^fullscan$") or lowerInput:match("^getall$") then
		MM:HandleGetAllScan()
	elseif lowerInput:match("^scan") then
		MM:HandleScan(input:match("^%w+%s+(.+)"))
	elseif lowerInput:match("^calc") then
		MM:CalculateAllStats()
	elseif lowerInput:match("^config") or lowerInput:match("^cfg") then
		MM:OpenConfig("Mystic Maestro")
	elseif lowerInput:match("^reforgebutton") then
		MM:StandaloneReforgeShow()
	elseif input == "" then
		MM:HandleMenuSlashCommand()
	else
		MM:Print("Command not recognized")
		MM:Print("Valid input is scan, getall, calc, reforgebutton")
		MM:Print("Scan Rarity includes all, uncommon, rare, epic, legendary")
	end
end

MM:RegisterChatCommand("mm", "ProcessSlashCommand")

local hijackFrame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
hijackFrame:SetScript("OnShow", function(self)
	if not registered then
		createBlizzOptions()
		registered = true
	end
	self:SetScript("OnShow", nil)
end)