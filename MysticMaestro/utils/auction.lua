﻿local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

-- Upvalue global functions called on every frame
local GetTime, CanSendAuctionQuery = GetTime, CanSendAuctionQuery

function MM:GetAuctionInfo(i)
  local itemName, icon, _, quality, _, level, _, _, buyoutPrice, _, _, seller = GetAuctionItemInfo("list", i)
  local link = GetAuctionItemLink("list", i)
  local duration = GetAuctionItemTimeLeft("list", i)
  return itemName, level, buyoutPrice, quality, seller, icon, link, duration
end

function MM:IsEnchantItemFound(itemName, quality, level, buyoutPrice, i)
  local trinketFound = MM:IsTrinket(itemName, level)
  local enchantID, mysticScroll = GetAuctionItemMysticEnchant("list", i)
  enchantID, mysticScroll = MM:StandardizeEnchantID(itemName, enchantID)
  local properItem = buyoutPrice and buyoutPrice > 0 and ((quality and quality >= 3) or mysticScroll) 
  return properItem and enchantID, enchantID, trinketFound
end

function MM:CollectSpecificREData(scanTime, expectedEnchantID)
  local listings = self.data.RE_AH_LISTINGS
  local enchantFound = false
  local numBatchAuctions = GetNumAuctionItems("list")
  local temp = ":"
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local itemName, level, buyoutPrice, quality = MM:GetAuctionInfo(i)
      local itemFound, enchantID, trinketFound = MM:IsEnchantItemFound(itemName,quality,level,buyoutPrice,i)
      if itemFound and enchantID == expectedEnchantID then
        temp = trinketFound and buyoutPrice .. "," .. temp or temp .. buyoutPrice .. ","
        enchantFound = true
      end
    end
    if enchantFound then
      listings[expectedEnchantID][scanTime] = temp
    end
  end
  return enchantFound
end

local pendingQuery, awaitingResults, timeoutTime, enchantToQuery, selectedScanTime

function MM:InitializeSingleScan(enchantID)
  pendingQuery = true
  awaitingResults = false
  timeoutTime = nil
  enchantToQuery = enchantID
  selectedScanTime = time()
end

function MM:CancelSingleScan()
  pendingQuery = false
  awaitingResults = false
  timeoutTime = nil
  enchantToQuery = nil
  selectedScanTime = nil
end

function MM:AwaitingSingleScanResults()
  return awaitingResults
end

local results = {}

function MM:GetSingleScanResults()
  return results
end

function MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
  if awaitingResults then
    local currentTime = GetTime()
    self.lastSelectScanTime = currentTime
    local listings, reID, sTime = self.data.RE_AH_LISTINGS, enchantToQuery, selectedScanTime
    local listingData = listings[reID]
    results = {}
    local temp = ":"
    awaitingResults = false
    for i=1, GetNumAuctionItems("list") do
      local itemName, level, buyoutPrice, quality, seller, icon, link, duration = MM:GetAuctionInfo(i)
      if seller == nil and currentTime < timeoutTime then
        awaitingResults = true
      end
      local itemFound, enchantID, trinketFound = MM:IsEnchantItemFound(itemName,quality,level,buyoutPrice,i)
      if itemFound and reID == enchantID then
        table.insert(results, {
          id = i,
          enchantID = enchantID,
          seller = seller,
          buyoutPrice = buyoutPrice,
          yours = seller == UnitName("player"),
          icon = icon,
          link = link,
          duration = duration
        })
        temp = trinketFound and buyoutPrice .. "," .. temp or temp .. buyoutPrice .. ","
      end
    end
    listings[reID][sTime] = temp
    self:CalculateREStats(reID, listingData)
    table.sort(results, function(k1, k2) return k1.buyoutPrice < k2.buyoutPrice end)
    if self:IsEmbeddedMenuOpen() and not self.AutomationManager:IsRunning() then
      self:PopulateSelectedEnchantAuctions(results)
      self:SetMyAuctionLastScanTime(reID)
      self:SetMyAuctionBuyoutStatus(reID)
      self:RefreshMyAuctionsScrollFrame()
      self:EnableListButton()
      self:EnableAuctionRefreshButton()
      self:PopulateGraph(reID)
      self:ShowStatistics(reID)
    end
    timeoutTime = (awaitingResults and currentTime < timeoutTime) and timeoutTime or nil
  end
