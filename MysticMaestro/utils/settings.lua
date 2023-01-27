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
	-- General
	options.args.general = {
		name = "General",
		type = "group",
		order = 1,
		get = get,
		set = set,
		args = {
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
			shopHeader = {
				order = 2,
				name = "Stop for shopping list items",
				type = "header"
			},
			shopEnabled = {
				order = 3,
				name = "Enabled",
				desc = "Stop reforging items with an enchant on your shopping lists",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopForShop.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopForShop.enabled = val end
			},
			reserveShoppingList = {
				order = 4,
				name = "Reserve List Items",
				desc = "Items places on a shopping list will not be reforged over when looking for insignia to roll on",
				type = "toggle"
			},
			shoppingListsDropdown = {
				order = 5,
				name = "Select a List",
				desc = "This is where you can find all of your shopping lists",
				type = "select",
				style = "dropdown",
				values = function() 
					local returnList = {}
					for k, v in ipairs(MM.db.realm.OPTIONS.shoppingLists) do
						table.insert(returnList,v.Name)
					end
					return returnList
				end,
			},
			shoppingSubList = {
				order = 6,
				name = "Enchant Entries",
				desc = "This is where you input entries to the list",
				type = "select",
				style = "dropdown",
				values = function() 
					local returnList = {}
					if MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown] then
						for k, v in ipairs(MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown]) do
							table.insert(returnList,v)
						end
					else
						returnList = {}
					end
					return returnList
				end,
			},
			shopEnabledList = {
				order = 7,
				name = "Enabled",
				desc = "Enables or disables this shopping list",
				type = "toggle",
				get = function(info)
					local o = MM.db.realm.OPTIONS
					if o.shoppingLists[o.shoppingListsDropdown] then
						return o.shoppingLists[o.shoppingListsDropdown].enabled
					end
				end,
				set = function(info,val)
					if MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown] then
						MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown].enabled = val
					end
				end
			},
			shopUnknown = {
				order = 8,
				name = "Unknown",
				desc = "This shopping list will only stop reforging for enchants which are unknown",
				type = "toggle",
				get = function(info)
					local o = MM.db.realm.OPTIONS
					if o.shoppingLists[o.shoppingListsDropdown] then
						return o.shoppingLists[o.shoppingListsDropdown].unknown
					end
				end,
				set = function(info,val)
					if MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown] then
						MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown].unknown = val
					end
				end
			},
			shopExtract = {
				order = 9,
				name = "Extract",
				desc = "This shopping list will extract unknown entries automatically",
				type = "toggle",
				get = function(info)
					local o = MM.db.realm.OPTIONS
					if o.shoppingLists[o.shoppingListsDropdown] then
						return o.shoppingLists[o.shoppingListsDropdown].unknown
					end
				end,
				set = function(info,val)
					if MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown] then
						MM.db.realm.OPTIONS.shoppingLists[MM.db.realm.OPTIONS.shoppingListsDropdown].unknown = val
					end
				end
			},
			seasonalHeader = {
				order = 20,
				name = "Stop for seasonal enchants",
				type = "header"
			},
			seasonalEnabled = {
				order = 21,
				name = "Enabled",
				desc = "Stop reforging items with any seasonal enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopSeasonal.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopSeasonal.enabled = val end
			},
			seasonalExtract = {
				order = 22,
				name = "Extract",
				desc = "Automatically extract any unknown seasonal enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopSeasonal.extract end,
				set = function(info,val) MM.db.realm.OPTIONS.stopSeasonal.extract = val end
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
				get = function(info) return MM.db.realm.OPTIONS.stopQuality.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality.enabled = val end
			},
			qualityUncommon = {
				order = 32,
				name = "Uncommon",
				desc = "Stop reforging items with any uncommon quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[2] = val end
			},
			qualityRare = {
				order = 33,
				name = "Rare",
				desc = "Stop reforging items with any rare quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[3] = val end
			},
			qualityEpic = {
				order = 34,
				name = "Epic",
				desc = "Stop reforging items with any epic quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopQuality[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopQuality[4] = val end
			},
			qualityLegendary = {
				order = 35,
				name = "Legendary",
				desc = "Stop reforging items with any legendary quality enchant",
				type = "toggle",
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
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown.enabled end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown.enabled = val end
			},
			unknownExtract = {
				order = 42,
				name = "Extract",
				desc = "Automatically extract any unknown enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown.extract end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown.extract = val end
			},
			unknownUncommon = {
				order = 43,
				name = "Uncommon",
				desc = "Stop reforging items with any unknown uncommon quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[2] = val end
			},
			unknownRare = {
				order = 44,
				name = "Rare",
				desc = "Stop reforging items with any unknown rare quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[3] = val end
			},
			unknownEpic = {
				order = 45,
				name = "Epic",
				desc = "Stop reforging items with any unknown epic quality enchant",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopUnknown[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopUnknown[4] = val end
			},
			unknownLegendary = {
				order = 46,
				name = "Legendary",
				desc = "Stop reforging items with any unknown legendary quality enchant",
				type = "toggle",
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
				get = function(info) return MM.db.realm.OPTIONS.stopPrice.value end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice.value = val end
			},
			priceUncommon = {
				order = 53,
				name = "Uncommon",
				desc = "Stop reforging items with an uncommon quality enchant above the price value",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[2] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[2] = val end
			},
			priceRare = {
				order = 54,
				name = "Rare",
				desc = "Stop reforging items with a rare quality enchant above the price value",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[3] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[3] = val end
			},
			priceEpic = {
				order = 55,
				name = "Epic",
				desc = "Stop reforging items with an epic quality enchant above the price value",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[4] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[4] = val end
			},
			priceLegendary = {
				order = 56,
				name = "Legendary",
				desc = "Stop reforging items with a legendary quality enchant above the price value",
				type = "toggle",
				get = function(info) return MM.db.realm.OPTIONS.stopPrice[5] end,
				set = function(info,val) MM.db.realm.OPTIONS.stopPrice[5] = val end
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
		if not registered then
			createBlizzOptions()
			registered = true
		end
		InterfaceOptionsFrame_OpenToCategory("Mystic Maestro")
  elseif input == "" then
    MM:HandleMenuSlashCommand()
  else
    MM:Print("Command not recognized")
    MM:Print("Valid input is scan, getall, calc")
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