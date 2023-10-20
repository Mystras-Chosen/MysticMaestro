local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

-- Options can be accessed in the table: MM.db.realm.OPTIONS
local defaultDB = {
	realm = {
		OPTIONS = {
			confirmList = true,
			confirmBuyout = true,
			confirmCancel = true,
			confirmCraft = true,
			confirmAutomation = true,
			enchantWindowScale = 1,
			standAloneButtonScale = 1,

			deleteAltar = false,

			listDuration = 1,
			
			allowEpic = false,
			limitIlvl = 71,
			limitGold = 2,

			myTimeout = 15,
			myCutoff = 30,
			mySortAlpha = false,

			notificationLearned = true,

			useGetall = true,
			rarityMagic = true,
			rarityRare = true,
			rarityEpic = true,
			rarityLegendary = true,

			ttKnownIndicator = true,
			ttEnable = true,
			worldforgedTooltip = true,
			ttGuildEnable = true,
			
			ttMin = true,
			ttGPO = true,
			ttMed = false,
			ttMean = false,
			ttMax = false,

			postMin = 1,
			postMax = 400,
			postDefault = 120,
			postIfUnder = "IGNORE",
			postIfOver = "MAX",
			postUncommon = true,
			postRare = true,
			postEpic = true,
			postLegendary = true,

			ttTENMin = true,
			ttTENGPO = false,
			ttTENMed = false,
			ttTENMean = false,
			ttTENMax = false,

			standaloneBtn = {
			Citys = false,
			Enable = true,
			},

			minimap = {hide = false},

			enableShare = false,
			enableShareCombat = false,

			enableMatching = false,
			matchingToBank = true,
			mathcingFromBank = true,

			purchaseScrolls = true,
			removeFound = true,
			noChatResult = false,
			delayAfterBagUpdate = 0.3,
			stopIfNoRunes = true,
			shoppingListsDropdown = 1,
			shoppingSubList = 1,
			stopForShop = {
				enabled = false,
			},
			shoppingLists = {
			},
			stopQuality = {
				enabled = false,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true
			},
			stopUnknown = {
				enabled = false,
				extract = false,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true
			},
			stopPrice = {
				enabled = false,
				value = 3.5,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true
			},
			green = {
				enabled=false,
				unknown=true,
				extract=true,
				Focused=false,
				Concentrated=false,
				Taunting=false,
				Accurate=false,
				Subtle=false,
				Quick=false,
				Accrual=false,
				Brutal=false,
				Critical=false,
				Lengthy=false,
				Hardy=false,
				Steady=false,
				Powerful=false,
				Hasty=false,
				Other=false,
			},
		},
		VIEWS = {
			sort = 1,
			filter = {
				allQualities = true,
				uncommon = false,
				rare = false,
				epic = false,
				legendary = false,
				allKnown = true,
				known = false,
				unknown = false,
				favorites = false,
				bags = false
			}
		},
		SHOPPING_LISTS = {},
	}
}

local guildDB = {
	realm = {
		GUILD_TOOLTIPS = {
			Accounts = {},
			Guilds = {}
		},
	}
}

local realmName = GetRealmName()
local enchantMT = {
	__index = function(t, k)
		local newListing = {}
		t[k] = newListing
		return newListing
	end
}

function MM:SetupDatabase()
	if not MysticMaestroData then
		MysticMaestroData = MysticMaestroData or {}
	end

	MysticMaestroData[realmName] = MysticMaestroData[realmName] or {
		RE_AH_LISTINGS = {},
		RE_AH_STATISTICS = {}
	}
	MM.data = setmetatable(MysticMaestroData,
		{
			__index = function(t, k)
				return t[realmName][k]
			end,
			__newindex = function(t, k, v)
				t[realmName][k] = v
			end
		}
	)
	setmetatable(MM.data.RE_AH_LISTINGS, enchantMT)
	setmetatable(MM.data.RE_AH_STATISTICS, enchantMT)

	MM.db = LibStub("AceDB-3.0"):New("MysticMaestroDB", defaultDB, true)
	MM.db.realm.FAVORITE_ENCHANTS = MM.db.realm.FAVORITE_ENCHANTS or {}
	MM.db.realm.VIEWS = MM.db.realm.VIEWS or {}
	MM.db.realm.OPTIONS = MM.db.realm.OPTIONS or {}
	MM.sbSettings = MM.db.realm.OPTIONS.standaloneBtn
	MM.shoppingLists = MM.db.realm.SHOPPING_LISTS
	
	MM.rollState = "Start Reforge"

	MM.guidldb = LibStub("AceDB-3.0"):New("MysticMaestroGuildEnchants", guildDB, true)
	if MM.db.realm.GUILD_TOOLTIPS then
		MM.guidldb.realm.GUILD_TOOLTIPS = MM:Clone(MM.db.realm.GUILD_TOOLTIPS)
		MM.db.realm.GUILD_TOOLTIPS = nil
	end
	MM.guildTooltips = MM.guidldb.realm.GUILD_TOOLTIPS
end