end

local function getMyAuctionInfo(i)
  local itemName, _, _, quality, _, _, _, _, buyoutPrice = GetAuctionItemInfo("owner", i)
  local enchantID, mysticScroll = GetAuctionItemMysticEnchant("owner", i)
  enchantID, mysticScroll = MM:StandardizeEnchantID(itemName, enchantID)
  local link = GetAuctionItemLink("owner", i)
  -- local duration = GetAuctionItemTimeLeft("owner", i)
  local iLevel, _, _, _, _, _, _, vendorPrice = select(4,GetItemInfo(link))
  local allowedQuality, allowedItemLevel, allowedVendorPrice
  local allowed = mysticScroll or MM:AllowedItem(quality, iLevel, vendorPrice)
  return buyoutPrice, enchantID, link, allowed
end

local function collectMyAuctionData(results)
  local numPlayerAuctions = GetNumAuctionItems("owner")
  for i=1, numPlayerAuctions do
    local buyoutPrice, enchantID, link, allowed = getMyAuctionInfo(i)
    if buyoutPrice and allowed and enchantID then
      results[enchantID] = results[enchantID] or { auctions = {} }
      table.insert(results[enchantID].auctions, {
        id = i, -- need to have owner ID so auction can be canceled
        buyoutPrice = buyoutPrice, -- need to have buyout price so canceled auction can be matched
        link = link
      })
    end
  end
end

local function collectFavoritesData(results)
  for enchantID in pairs(MM.db.realm.FAVORITE_ENCHANTS) do
    results[enchantID] = results[enchantID] or { auctions = {} }
  end
end

local function transferLastScanTime(fromResults, toResults)
  for enchantID, result in pairs(toResults) do
    if fromResults[enchantID] then
      result.lastScanTime = fromResults[enchantID].lastScanTime
      result.lowestBuyout = fromResults[enchantID].lowestBuyout
    end
  end
end

local function inferListedAuctionResults(newResults, listedAuctionEnchantID)
  newResults[listedAuctionEnchantID].lastScanTime = MM.lastSelectScanTime
  local listedEnchantAuctionResults = MM:GetSelectedEnchantAuctionsResults()
  if #listedEnchantAuctionResults > 0 then
    newResults[listedAuctionEnchantID].lowestBuyout = listedEnchantAuctionResults[1].buyoutPrice > MM.listedAuctionBuyoutPrice or listedEnchantAuctionResults[1].yours
  else
    newResults[listedAuctionEnchantID].lowestBuyout = true
  end
end

local myAuctionResults

function MM:GetMyAuctionResults()
  return myAuctionResults
end

function MM:CacheMyAuctionResults(listedAuctionEnchantID)
  local newResults = {}
  collectMyAuctionData(newResults)
  collectFavoritesData(newResults)
  if myAuctionResults then
    transferLastScanTime(myAuctionResults, newResults)
  end
  if listedAuctionEnchantID and newResults[listedAuctionEnchantID] then
    inferListedAuctionResults(newResults, listedAuctionEnchantID)
  end
  myAuctionResults = newResults
  return myAuctionResults
end

local function convertMyAuctionResults(results)
  local r = {}
  for enchantID, result in pairs(results) do
    table.insert(r, {
      enchantID = enchantID,
      lastScanTime = result.lastScanTime,
      lowestBuyout = result.lowestBuyout,
      auctions = result.auctions
    })
  end
  return r
end

function MM:GetSortedMyAuctionResults()
  if not myAuctionResults then
    self:CacheMyAuctionResults()
  end
  local sortableMyAuctionResults = convertMyAuctionResults(myAuctionResults)
  table.sort(sortableMyAuctionResults,
    function(r1, r2)
      return #r1.auctions > #r2.auctions
    end
  )
  return sortableMyAuctionResults
