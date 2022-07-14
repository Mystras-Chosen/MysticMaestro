local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end

function MM:GetAHItemEnchantID(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  return self:MatchTooltipRE(GameTooltip)
end

local function getAuctionInfo(i)
  local itemName, _, _, quality, _, level, _, _, buyoutPrice, _, _, seller = GetAuctionItemInfo("list", i)
  return itemName, level, buyoutPrice, quality, seller
end

local function isEnchantTrinketFound(itemName, level, buyoutPrice, i)
  local trinketFound = itemName and itemName:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0
  local enchantID
  if trinketFound then
    enchantID = MM:GetAHItemEnchantID(i)
  end
  return trinketFound and enchantID, enchantID
end

local function isEnchantItemFound(quality, buyoutPrice, i)
  local properItem = buyoutPrice and buyoutPrice > 0 and quality and quality >= 3
  local enchantID
  if properItem then
    enchantID = MM:GetAHItemEnchantID(i)
  end
  return properItem and enchantID, enchantID
end

local qualityValue = {
  uncommon = 2,
  rare = 3,
  epic = 4,
  legendary = 5
}

function MM:GetAlphabetizedEnchantList(qualityName)
	-- list of mystic enchant IDs ordered alphabetically by their spell name
	local enchants = MM[qualityName:upper() .. "_ENCHANTS"]
	if not enchants then
		enchants = {}
		for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
			if enchantData.quality == qualityValue[qualityName] then
				table.insert(enchants, enchantID)
				enchants[enchantID] = true
			end
		end
		table.sort(enchants,
      function(k1, k2)
        return MM.RE_NAMES[k1] < MM.RE_NAMES[k2]
      end
    )
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end

---------------------------------
--   Auction Stats functions   --
---------------------------------

function MM:CollectSpecificREData(scanTime, expectedEnchantID)
  local listings = self.db.realm.RE_AH_LISTINGS
  listings[expectedEnchantID][scanTime] = listings[expectedEnchantID][scanTime] or {}
  listings[expectedEnchantID][scanTime]["other"] = listings[expectedEnchantID][scanTime]["other"] or {}
  local enchantFound = false
  local numBatchAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local itemName, level, buyoutPrice, quality = getAuctionInfo(i)
      buyoutPrice = MM:round(buyoutPrice / 10000, 4, true)
      local itemFound, enchantID = isEnchantTrinketFound(itemName, level, buyoutPrice, i)
      if itemFound and enchantID == expectedEnchantID then
        enchantFound = true
        table.insert(listings[enchantID][scanTime], buyoutPrice)
      else
        itemFound, enchantID = isEnchantItemFound(quality,buyoutPrice,i)
        if itemFound and enchantID == expectedEnchantID then
          enchantFound = true
          table.insert(listings[enchantID][scanTime]["other"], buyoutPrice)
        end  
      end
    end
  end
  return enchantFound
end

function MM:CollectAllREData(scanTime)
  local listings = self.db.realm.RE_AH_LISTINGS
  local numBatchAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local itemName, level, buyoutPrice, quality = getAuctionInfo(i)
      buyoutPrice = MM:round(buyoutPrice / 10000, 4, true)
      local itemFound, enchantID = isEnchantTrinketFound(itemName, level, buyoutPrice)
      if itemFound then
        listings[enchantID][scanTime] = listings[enchantID][scanTime] or {}
        table.insert(listings[enchantID][scanTime], buyoutPrice)
      else
        itemFound, enchantID = isEnchantItemFound(quality,buyoutPrice,i)
        if itemFound then
          listings[enchantID][scanTime] = listings[enchantID][scanTime] or {}
          listings[enchantID][scanTime]["other"] = listings[enchantID][scanTime]["other"] or {}
          table.insert(listings[enchantID][scanTime]["other"], buyoutPrice)
        end
      end
    end
  end
end

function MM:CalculateStatsFromTime(reID,sTime)
  local listing = self.db.realm.RE_AH_LISTINGS[reID][sTime]
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
  local minVal, medVal, avgVal, topVal, count, stdDev = MM:CalculateStatsFromList(listing)
  local minOther, medOther, avgOther, topOther, countOther
  if listing.other ~= nil then
    minOther, medOther, avgOther, topOther, countOther, stdDevOther = MM:CalculateStatsFromList(listing.other)
  end
  if count and count > 0 or countOther and countOther > 0 then
    stats[sTime], stats["current"] = stats[sTime] or {}, stats["current"] or {}
    local t = stats[sTime]
    local c = stats["current"]
    if count and count > 0 then
      t.minVal,t.medVal,t.avgVal,t.topVal,t.listed,t.stdDev = minVal,medVal,avgVal,topVal,count,stdDev
      if c.latest == nil or c.latest <= sTime then
        c.minVal,c.medVal,c.avgVal,c.topVal,c.listed,c.latest,c.stdDev = minVal,medVal,avgVal,topVal,count,sTime,stdDev
      end
    end
    if countOther and countOther > 0 then
      t.minOther,t.medOther,t.avgOther,t.topOther,t.listedOther,t.stdDevOther = minOther,medOther,avgOther,topOther,countOther,stdDevOther
      if c.latestOther == nil or c.latestOther <= sTime then
        c.minOther,c.medOther,c.avgOther,c.topOther,c.listedOther,c.latestOther,c.stdDevOther = minOther,medOther,avgOther,topOther,countOther,sTime,stdDevOther
      end
    end
  end
end

function MM:CalculateAllStats(forceCalc)
  local listDB = self.db.realm.RE_AH_LISTINGS
  local reID, listing, timekey, values
  for reID, listing in pairs(listDB) do
    for timekey, values in pairs(listing) do
      if forceCalc or self.db.realm.RE_AH_STATISTICS[reID][timekey] == nil then
        MM:CalculateStatsFromTime(reID,timekey)
      end
    end
  end
end

function MM:CalculateStatsFromList(list)
  local minVal, topVal, count, tally = 0, 0, 0, 0
  for _, v in pairs(list) do
    if type(v) == "number" then
      if v > 0 and (v < minVal or minVal == 0) then
        minVal = v
      end
      if v > topVal then
        topVal = v
      end
      if v ~= nil then
        tally = tally + v
        count = count + 1
      end
    end
  end
  if count > 0 then
    local midKey = count > 1 and MM:round(count/2) or 1
    sort(list)
    local medVal = list[midKey]
    local avgVal = MM:round(tally/count)
    local stdDev = MM:StdDev(list,avgVal)
    return minVal, medVal, avgVal, topVal, count, MM:round(stdDev,2)
  end
end

local kIndex = {
  ["min"] = {"minVal","minOther"},
  ["med"] = {"medVal","medOther"},
  ["mean"] = {"avgVal","avgOther"},
  ["max"] = {"topVal","topOther"},
  ["dev"] = {"stdDev","stdDevOther"},
  ["num"] = {"listed","listedOther"}
}

function MM:LowestListed(reID,keytype)
  local current = self.db.realm.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local trink, other = current[kIndex[keytype or "min"][1]], current[kIndex[keytype or "min"][2]]
  local lowest
  if current.latestOther and current.latest then
    lowest = trink < other and trink or other
  elseif current.latest then
    lowest = trink
  elseif current.latestOther then
    lowest = other
  end
  return lowest
end

function MM:TotalListed(reID)
  local current = self.db.realm.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local trink, other = current[kIndex["num"][1]], current[kIndex["num"][2]]
  local total
  if current.latestOther and current.latest then
    total = trink + other
  elseif current.latest then
    total = trink
  elseif current.latestOther then
    total = other
  end
  return total
end

local qualityCost = {
  [2] = 2,
  [3] = 6,
  [4] = 10,
  [5] = 25
}

function MM:OrbCost(reID)
	return qualityCost[MYSTIC_ENCHANTS[reID].quality]
end

function MM:OrbValue(reID, keytype)
  local cost = MM:OrbCost(reID)
  local value = MM:LowestListed(reID,keytype or "min")
  return value and MM:round(value / cost,2,true) or nil
end
