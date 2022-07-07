local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end

function MM:GetAHItemEnchantName(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  return MM:MatchTooltipRE(GameTooltip)
end

function MM:MatchTooltipRE(TT)
  return TT:Match("Equip: (.- %- %w+) %- .+") or TT:Match("Equip: (.-) %- .+")
end

local function getAuctionInfo(i)
  local itemName, _, _, quality, _, level, _, _, buyoutPrice, _, _, seller = GetAuctionItemInfo("list", i)
  return itemName, level, buyoutPrice, quality, seller
end

local function isEnchantTrinketFound(itemName, level, buyoutPrice, i)
  local trinketFound = itemName and itemName:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0
  local enchantName
  if trinketFound then
    enchantName = MM:GetAHItemEnchantName(i)
  end
  return trinketFound and enchantName, enchantName
end

local function isEnchantItemFound(quality, buyoutPrice, i)
  local properItem = buyoutPrice and buyoutPrice > 0 and quality and quality >= 3
  local enchantName
  if properItem then
    enchantName = MM:GetAHItemEnchantName(i)
  end
  return properItem and enchantName, enchantName
end

function MM:CollectSpecificREData(scanTime, expectedEnchantName)
  local listings = self.db.realm.RE_AH_LISTINGS
  listings[expectedEnchantName][scanTime] = listings[expectedEnchantName][scanTime] or {}
  listings[expectedEnchantName][scanTime]["other"] = listings[expectedEnchantName][scanTime]["other"] or {}
  local enchantFound = false
  local numBatchAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local itemName, level, buyoutPrice, quality = getAuctionInfo(i)
      local itemFound, enchantName = isEnchantTrinketFound(itemName, level, buyoutPrice, i)
      if itemFound and enchantName == expectedEnchantName then
        enchantFound = true
        table.insert(listings[enchantName][scanTime], buyoutPrice)
      else
        itemFound, enchantName = isEnchantItemFound(quality,buyoutPrice,i)
        if itemFound and enchantName == expectedEnchantName then
          enchantFound = true
          table.insert(listings[enchantName][scanTime]["other"], buyoutPrice)
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
      local itemFound, enchantName = isEnchantTrinketFound(itemName, level, buyoutPrice)
      if itemFound then
        listings[enchantName][scanTime] = listings[enchantName][scanTime] or {}
        table.insert(listings[enchantName][scanTime], buyoutPrice)
      else
        itemFound, enchantName = isEnchantItemFound(quality,buyoutPrice,i)
        if itemFound then
          listings[enchantName][scanTime] = listings[enchantName][scanTime] or {}
          listings[enchantName][scanTime]["other"] = listings[enchantName][scanTime]["other"] or {}
          table.insert(listings[enchantName][scanTime]["other"], buyoutPrice)
        end
      end
    end
  end
end

function MM:round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function MM:CompareTime(a,b)
  local time = difftime(a,b)
  local yDif = floor(time / 31536000)
  local dDif = floor(mod(time, 31536000) / 86400)
  local hDif = floor(mod(time, 86400) / 3600)
  local mDif = floor(mod(time, 3600) / 60)
  local sDif = floor(mod(time, 60))
  return {year = yDif, day = dDif, hour = hDif, min = mDif, sec = sDif}
end

function MM:Dump(data,index)
  return DevTools_Dump(data,index ~= nil and index or 0)
end

function MM:CalculateStatsFromTime(nameRE,sTime)
  local listing = self.db.realm.RE_AH_LISTINGS[nameRE][sTime]
  local stats = self.db.realm.RE_AH_STATISTICS[nameRE]
  local minVal, medVal, avgVal, topVal, count = MM:CalculateStatsFromList(listing)
  local minOther, medOther, avgOther, topOther, countOther
  if listing.other ~= nil then
    minOther, medOther, avgOther, topOther, countOther = MM:CalculateStatsFromList(listing.other)
  end
  if count and count > 0 or countOther and countOther > 0 then
    stats[sTime], stats["current"] = stats[sTime] or {}, stats["current"] or {}
    local t = stats[sTime]
    local c = stats["current"]
    if count and count > 0 then
      t.minVal,t.medVal,t.avgVal,t.topVal,t.listed = minVal,medVal,avgVal,topVal,count
      if c.latest == nil or c.latest <= sTime then
        c.minVal,c.medVal,c.avgVal,c.topVal,c.listed,c.latest = minVal,medVal,avgVal,topVal,count,sTime
      end
    end
    if countOther and countOther > 0 then
      t.minOther,t.medOther,t.avgOther,t.topOther,t.listedOther = minOther,medOther,avgOther,topOther,countOther
      if c.latestOther == nil or c.latestOther <= sTime then
        c.minOther,c.medOther,c.avgOther,c.topOther,c.listedOther,c.latestOther = minOther,medOther,avgOther,topOther,countOther,sTime
      end
    end
  end
end

function MM:CalculateAllStats(forceCalc)
  local listDB = self.db.realm.RE_AH_LISTINGS
  local namekey, listing, timekey, values
  for namekey, listing in pairs(listDB) do
    for timekey, values in pairs(listing) do
      if forceCalc or self.db.realm.RE_AH_STATISTICS[namekey][timekey] == nil then
        MM:CalculateStatsFromTime(namekey,timekey)
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
    return minVal, medVal, avgVal, topVal, count
  end
end

local qualityValue = {
  uncommon = 2,
  rare = 3,
  epic = 4,
  legendary = 5
}

function MM:GetAlphabetizedEnchantList(qualityName)
	local enchants = MM[qualityName:upper() .. "_ENCHANTS"]
	if not enchants then
		enchants = {}
		for _, enchantData in pairs(MYSTIC_ENCHANTS) do
			if enchantData.quality == qualityValue[qualityName] then
				local enchantName = GetSpellInfo(enchantData.spellID)
				table.insert(enchants, enchantName)
				enchants[enchantName] = true
			end
		end
		table.sort(enchants)
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end