end

function MM:SetMyAuctionBuyoutStatus(enchantID)
  local result = self:GetMyAuctionResults()[enchantID]
  if result then
    local selectedAuctionResults = self:GetSelectedEnchantAuctionsResults()
    result.lowestBuyout = #selectedAuctionResults > 0 and selectedAuctionResults[1].yours
  end
end

local lastScanTimerHandles = {} -- store handles in case enchant is scanned again to reset callback function timer

local function updateColorCallback(self)
  if MM:IsEmbeddedMenuOpen() then
    MM:RefreshMyAuctionsScrollFrame()
    lastScanTimerHandles[self] = nil
  end
end

function MM:SetMyAuctionLastScanTime(myAuctionEnchantID)
  local result = self:GetMyAuctionResults()[myAuctionEnchantID]
  if result then
    result.lastScanTime = GetTime()
    for handle, enchantID in pairs(lastScanTimerHandles) do
      if enchantID == myAuctionEnchantID then
        lastScanTimerHandles[handle] = nil
        handle:Cancel()
      end
    end
    local waitTimePeriod = self.db.realm.OPTIONS.myTimeout * 60
    lastScanTimerHandles[Timer.NewTimer(waitTimePeriod, updateColorCallback)] = myAuctionEnchantID
  end
end

function MM:GetLastScanTimeColor(result)
  if #result.auctions > 0 then
    local waitTimePeriod = self.db.realm.OPTIONS.myTimeout * 60
    local veryLongTimePeriod = self.db.realm.OPTIONS.myCutoff * 60
    local cheapestAuction = self:GetSelectedEnchantAuctionsResults()[1]
    -- subtract 1 because callback is called too early for some reason
    if not result.lowestBuyout or (result.lastScanTime or 0) + veryLongTimePeriod - 1 < GetTime() then
      return "ff0000"
    -- subtract 1 because callback is called too early for some reason
    elseif result.lastScanTime + waitTimePeriod - 1 < GetTime() then
      lastScanTimerHandles[Timer.NewTimer(veryLongTimePeriod - waitTimePeriod, updateColorCallback)] = result.enchantID
      return "ffff00"
    else
      return "00ff00"
    end
  else
    return "777777"
  end
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if pendingQuery and CanSendAuctionQuery() then
      QueryAuctionItems(MM.RE_NAMES[enchantToQuery], nil, nil, 0, 0, 3, false, true, nil)
      pendingQuery = false
      awaitingResults = true
      timeoutTime = GetTime() + 1
    end
    if timeoutTime and GetTime() >= timeoutTime then
      MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
    end
  end
)

---------------------------------
--   Auction Stats functions   --
---------------------------------

function MM:AuctionListStringToList(listString)
  local left, right = string.split(":", listString)
  local list = { ["other"] = {}}
  for buyout in left:gmatch("%d+") do
    table.insert(list, tonumber(buyout))
  end
  for buyout in right:gmatch("%d+") do
    table.insert(list.other, tonumber(buyout))
  end
  return list
end

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
    local midKey = count > 1 and MM:Round(count/2) or 1
    sort(list)
    local med = list[midKey]
    local mean = MM:Round(tally/count)
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
    local aDev = dev and MM:Round(MM:StdDev(adjustedList,aMean),2) or 0
    local total = ( tCount or 0 ) + ( oCount or 0 )
    return {Min=aMin, Med=aMed, Mean=aMean, Max=aMax, Count=aCount, Trinkets=(tCount or 0), Total=total, Dev=aDev}
  end
end

local function serializeScanAvg(scanObj)
  local string = scanObj.Min .. ";" .. scanObj.Med .. ";" .. scanObj.Mean .. ";" .. scanObj.Max .. ";" .. scanObj.Count .. ";" .. scanObj.Trinkets .. ";" .. scanObj.Total .. ";" .. scanObj.Dev or ""
  return string
end

