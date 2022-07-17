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

local function calculateLimitor(tMed,oMed,tMax)
  local val
  if tMed and oMed then
    val = tMed + oMed
  elseif tMed then
    val = tMed * 2
  elseif oMed then
    val = oMed * 2
  end
  if val and tMax and val > tMax then
    val = tMax
  end
  return val
end

function MM:CalculateStatsFromTime(reID,sTime)
  local listing = self.db.realm.RE_AH_LISTINGS[reID][sTime]
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
  local tMin, tMed, tMean, tMax, tCount, tDev = MM:CalculateStatsFromList(listing)
  local oMin, oMed, oMean, oMax, oCount, oDev
  if listing.other ~= nil then
    oMin, oMed, oMean, oMax, oCount, oDev = MM:CalculateStatsFromList(listing.other)
  end
  if tCount and tCount > 0 or oCount and oCount > 0 then
    local limitor = calculateLimitor(tMed,oMed,tMax)
    local adjustedList = MM:CombineListsLimited(listing,listing.other,limitor)
    local aMin, aMed, aMean, aMax, aCount, aDev = MM:CalculateStatsFromList(adjustedList)
    stats["daily"], stats["current"] = stats["daily"] or {}, stats["current"] or {}
    local d = stats["daily"]
    local t = {}
    local c = stats["current"]
    local dCode = MM:TimeToDate(sTime)
    local total = ( tCount or 0 ) + ( oCount or 0 )
    t.Min,t.Med,t.Mean,t.Max,t.Count,t.Dev,t.Total,t.Trinkets = aMin,aMed,aMean,aMax,aCount,aDev,total,tCount or 0
    d[dCode] = d[dCode] or {}
    table.insert(d[dCode],t)
    if c.Last == nil or c.Last <= sTime then
      c.Min,c.Med,c.Mean,c.Max,c.Count,c.Last,c.Dev,c.Total,c.Trinkets = aMin,aMed,aMean,aMax,aCount,sTime,aDev,total,tCount or 0
    end
  end
end

local valueList = { "Min", "Med", "Mean", "Max", "Count", "Dev", "Total", "Trinkets" }

function MM:CalculateDailyAverages(reID)
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
  if stats then
    local daily = stats["daily"]
    if daily then
      local rAvg, rCount = {}, 0
      -- setup rolling average obj
      for _, val in pairs(valueList) do rAvg[val] = 0 end
      for dCode, scans in pairs(daily) do
        local avg, count, remove = {}, 0, {}
        rCount = rCount + 1
        for _, val in pairs(valueList) do avg[val] = 0 end
        for k, scan in ipairs(scans) do
          -- setup daily average
          for _, val in pairs(valueList) do avg[val] = avg[val] + scan[val] end
          count = count + 1
          table.insert(remove,k)
        end
        for _, val in pairs(valueList) do
          -- set each day average value
          avg[val] = avg[val] / count
          scans[val] = MM:round( avg[val], 2 , true  )
          rAvg[val] = rAvg[val] + avg[val]
        end
        for _, val in ipairs(remove) do table.remove(scans,val) end
      end
      for _, val in pairs(valueList) do
        -- set total average of each data point
        rAvg[val] = rAvg[val] / rCount
        stats["current"]["10d_"..val] = MM:round( rAvg[val] , 1 , true  )
      end
    end
  end
end

function MM:CalculateAllStats()
  local listDB = self.db.realm.RE_AH_LISTINGS
  local reID, listing, timekey, values
  for reID, listing in pairs(listDB) do
    for timekey, values in pairs(listing) do
      MM:CalculateStatsFromTime(reID,timekey)
    end
    MM:CalculateDailyAverages(reID)
  end
end

function MM:LowestListed(reID,keytype)
  local current = self.db.realm.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local price = current[keytype or "Min"]
  return price
end

function MM:OrbValue(reID, keytype)
  local cost = MM:OrbCost(reID)
  local value = MM:LowestListed(reID,keytype)
  return value and MM:round(value / cost,2,true) or nil
end
