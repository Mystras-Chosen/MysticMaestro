local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end


local function getAuctionInfo(i)
  local itemName, icon, _, quality, _, level, _, _, buyoutPrice, _, _, seller = GetAuctionItemInfo("list", i)
  local link = GetAuctionItemLink("list", i)
  return itemName, level, buyoutPrice, quality, seller, icon, link
end

local function isEnchantTrinketFound(itemName, level, buyoutPrice, i)
  local trinketFound = itemName and itemName:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0
  local enchantID
  if trinketFound then
    enchantID = GetAuctionItemMysticEnchant("list", i)
  end
  return trinketFound and enchantID, enchantID
end

local function isEnchantItemFound(quality, buyoutPrice, i)
  local properItem = buyoutPrice and buyoutPrice > 0 and quality and quality >= 3
  local enchantID
  if properItem then
    enchantID = GetAuctionItemMysticEnchant("list", i)
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

local displayInProgress, pendingQuery, awaitingResults, enchantToQuery, selectedScanTime

function MM:DeactivateSelectScanListener()
  awaitingResults = false
end

function MM:AsyncDisplayEnchantAuctions(enchantID)
  displayInProgress = true
  pendingQuery = true
  awaitingResults = false
  enchantToQuery = enchantID
  selectedScanTime = time()
end

local results = {}
function MM:SelectScan_AUCTION_ITEM_LIST_UPDATE()
  if awaitingResults then
    local listings = self.db.realm.RE_AH_LISTINGS
    listings[enchantToQuery][selectedScanTime] = listings[enchantToQuery][selectedScanTime] or {}
    listings[enchantToQuery][selectedScanTime]["other"] = listings[enchantToQuery][selectedScanTime]["other"] or {}
    awaitingResults = false
    wipe(results)
    for i=1, GetNumAuctionItems("list") do
      local itemName, level, buyoutPrice, quality, seller, icon, link = getAuctionInfo(i)
      if seller == nil then
        awaitingResults = true  -- TODO: timeout awaitingResults
      end
      local itemFound, enchantID = isEnchantTrinketFound(itemName, level, buyoutPrice, i)
      if itemFound and enchantToQuery == enchantID then
        table.insert(results, {
          id = i,
          seller = seller,
          buyoutPrice = buyoutPrice,
          yours = seller == UnitName("player"),
          icon = icon,
          link = link
        })
        buyoutPrice = MM:round(buyoutPrice / 10000, 4, true)
        table.insert(listings[enchantToQuery][selectedScanTime], buyoutPrice)
      else
        itemFound, enchantID = isEnchantItemFound(quality, buyoutPrice, i)
        if itemFound and enchantToQuery == enchantID then
          table.insert(results, {
            id = i,
            seller = seller,
            buyoutPrice = buyoutPrice,
            yours = seller == UnitName("player"),
            icon = icon,
            link = link
          })
          buyoutPrice = MM:round(buyoutPrice / 10000, 4, true)
          table.insert(listings[enchantToQuery][selectedScanTime]["other"], buyoutPrice)
        end
      end
    end
    table.sort(results, function(k1, k2) return k1.buyoutPrice < k2.buyoutPrice end)
    if MysticMaestroMenuAHExtension and MysticMaestroMenuAHExtension:IsVisible() then
      self:PopulateSelectedEnchantAuctions(results)
      self:CalculateREStats(enchantToQuery)
      self:PopulateGraph(enchantToQuery)
      self:ShowStatistics(enchantToQuery)
    end
  end
end

local function getMyAuctionInfo(i)
  local _, icon, _, quality, _, _, _, _, buyoutPrice = GetAuctionItemInfo("owner", i)
  local enchantID = GetAuctionItemMysticEnchant("owner", i)
  local link = GetAuctionItemLink("owner", i)
  return icon, quality, buyoutPrice, enchantID, link
end

local function collectMyAuctionsData(results)
  local numPlayerAuctions = GetNumAuctionItems("owner")
  for i=1, numPlayerAuctions do
    local icon, quality, buyoutPrice, enchantID, link = getMyAuctionInfo(i)
    if buyoutPrice and quality >= 3 and enchantID then
      results[enchantID] = results[enchantID] or {}
      table.insert(results[enchantID], {
        id = i, -- need to have owner ID so auction can be canceled
        buyoutPrice = buyoutPrice, -- need to have buyout price so canceled auction can be matched
        link = link
      })
    end
  end
end

local function collectFavoritesData(results)
  for enchantID in pairs(MM.db.realm.FAVORITE_ENCHANTS) do
    results[enchantID] = results[enchantID] or {}
  end