function MM:DeserializeScanAvg(scanStr)
  local Min, Med, Mean, Max, Count, Trinkets, Total, Dev = string.split(";",scanStr)
  return {Min=Min, Med=Med, Mean=Mean, Max=Max, Count=Count, Trinkets=Trinkets, Total=Total, Dev=Dev}
end

function MM:CalculateStatsFromTime(reID,sTime)
  local listing = self:AuctionListStringToList(self.data.RE_AH_LISTINGS[reID][sTime])
  local stats = self.data.RE_AH_STATISTICS[reID]
  local r = MM:CalculateMarketValues(listing,true)
  if not r then return end
  stats["dailyTemp"], stats["current"] = stats["dailyTemp"] or {}, stats["current"] or {}
  local d = stats["dailyTemp"]
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

local valueList = { "Min", "Med", "Mean", "Max", "Count", "Dev", "Total", "Trinkets" }

local function calcDayStats(scans)
  local avg, count = {}, 0
  for _, val in pairs(valueList) do avg[val] = 0 end
  for k, scan in ipairs(scans) do
    for _, val in pairs(valueList) do avg[val] = avg[val] + scan[val] end
    count = count + 1
  end
  for _, val in pairs(valueList) do
    avg[val] = avg[val] / count
  end
  return avg
end

local function pruneDailyData(reID)
  local stats = MM.data.RE_AH_STATISTICS[reID]
  if not stats then return end
  local daily = stats["daily"]
  if not daily then return end
  table.sort(daily, function(k1, k2) return k1 > k2 end)
  local removeList = {}
  local ind = 0
  for k, _ in pairs(daily) do
    ind = ind + 1
    if ind > 10 then
      table.insert(removeList,k)
    end
  end
  for _, k in ipairs(removeList) do
    daily[k] = nil
  end
end

function MM:CalculateDailyAverages(reID)
  local stats = self.data.RE_AH_STATISTICS[reID]
  if not stats then return end
  local dailyTemp = stats["dailyTemp"]
  if not dailyTemp then return end
  stats["daily"] = stats["daily"] or {}
  local daily = stats["daily"]
  -- Serialize the temporary listing data into the daily tally
  for dCode, scans in pairs(dailyTemp) do
    local avg = calcDayStats(scans)
    stats["daily"][dCode] = serializeScanAvg(avg)
  end
  pruneDailyData(reID)
  -- initialize the rolling average
  local rAvg, rCount = {}, 0
  for _, val in pairs(valueList) do rAvg[val] = 0 end
  -- take values from each day and average together
  for dCode, data in pairs(daily) do
    local avg = MM:DeserializeScanAvg(data)
    for _, val in pairs(valueList) do
      rAvg[val] = rAvg[val] + avg[val]
    end
    rCount = rCount + 1
  end
  -- take the totals and set as the current 10 day values
  for _, val in pairs(valueList) do
    rAvg[val] = rAvg[val] / rCount
    stats["current"]["10d_"..val] = MM:Round( rAvg[val] , 1 , true  )
  end
  stats.dailyTemp = nil
end

function MM:CalculateAllStats()
  local listings = self.data.RE_AH_LISTINGS
  for reID, listingData in pairs(listings) do
    self:CalculateREStats(reID, listingData)
  end
end

function MM:CalculateREStats(reID, listingData)
  local remove = {}
  local today = MM:TimeToDate(time())
  for timeKey in pairs(listingData) do
    self:CalculateStatsFromTime(reID, timeKey)
    -- if the key isnt today, we add to remove list
    local compare = MM:TimeToDate(timeKey)
    if today ~= compare then table.insert(remove,timeKey) end
  end
  for _, timeKey in pairs(remove) do
    listingData[timeKey] = nil
  end
  self:CalculateDailyAverages(reID)
end

function MM:LowestListed(reID,keytype)
  local current = self.data.RE_AH_STATISTICS[reID].current
  if not current then return nil end
  local price = current[keytype or "Min"]
  return price
end

