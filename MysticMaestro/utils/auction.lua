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

---------------------------------
--   Auction Stats functions   --
---------------------------------

function MM:CalculateStatsFromList(list)
  local min, max, count, tally = 0, 0, 0, 0
  for _, v in pairs(list) do
    if type(v) == "number" then
      if v > 0 and (v < min or min == 0) then
        min = v
      end
      if v > max then
        max = v
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
    local med = list[midKey]
    local mean = MM:round(tally/count)
    local dev = MM:StdDev(list,mean)
    return min, med, mean, max, count, MM:round(dev,2)
  end
end

local function calculateLimitor(tMed,tMax,oMed)
  local val
  if tMed and oMed then
    val = tMed + oMed
  elseif tMed then
    val = tMed * 2
  elseif oMed then
    val = oMed * 2
  end
  if tMax and val > tMax then
    val = tMax
  end
  return val
end

function MM:CalculateStatsFromTime(reID,sTime)
  local listing = self.db.realm.RE_AH_LISTINGS[reID][sTime]
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
  local tMin, tMed, tMean, tMax, tCount, tDev = MM:CalculateStatsFromList(listing)
  local oMin, oMed, oMean, oMax, oCount, oDev
  local aMin, aMed, aMean, aMax, aCount, aDev
  if listing.other ~= nil then
    oMin, oMed, oMean, oMax, oCount, oDev = MM:CalculateStatsFromList(listing.other)
  end
	-- local limitor = tMed and oMed and tMed + oMed or tMed and tMed * 2 or oMed and oMed * 2 or nil
	local limitor = calculateLimitor(tMed,tMax,oMed)
	local adjustedList = MM:CombineListsLimited(listing,listing.other,limitor)
  aMin, aMed, aMean, aMax, aCount, aDev = MM:CalculateStatsFromList(adjustedList)
  if tCount and tCount > 0 or oCount and oCount > 0 then
    stats[sTime], stats["current"] = stats[sTime] or {}, stats["current"] or {}
    local t = stats[sTime]
    local c = stats["current"]
    if tCount and tCount > 0 then
      t.tMin,t.tMed,t.tMean,t.tMax,t.tCount,t.tDev = tMin,tMed,tMean,tMax,tCount,tDev
      if c.tLast == nil or c.tLast <= sTime then
        c.tMin,c.tMed,c.tMean,c.tMax,c.tCount,c.tLast,c.tDev = tMin,tMed,tMean,tMax,tCount,sTime,tDev
      end
    end
    if oCount and oCount > 0 then
      t.oMin,t.oMed,t.oMean,t.oMax,t.oCount,t.oDev = oMin,oMed,oMean,oMax,oCount,oDev
      if c.oLast == nil or c.oLast <= sTime then
        c.oMin,c.oMed,c.oMean,c.oMax,c.oCount,c.oLast,c.oDev = oMin,oMed,oMean,oMax,oCount,sTime,oDev
      end
    end
    if oCount and oCount > 0 or tCount and tCount > 0 then
      t.aMin,t.aMed,t.aMean,t.aMax,t.aCount,t.aDev = aMin,aMed,aMean,aMax,aCount,aDev
      if c.aLast == nil or c.aLast <= sTime then
        c.aMin,c.aMed,c.aMean,c.aMax,c.aCount,c.aLast,c.aDev = aMin,aMed,aMean,aMax,aCount,sTime,aDev
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

local kIndex = {
  ["min"] = {"tMin","oMin"},
  ["med"] = {"tMed","oMed"},
  ["mean"] = {"tMean","oMean"},
  ["max"] = {"tMax","oMax"},
  ["dev"] = {"tDev","oDev"},
  ["count"] = {"tCount","oCount"}
}

function MM:LowestListed(reID,keytype)
  local current = self.db.realm.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local trink, other = current[kIndex[keytype or "min"][1]], current[kIndex[keytype or "min"][2]]
  return MM:Lowest(trink,other)
end

function MM:TotalListed(reID)
  local current = self.db.realm.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local trink, other = current[kIndex["count"][1]], current[kIndex["count"][2]]
  local total
  if current.oLast and current.tLast then
    total = trink + other
  elseif current.tLast then
    total = trink
  elseif current.oLast then
    total = other
  end
  return total
end

function MM:OrbValue(reID, keytype)
  local cost = MM:OrbCost(reID)
  local value = MM:LowestListed(reID,keytype or "min")
  return value and MM:round(value / cost,2,true) or nil
end
