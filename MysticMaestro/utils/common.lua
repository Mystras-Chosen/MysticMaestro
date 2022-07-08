local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end

function MM:MatchTooltipRE(TT)
  for i=1, TT:NumLines() do
    local line = _G[TT:GetName() .. "TextLeft" .. i]:GetText()
    if line and line ~= "" then
      name = line:match("Equip: (.- %- %w+) %- .+")
      if name then
        return self.RE_LOOKUP[name]
      end
      name, description = line:match("Equip: (.-) %- (.+)")
      if name then
        if name == "Druidic Rites" then
          if description:lower():find("damage") then
            return self.RE_LOOKUP[name .. " - Epic"]
          else
            return self.RE_LOOKUP[name .. " - Rare"]
          end
        else
          return self.RE_LOOKUP[name]
        end
      end
    end
  end
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

function MM:CollectSpecificREData(scanTime, expectedEnchantID)
  local listings = self.db.realm.RE_AH_LISTINGS
  listings[expectedEnchantID][scanTime] = listings[expectedEnchantID][scanTime] or {}
  listings[expectedEnchantID][scanTime]["other"] = listings[expectedEnchantID][scanTime]["other"] or {}
  local enchantFound = false
  local numBatchAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local itemName, level, buyoutPrice, quality = getAuctionInfo(i)
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

function MM:DaysAgoString(stamp,incSeconds)
  local string = ""
  local dif = MM:CompareTime(time(),stamp)
  if dif.year > 0 then
    string = string .. dif.year .. "y"
  end
  if dif.day > 0 then
    string = string .. dif.day .. "d"
  end
  if dif.hour > 0 then
    string = string .. dif.hour .. "h"
  end
  if dif.min > 0 then
    string = string .. dif.min .. "m"
  end
  if incSeconds and dif.sec > 0 then
    string = string .. dif.sec .. "s"
  end
  if string ~= "" then
    string = string .. " ago."
  end
  return string
end

function MM:Dump(data,index)
  return DevTools_Dump(data,index ~= nil and index or 0)
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

function MM:variance(tbl,avg)
  local dif
  local sum, count = 0, 0
  for k, v in pairs(tbl) do
    if type(v) == "number" then
      dif = v - avg
      sum = sum + (dif * dif)
      count = count + 1
    end
  end
  return ( sum / count )
end

function MM:StdDev(tbl,avg)
  local variance = MM:variance(tbl,avg)
  return math.sqrt(variance)
end

local qualityValue = {
  uncommon = 2,
  rare = 3,
  epic = 4,
  legendary = 5
}

-- list of mystic enchant IDs ordered alphabetically by their spell name
function MM:GetAlphabetizedEnchantList(qualityName)
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
        return GetSpellInfo(MYSTIC_ENCHANTS[k1].spellID) < GetSpellInfo(MYSTIC_ENCHANTS[k2].spellID)
      end
    )
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end