function MM:OrbValue(reID, keytype)
  local cost = MM:OrbCost(reID)
  local value = MM:LowestListed(reID,keytype)
  return value and MM:Round(value / cost,2,true) or nil
end

---------------------------------------
--   Auction Interaction functions   --
---------------------------------------

StaticPopupDialogs["MM_BUYOUT_AUCTION"] = {
  text = BUYOUT_AUCTION_CONFIRMATION,
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self)
    local data = MM:GetSelectedSelectedEnchantAuctionData()
      PlaceAuctionBid("list", data.id, data.buyoutPrice)
      MM:RefreshSelectedEnchantAuctions(true)
  end,
  OnShow = function(self)
    local data = MM:GetSelectedSelectedEnchantAuctionData()
    MoneyFrame_Update(self.moneyFrame, data.buyoutPrice)
  end,
  hasMoneyFrame = 1,
  showAlert = 1,
  timeout = 0,
  exclusive = 1,
  hideOnEscape = 1,
  --enterClicksFirstButton = 1  -- causes taint for some reason
}

function MM:BuyoutAuction(id)
  SetSelectedAuctionItem("list", id)
  if MM.db.realm.OPTIONS.confirmBuyout then
    StaticPopup_Show("MM_BUYOUT_AUCTION")
  else
    local data = MM:GetSelectedSelectedEnchantAuctionData()
    PlaceAuctionBid("list", data.id, data.buyoutPrice)
    MM:RefreshSelectedEnchantAuctions(true)
  end

end

StaticPopupDialogs["MM_CANCEL_AUCTION"] = {
	text = CANCEL_AUCTION_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		CancelAuction(GetSelectedAuctionItem("owner"))
    MM:RefreshSelectedEnchantAuctions(true)
	end,
	OnShow = function(self)
    self.text:SetText(CANCEL_AUCTION_CONFIRMATION)
	end,
	showAlert = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
  --enterClicksFirstButton = 1  -- causes taint for some reason
}

-- returns the first id that matches enchantID and buyoutPrice
local function findOwnerAuctionID(enchantID, buyoutPrice)
  local results = MM:GetSortedMyAuctionResults()
  for _, result in ipairs(results) do
    if result.enchantID == enchantID then
      for _, auction in ipairs(result.auctions) do
        if auction.buyoutPrice == buyoutPrice then
          return auction.id
        end
      end
    end
  end
  print("this shouldn't print")
  return nil
end

function MM:CancelAuction(enchantID, buyoutPrice)
  local auctionID = findOwnerAuctionID(enchantID, buyoutPrice)
  SetSelectedAuctionItem("owner", auctionID)
  if MM.db.realm.OPTIONS.confirmCancel then
    StaticPopup_Show("MM_CANCEL_AUCTION")
  else
    CancelAuction(GetSelectedAuctionItem("owner"))
    MM:RefreshSelectedEnchantAuctions(true)
  end
end

function MM:StartAuction(enchantID, price)
  if CalculateAuctionDeposit(1, 1) > GetMoney() then
    UIErrorsFrame:AddMessage("|cffff0000Not enough money for a deposit|r")
    return false
  else
    StartAuction(price, price, 1, 1, 1)
    self.listedAuctionEnchantID = enchantID
    self.listedAuctionBuyoutPrice = price
    return true
  end
end

local startingPrice, enchantToList
StaticPopupDialogs["MM_LIST_AUCTION"] = {
	text = "List auction for the following amount?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
    local sellPrice = MoneyInputFrame_GetCopper(self.moneyInputFrame)
    if MM:StartAuction(enchantToList, sellPrice) then
      MM:RefreshSelectedEnchantAuctions(true)
    end
	end,
	OnShow = function(self)
    MoneyInputFrame_SetCopper(self.moneyInputFrame, startingPrice)
	end,
  EditBoxOnEnterPressed = function(self)
    MoneyInputFrame_ClearFocus(self:GetParent())
  end,
  OnCancel = function(self)
    ClickAuctionSellItemButton()
    ClearCursor()
  end,
  hasMoneyInputFrame = 1,
	showAlert = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
  enterClicksFirstButton = 1  -- doesn't cause taint for some reason
}

