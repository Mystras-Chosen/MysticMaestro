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
			deleteAltar = {
				order = 2,
				name = "Delete Enchanting Altar",
				desc = "Deletes the enchanting altar after you summon it to save on bag space a new altar will be pulled from collection on first click off the next summon",
				type = "toggle",
				width = 2,
			},
			confirmHeader = {
				order = 5,
				name = "Confirmations",
				type = "header"
			},
			confirmDescription = {
				order = 6,
				name = "Check the box for each type of confirmation you would like to enable.",
				type = "description"
			},
			confirmList = {
				order = 7,
				name = "Listing",
				desc = "Enables a confirmation before making a listing.",
				type = "toggle",
				width = 0.5,
			},
			confirmBuyout = {
				order = 8,
				name = "Buyout",
				desc = "Enables a confirmation before buying an auction.",
				type = "toggle",
				width = 0.5,
			},
			confirmCancel = {
				order = 9,
				name = "Cancel",
				desc = "Enables a confirmation before canceling your auction.",
				type = "toggle",
				width = 0.5,
			},
			confirmCraft = {
				order = 15,
				name = "Craft",
				desc = "Enables a confirmation before crafting an enchant onto a Untarnished Mystic Scroll.",
				type = "toggle",
				width = 0.5,
			},
			confirmAutomation = {
				order = 16,
				name = "Automation",
				desc = "Enables a confirmation before starting Automation functions. This applies to Post and Scan automations as well as any others added in the future.",
				type = "toggle",
				width = 0.5,
			},
			myHeader = {
				order = 25,
				name = "My Auctions",
				type = "header"
			},
			myTimeout = {
				order = 26,
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
				order = 27,
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
				order = 28,
				name = "Sort Alphabetically",
				desc = "Enable to sort alphabetically, disable to sort based on the number of listed enchants.",
				type = "toggle"
			},
			notificationHeader = {
				order = 29,
				name = "Notifications",
				type = "header"
			},
			notificationLearned = {
				order = 30,
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
				order = 37,
				name = "Only In Major Citys",
				desc = "Only show while in major citys",
				type = "toggle",
				width = 1,
				get = function() return MM.sbSettings.Citys end,
				set = function() MM:StandaloneCityReforgeToggle("city") end
			},
			enchantWindowScaleHeader = {
				order = 38,
				name = "Window Scale",
				type = "header"
			},
			enchantWindowScale = {
				order = 39,
				name = "Enchant Window",
				desc = "Sets the size scale of the enchant frame",
				type = "range",
				step = .01,
				min = .25,
				max = 1.5,
				width = 2,
				get = function()
					Collections:SetScale(MM.db.realm.OPTIONS.enchantWindowScale)
					return MM.db.realm.OPTIONS.enchantWindowScale
				end
			},
			standAloneButtonScale = {
				order = 39,
				name = "Standalone Reforge Button",
				desc = "Sets the size standalone reforge button",
				type = "range",
				step = .01,
				min = .25,
				max = 1.5,
				width = 2,
				get = function()
					MysticMaestro_ReforgeFrame:SetScale(MM.db.realm.OPTIONS.standAloneButtonScale)
					return MM.db.realm.OPTIONS.standAloneButtonScale
				end
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
			durationHeader = {
				order = 1,
				name = "Auction Duration",
				type = "header"
			},
			listDuration = {
				order = 2,
				name = "Listing Duration Index",
				desc = "The duration to create listings. A value of 1 is 12 hours, 2 is 24 hours, 3 is 48 hours.",
				type = "range",
				step = 1,
				min = 1,
				max = 3,
				width = 2
			},
			postHeader = {
				order = 10,
				name = "Post Values",
				type = "header"
			},
			postMin = {
				order = 11,
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
				order = 12,
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
				order = 13,
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
				order = 20,
				type = "description",
				name = "Determine posting behavior when competition is outside your set price bounds. Options calling for unavailable data will fall back to one of the above settings.",
				width = "full",
			},
			postIfUnder = {
				order = 21,
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
				order = 22,
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
			postQualityHeader = {
				order = 30,
				name = "Post Qualitys",
				type = "header"
			},
			postUncommon = {
				order = 31,
				name = "Uncommon",
				desc = "Post enchants of this quality",
				type = "toggle",
				width = .7,
			},
			postRare = {
				order = 32,
				name = "Rare",
				desc = "Post enchants of this quality",
				type = "toggle",
				width = .5,
			},
			postEpic = {
				order = 33,
				name = "Epic",
				desc = "Post enchants of this quality",
				type = "toggle",
				width = .5,
			},
			postLegendary = {
				order = 34,
				name = "Legendary",
				desc = "Post enchants of this quality",
				type = "toggle",
				width = .7,
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
				values = function() 
					if MM.guildTooltips.Accounts[MM.guildName] and MM.guildTooltips.Accounts[MM.guildName].charList then
						return MM.guildTooltips.Accounts[MM.guildName].charList 
					else 
						return {[1] = "No Guild"} end 
					end,
				get =  function()
					if not MM.guildTooltips.Accounts[MM.guildName] then return end
					MM.guildTooltips.Accounts[MM.guildName].displayName = MM.guildTooltips.Accounts[MM.guildName].charList[MM.db.realm.OPTIONS.ttGuildDisplayName]
					MM:GuildTooltipsBroadcast("MAESTRO_GUILD_TOOLTIPS_SEND")
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
			delayAfterBagUpdate = {
				name = "Delay after Reforge result",
				order = 2,
				type = "range",
				step = 0.01,
				min = 0.1,
				max = 2,
				softMin = 0.2,
				softMax = 1,
				desc = "Set the amount of time to elapse after each reforge, too low of a value will cause blocked casts.",
			},
			purchaseScrolls = {
				order = 3,
				name = "Purchase Mystic Scrolls",
				desc = "Automatically purchase required mystic scrolls during the reforge loop",
				type = "toggle"
			},
			removeFound = {
				order = 3,
				name = "Remove Found",
				desc = "Automatically remove found enchants on an auto extract shopping list that is enabled",
				type = "toggle"
			},
			noChatResult = {
				order = 4,
				name = "Hide chat result text",
				desc = "Don't show result text in chat window ",
				type = "toggle"
			},
			qualityHeader = {
				order = 30,
				name = "Stop for specific qualities of enchants",
				type = "header"
			},
			qualityEnabled = {
				order = 31,
				name = "Enabled",
				desc = "Stop reforging items with an enchant of any enabled quality",
				type = "toggle",
				width = 1,
				get = function(info) return MM.db.realm.OPTIONS.stopQuality.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality.enabled = val end
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
		get = get,
		set = set,
		args = {
			enableShare = {
				name = "Enable Shopping list sharing",
				desc = "Enable shopping list sharing",
				type = "toggle",
				width = 6
			},
			enableShareCombat = {
				name = "Auto reject in combat",
				desc = "Auto reject in combat",
				type = "toggle",
				width = 6
			},
		}
	}
	-- Share settings
	options.args.bank = {
		name = "Bank Functions",
		type = "group",
		get = get,
		set = set,
		args = {
			ttGuildHeader = {
				order = 1,
				name = "Guild/Personal/Realm Bank",
				type = "header"
			},
			enableMatching = {
				order = 2,
				name = "Enable",
				desc = "Enable moving enchants matching my rolling criteria",
				type = "toggle",
				width = 6
			},
			matchingToBank = {
				order = 3,
				name = "Move matching to bank",
				desc = "Move enchants matching my rolling criteria to bank",
				type = "toggle",
				width = 6
			},
			mathcingFromBank = {
				order = 4,
				name = "Move matching from bank",
				desc = "Move enchants matching my rolling criteria from bank",
				type = "toggle",
				width = 6
			},
		}
	}
	local serverSelect
	local function getServerNames()
		local serverNames = {}
		for name, _ in pairs(MysticMaestroData) do
			table.insert(serverNames,name)
		end
		return serverNames
	end
	-- DB Management
	options.args.manage = {
		name = "Manage Data",
		type = "group",
		args = {
			header = {
				order = 1,
				name = "As we move from one server to the next,"
				.. " we end up with stray data remaining from servers which are no longer active."
				.. " This is a way for you to manually purge that data from old servers.",
				type = "header"
			},
			serverSelect = {
				order = 2,
				name = "Select a Server",
				desc = "Select a server to wipe its data.",
				type = "select",
				width = 2,
				values = getServerNames,
				get = function() return serverSelect end,
				set = function(info,val) serverSelect = val end 
			},
			wipeButton = {
				order = 3,
				name = "Wipe Data",
				desc = "Wipes the data for the selected server.",
				type = "execute",
				func = function()
					if serverSelect then
						local serverNames = getServerNames()
						local selection = serverNames[serverSelect]
						MysticMaestroData[selection] = nil
						MysticMaestroDB.realm[selection] = nil
						MM:Print(selection .. " options and scan data has been wiped.")
						serverSelect = nil
					end
				end
			}
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
	-- Share
	config:RegisterOptionsTable("MysticMaestro-Bank", options.args.bank)
	dialog:AddToBlizOptions("MysticMaestro-Bank", options.args.bank.name, "Mystic Maestro")
	-- Manage
	config:RegisterOptionsTable("MysticMaestro-Manage", options.args.manage)
	dialog:AddToBlizOptions("MysticMaestro-Manage", options.args.manage.name, "Mystic Maestro")
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