end

local function convertMyAuctionResults(results)
  local r = {}
  for enchantID, auctions in pairs(results) do
    table.insert(r, {
      enchantID = enchantID,
      auctions = auctions
    })
  end
  return r
end

local myAuctionResults
function MM:GetMyAuctionsResults()
  myAuctionsResults = {}
  collectMyAuctionsData(myAuctionsResults)
  collectFavoritesData(myAuctionsResults)
  return convertMyAuctionResults(myAuctionsResults)
end

local function onUpdate()
  if displayInProgress then
    if pendingQuery and CanSendAuctionQuery() then
      MM:Print("performing query of " .. MM.RE_NAMES[enchantToQuery])
      QueryAuctionItems(MM.RE_NAMES[enchantToQuery], nil, nil, 0, 0, 3, false, true, nil)
      pendingQuery = false
      awaitingResults = true
    end
  end
end

MM.OnUpdateFrame:HookScript("OnUpdate", onUpdate)

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
    -- local dev = MM:StdDev(list,mean)
    return min, med, mean, max, count
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

function MM:CalculateMarketValues(list,dev)
  local tMin, tMed, tMean, tMax, tCount = MM:CalculateStatsFromList(list)
  local oMin, oMed, oMean, oMax, oCount
  if list.other ~= nil then
    oMin, oMed, oMean, oMax, oCount = MM:CalculateStatsFromList(list.other)
  end
  if tCount and tCount > 0 or oCount and oCount > 0 then
    local limitor = calculateLimitor(tMed,oMed,tMax)
    local adjustedList = MM:CombineListsLimited(list,list.other,limitor)
    local aMin, aMed, aMean, aMax, aCount = MM:CalculateStatsFromList(adjustedList)
    local aDev = dev and MM:StdDev(adjustedList,aMean) or 0
    local total = ( tCount or 0 ) + ( oCount or 0 )
    return {Min=aMin, Med=aMed, Mean=aMean, Max=aMax, Dev=aDev, Count=aCount, Trinkets=(tCount or 0), Total=total}
  end
end

function MM:CalculateStatsFromTime(reID,sTime)
  local listing = self.db.realm.RE_AH_LISTINGS[reID][sTime]
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
  local r = MM:CalculateMarketValues(listing,true)
  if r then
    stats["daily"], stats["current"] = stats["daily"] or {}, stats["current"] or {}
    local d = stats["daily"]
    local t = {}
    local c = stats["current"]
    local dCode = MM:TimeToDate(sTime)
    t.Min,t.Med,t.Mean,t.Max,t.Count,t.Dev,t.Total,t.Trinkets = r.Min,r.Med,r.Mean,r.Max,r.Count,r.Dev,r.Total,r.Trinkets
    d[dCode] = d[dCode] or {}
    table.insert(d[dCode],t)
    if c.Last == nil or c.Last <= sTime then
      c.Min,c.Med,c.Mean,c.Max,c.Count,c.Last,c.Dev,c.Total,c.Trinkets = r.Min,r.Med,r.Mean,r.Max,r.Count,sTime,r.Dev,r.Total,r.Trinkets
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
          rAvg[val] = rAvg[val] + avg[val]
        end
      end
      for _, val in pairs(valueList) do
        -- set total average of each data point
        rAvg[val] = rAvg[val] / rCount
        stats["current"]["10d_"..val] = MM:round( rAvg[val] , 1 , true  )
      end
      -- We have finished with the Daily data and can remove it
      stats.daily = nil
    end
  end
end

function MM:CalculateAllStats()
  local listDB = self.db.realm.RE_AH_LISTINGS
  local removeList = {}
  local reID, listing, timekey, values, k
  for reID, listing in pairs(listDB) do
    for timekey, values in pairs(listing) do
      if not MM:BeyondDays(timekey) then 
        MM:CalculateStatsFromTime(reID,timekey)
      else
        table.insert(removeList,timekey)
      end
    end
    for k, timekey in pairs(removeList) do 
      listing[timekey] = nil
    end
    MM:CalculateDailyAverages(reID)
  end
end

function MM:CalculateREStats(reID)
  local listing = self.db.realm.RE_AH_LISTINGS[reID]
  local removeList = {}
  local timekey, values, k
  for timekey, values in pairs(listing) do
    if not MM:BeyondDays(timekey) then 
      MM:CalculateStatsFromTime(reID,timekey)
    else
      table.insert(removeList,timekey)
    end
  end
  for k, timekey in pairs(removeList) do 
    listing[timekey] = nil
  end
  MM:CalculateDailyAverages(reID)
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