local function findSellableItemWithEnchantID(enchantID,listMode)
  local items = {trinket = {},other = {}}
  for bagID=0, 4 do
    for slotIndex=1, GetContainerNumSlots(bagID) do
      local _,count,_,quality,_,_,item = GetContainerItemInfo(bagID, slotIndex)
      local name, reqLevel, vendorPrice, mysticScroll, allowedQuality, allowedItemLevel, allowedVendorPrice
      if item then
        name, _, _, iLevel, reqLevel, _, _, _, _, _, vendorPrice = GetItemInfo(item)
        mysticScroll = name:match("^Mystic Scroll: (.*)")
      end
      -- we have an item, with at least 3 quality and is not soulbound
      if item and (mysticScroll or (MM:AllowedItem(quality, iLevel, vendorPrice) and not MM:IsSoulbound(bagID, slotIndex))) then
        local re
        if mysticScroll then
          re = MM.RE_LOOKUP[mysticScroll]
        else
          re = GetREInSlot(bagID, slotIndex)
        end
        if re and not MYSTIC_ENCHANTS[re] and MM.RE_ID[re] then
          re = MM.RE_ID[re]
        end
      
        -- the item matches our specified RE, and is sorted into trinket or not
        if re == enchantID then
          local _,_,_,_,reqLevel,_,_,_,_,_,vendorPrice = GetItemInfo(item)
          local istrinket = MM:IsTrinket(name,reqLevel)
          for i=1, count do
            table.insert(istrinket and items.trinket or items.other, istrinket and {bagID, slotIndex} or {bagID, slotIndex, (vendorPrice or 0)})
          end
        end
      end
    end
  end
  if listMode then
    local itemList = {}
    for _, entry in pairs(items.trinket) do
      table.insert(itemList,entry)
    end
    for _, entry in pairs(items.other) do
      table.insert(itemList,entry)
    end
    return itemList ~= {} and itemList or false
  elseif #items.trinket > 0 then
    return unpack(items.trinket[1])
  elseif #items.other > 0 then
    table.sort(items.other,function(k1, k2) return MM:Compare(items.other[k1].vendorPrice, items.other[k2].vendorPrice, ">") end)
    return unpack(items.other[1])
  else
    return
  end
end

local bagClear, isFetching, fetchBag, fetchSlot, autoPosting, autoPostingTimer
local auctionQueue = {}
local auctionQueueAdded = {}
function MM:ClearAuctionItem()
  ClearCursor()
  if GetAuctionSellItemInfo() then
      ClickAuctionSellItemButton()
      ClearCursor()
      return GetAuctionSellItemInfo() and false or true
  end
  return true
end

function MM:PlaceItemInAuctionSlot(bagID, slotIndex)
  PickupContainerItem(bagID, slotIndex)
  ClickAuctionSellItemButton()
  ClearCursor()
end

local function clearQueueObjects()
  autoPosting = nil
  auctionQueueAdded = {}
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if autoPosting and not bagClear and not isFetching then
      if #auctionQueue <= 0 then
        if not autoPostingTimer then
          autoPostingTimer = Timer.NewTimer(5, clearQueueObjects)
        end
        return
      elseif autoPostingTimer then
        autoPostingTimer:Cancel()
        autoPostingTimer = nil
      end
      local nextItem = table.remove(auctionQueue)
      bagClear = true
      fetchBag, fetchSlot = nextItem[1], nextItem[2]
      startingPrice = nextItem.price
      enchantToList = nextItem.enchantID
    elseif bagClear then
      if MM:ClearAuctionItem() then
        bagClear = nil
        isFetching = true
      end
    elseif isFetching then
      if not GetAuctionSellItemInfo() then
        MM:PlaceItemInAuctionSlot(fetchBag, fetchSlot)
      else
        isFetching = nil
        fetchBag = nil
        fetchSlot = nil
        if autoPosting then
            MM:StartAuction(enchantToList, startingPrice)
        else
          local modKey = IsModifierKeyDown()
          if (MM.db.realm.OPTIONS.confirmList and not modKey)
          or (not MM.db.realm.OPTIONS.confirmList and modKey) then
            StaticPopup_Show("MM_LIST_AUCTION")
          elseif MM:StartAuction(enchantToList, startingPrice) then
            MM:RefreshSelectedEnchantAuctions(true)
          end
        end
      end
    end
  end
)

