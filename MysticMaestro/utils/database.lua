local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local defaultDB = {
  realm = {
    OPTIONS = {
      confirmList = true,
      confirmBuyout = true,
      confirmCancel = true,
      confirmCraft = true,

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

      ttTENMin = true,
      ttTENGPO = false,
      ttTENMed = false,
      ttTENMean = false,
      ttTENMax = false,
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
    }
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

local function convertListingData(listingData)
  local results = {}
  for scanTime, auctionList in pairs(listingData) do
    local temp = ":"
    for _, buyoutPrice in ipairs(auctionList) do
      temp = buyoutPrice .. "," .. temp
    end
    for _, buyoutPrice in ipairs(auctionList.other) do
      temp = temp .. buyoutPrice .. ","
    end
    results[scanTime] = temp
  end
  return results
end

function MM:SetupDatabase()
	if MysticMaestroDB and not MysticMaestroData then
		MysticMaestroData = {}
		for realmName, realmTable in pairs(MysticMaestroDB.realm) do
			MysticMaestroData[realmName] = {
				RE_AH_LISTINGS = realmTable.RE_AH_LISTINGS,
				RE_AH_STATISTICS = realmTable.RE_AH_STATISTICS
			}
			realmTable.RE_AH_LISTINGS = nil
			realmTable.RE_AH_STATISTICS = nil
			local temp = {}
			for enchantID, listingData in pairs(MysticMaestroData[realmName].RE_AH_LISTINGS) do
				temp[enchantID] = convertListingData(listingData)
			end
			MysticMaestroData[realmName].RE_AH_LISTINGS = temp
		end
	elseif not MysticMaestroData then
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
end