function MM:ListAuction(enchantID, price)
  local bagID, slotIndex = findSellableItemWithEnchantID(enchantID)
  if bagID then
    MM:CloseAuctionPopups()
    bagClear = true
    fetchBag, fetchSlot = bagID, slotIndex
    startingPrice = price
    enchantToList = enchantID
  else
    print("No item found")
  end
end

function MM:ListAuctionQueue(enchantID,price)
  if not auctionQueueAdded[enchantID] then
    local itemList = findSellableItemWithEnchantID(enchantID,true)
    for _, entry in ipairs(itemList) do
      entry.price = price
      entry.enchantID = enchantID
      table.insert(auctionQueue,entry)
    end
    autoPosting = true
    auctionQueueAdded[enchantID] = true
  end
end

function MM:CloseAuctionPopups()
  StaticPopup_Hide("MM_BUYOUT_AUCTION")
  StaticPopup_Hide("MM_CANCEL_AUCTION")
  StaticPopup_Hide("MM_LIST_AUCTION")
  if GetAuctionSellItemInfo() then
    ClickAuctionSellItemButton()
    ClearCursor()
  end
end

local refreshInProgress, restoreInProgress, refreshList, restoreList
local enchantToRestore
function MM:RefreshSelectedEnchantAuctions(waitForEvent)
  if waitForEvent then
    refreshInProgress = true
  else
    refreshList = true
  end
  self:DisableListButton()
  self:DisableAuctionRefreshButton()
  enchantToRestore = MM:GetSelectedEnchantButton().enchantID
end

-- entry point for refresh after buying or cancelling an auction
function MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
  if refreshInProgress then
    refreshInProgress = false
    refreshList = true
  end
  if restoreInProgress then
    restoreInProgress = false
    restoreList = true
  end
end

-- entry point for refresh after listing an auction
function MM:List_AUCTION_OWNED_LIST_UPDATE()
  if refreshInProgress then
    refreshInProgress = false
    refreshList = true
  end
end

local function enchantToRestoreIsStillSelected()
  local selectedEnchantButton = MM:GetSelectedEnchantButton()
  return selectedEnchantButton and enchantToRestore == MM:GetSelectedEnchantButton().enchantID
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if refreshList and CanSendAuctionQuery() then
      if enchantToRestoreIsStillSelected() then
        QueryAuctionItems("zzxxzzy")
        restoreInProgress = true
      end
      refreshList = false
    end
    if restoreList and CanSendAuctionQuery() then
      if enchantToRestoreIsStillSelected() then
        MM:InitializeSingleScan(enchantToRestore)
        QueryAuctionItems(MM.RE_NAMES[enchantToRestore], nil, nil, 0, 0, 3, false, true, nil)
        local results = MM:GetSortedMyAuctionResults()
        for _, result in ipairs(results) do
          if enchantToRestore == result.enchantID then
            MM:SetSelectedMyAuctionData(result)
          end
        end
      end
      restoreList = false
    end
  end
)

local getAllLastAvailableTime = 0
MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    getAllLastAvailableTime = select(2, CanSendAuctionQuery()) and GetTime() or getAllLastAvailableTime
  end
)

local function getAllScanInvoked(...)
  return select(10, ...)
end

local function getAllAvailableRightBeforeQuery()
  return GetTime() < getAllLastAvailableTime + .1
end

local function queryPosthook(...)
  if getAllScanInvoked(...) and getAllAvailableRightBeforeQuery() then
    MM.db.char.lastGetAllScanTime = time()
  end
end

hooksecurefunc("QueryAuctionItems", queryPosthook)