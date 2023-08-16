local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

-- API for other addons to get information about an RE
function Maestro(reID)
  return MM:DeepClone(MM:StatObj(reID))
end

function MM:Round(num, numDecimalPlaces, alwaysDown)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + (alwaysDown and 0 or 0.5)) / mult
end

function MM:Compare(a,b,comparitor,bigger)
  a = a or math.huge
  b = b or math.huge
  if a == math.huge or b == math.huge then
    if bigger then
      return a > b
    else
      return a < b
    end
  end
  
  if comparitor == ">" then
    return a > b
  elseif comparitor == ">=" then
    return a >= b
  elseif comparitor == "<" then
    return a < b
  elseif comparitor == "<=" then
    return a <= b
  elseif comparitor == "==" then
    return a == b
  elseif comparitor == "~=" then
    return a ~= b
  end
end

local function findAboveMin(list)
  for _, v in pairs(list) do
    if v.buyoutPrice >= MM.db.realm.OPTIONS.postMin * 10000 then
      return MM:PriceCorrection(v,list)
    end
  end
  return MM.db.realm.OPTIONS.postDefault * 10000, true
end

local function ifUnder(obj,list)
  local fetched
  if MM.db.realm.OPTIONS.postIfUnder == "UNDERCUT" then
    return obj.buyoutPrice, obj.yours
  elseif MM.db.realm.OPTIONS.postIfUnder == "IGNORE" then
    return findAboveMin(list)
  elseif MM.db.realm.OPTIONS.postIfUnder == "DEFAULT" then
    return MM.db.realm.OPTIONS.postDefault * 10000, true
  elseif MM.db.realm.OPTIONS.postIfUnder == "MAX" then
    return MM.db.realm.OPTIONS.postMax * 10000, true
  elseif MM.db.realm.OPTIONS.postIfUnder == "KEEP" then
    return false
  elseif MM.db.realm.OPTIONS.postIfUnder == "MEAN10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Mean"] or MM.db.realm.OPTIONS.postDefault * 10000, true
  elseif MM.db.realm.OPTIONS.postIfUnder == "MEDIAN10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Med"] or MM.db.realm.OPTIONS.postDefault * 10000, true
  elseif MM.db.realm.OPTIONS.postIfUnder == "MAX10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Max"] or (MM.db.realm.OPTIONS.postMax * 10000), true
  end
end

local function ifOver(obj)
  local fetched
  if MM.db.realm.OPTIONS.postIfOver == "UNDERCUT" then
    return obj.buyoutPrice, obj.yours
  elseif MM.db.realm.OPTIONS.postIfOver == "DEFAULT" then
    return MM.db.realm.OPTIONS.postDefault * 10000, true
  elseif MM.db.realm.OPTIONS.postIfOver == "MAX" then
    return MM.db.realm.OPTIONS.postMax * 10000, true
  elseif MM.db.realm.OPTIONS.postIfOver == "MEAN10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Mean"] or (MM.db.realm.OPTIONS.postDefault * 10000), true
  elseif MM.db.realm.OPTIONS.postIfOver == "MEDIAN10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Med"] or (MM.db.realm.OPTIONS.postDefault * 10000), true
  elseif MM.db.realm.OPTIONS.postIfOver == "MAX10" then
    fetched = MM:StatObj(obj.SpellID)
    return fetched and fetched["10d_Max"] or (MM.db.realm.OPTIONS.postMax * 10000), true
  end
end

-- When listing an auction, we determine what kind of undercut to perform.
-- Using the two functions from above, we determine how to price the enchant.
function MM:PriceCorrection(obj,list)
  if obj.buyoutPrice < MM.db.realm.OPTIONS.postMin * 10000 then
    return ifUnder(obj,list)
  elseif obj.buyoutPrice > MM.db.realm.OPTIONS.postMax * 10000 then
    return ifOver(obj)
  else
    return obj.buyoutPrice, obj.yours
  end
end

local EnchantQualitySettings = {
  [5] = "\124cFFFF8000", -- 255, 128, 0
  [4] = "\124cFFA335EE", -- 163, 53, 238
  [3] = "\124cFF0070DD", -- 0, 112, 221
  [2] = "\124cFF1EFF00", -- 30, 255, 0
}

-- Creates a Quality colored item link for use in text
function MM:ItemLinkRE(SpellID)
  local enchantData = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
  local quality = Enum.EnchantQualityEnum[enchantData.Quality]
  local color = EnchantQualitySettings[quality]
  return color .. "\124Hspell:" .. enchantData.SpellID .. "\124h[" .. enchantData.SpellName .. "]\124h\124r"
end

-- Inhouse version of the previous function
function MM:GetREInSlot(bag,slot)
  local itemLink = select(7, GetContainerItemInfo(bag, slot))
  if not itemLink then return end
  local itemID = GetItemInfoFromHyperlink(itemLink)
  if not itemID then return end
  local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
  return enchant and enchant.SpellID
end

-- Find Untarnished Mystic Scroll to use in crafting
function MM:FindBlankScrolls()
  for bagID=0, 4 do
    for containerIndex=1, GetContainerNumSlots(bagID) do
      local itemLink = select(7, GetContainerItemInfo(bagID, containerIndex))
      if itemLink then
        local itemName = GetItemInfo(itemLink)
        if MM:IsUntarnished(itemName) then
          return bagID, containerIndex
        end
      end
    end
  end
end

-- split up cache by bagID so BAG_UPDATE doesn't have to refresh the entire cache every time
local sellableREsInBagsCache = setmetatable({ [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }, {
  __index = function(t, SpellID)
    local count = 0
    for bagID=0, 4 do
      count = count + (t[bagID][SpellID] or 0)
    end
    return count
  end
})

-- get number of sellable REs with that ID in bags
-- pass "blanks" to get the number of blank trinkets in bags
function MM:CountSellableREInBags(SpellID)
  return sellableREsInBagsCache[SpellID]
end

-- Create a cache of the scrolls available in bags
function MM:UpdateSellableREsCache(bagID)
  local newContainerCache = {}
  local itemName
  for containerIndex=1, GetContainerNumSlots(bagID) do
    local _,count,_,_,_,_,itemLink = GetContainerItemInfo(bagID, containerIndex)
    local SpellID = MM:GetREInSlot(bagID, containerIndex)
    if itemLink then
      itemName = GetItemInfo(itemLink)
      if SpellID then
        newContainerCache[SpellID] = (newContainerCache[SpellID] or 0) + (count or 1)
      elseif MM:IsUntarnished(itemName) then
        newContainerCache["blanks"] = (newContainerCache["blanks"] or 0) + 1
      end
    end
  end
  sellableREsInBagsCache[bagID] = newContainerCache
end

-- cache helper
function MM:ResetSellableREsCache()
  for bagID=0, 4 do
    self:UpdateSellableREsCache(bagID)
  end
end

-- cache helper
function MM:GetSellableREs()
  local sellableREs = {}
  for bagID=0, 4 do
    for SpellID, count in pairs(sellableREsInBagsCache[bagID]) do
      if SpellID ~= "blanks" then
        sellableREs[SpellID] = count
      end
    end
  end
  return sellableREs
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

function MM:DaysAgoString(stamp)
  local string = ""
  if stamp == 0 then return "No Scan Data" end
  local dif = MM:CompareTime(time(),stamp)
  if dif.year > 0 then
    string = string .. dif.year .. " year" .. (dif.year > 1 and "s" or "")
  elseif dif.day > 0 then
    string = string .. dif.day .. " day" .. (dif.day > 1 and "s" or "")
  elseif dif.hour > 0 then
    string = string .. dif.hour .. " hour" .. (dif.hour > 1 and "s" or "")
  elseif dif.min > 0 then
    string = string .. dif.min .. " minute" .. (dif.min > 1 and "s" or "")
  elseif dif.sec > 0 then
    string = string .. dif.sec .. " second" .. (dif.sec > 1 and "s" or "")
  end
  if string ~= "" then
    string = string .. " ago."
  end
  return string
end

function MM:TimeToDate(stamp)
  local d = date("*t",stamp)
  return time({year=d.year, month=d.month, day=d.day, hour=0})
end

function MM:DaysAgo(days)
  local stamp = MM:TimeToDate(time()) + 86400 -- add a day's worth of seconds
  local t = date("*t",stamp)
  t.day = t.day - days
  return time(t)
end

-- print out the object to chat
function MM:Dump(orig, depth)
  if not depth then print("Line","Key","Value") end
  depth = depth or 0
  local depthStr = ""
  for i=1, depth do depthStr = depthStr .. " |" end
  for k, v in next, orig do
     local splitStr =  (type(v) == 'table' and '\\' or ' ')
     print("|"..depthStr..splitStr, k, v)
     if type(v) == "table" then dump(v,depth+1) end
  end
end

-- calculate the variance between values
function MM:Variance(tbl,mean)
  local dif
  local sum, count = 0, 0
  for k, v in pairs(tbl) do
    if type(v) == "number" then
      dif = v - mean
      sum = sum + (dif * dif)
      count = count + 1
    end
  end
  return ( sum / count )
end

-- use the variance to calculate standard deviation
function MM:StdDev(tbl,mean)
  local variance = MM:Variance(tbl,mean)
  return math.sqrt(variance)
end

local qualityCost = {
  [2] = 3,
  [3] = 6,
  [4] = 10,
  [5] = 25
}

-- return an orb cost for each quality of enchants
function MM:OrbCost(reID)
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(reID)
  local quality = Enum.EnchantQualityEnum[enchant.Quality]
	return qualityCost[quality]
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
    local enchantList = C_MysticEnchant.QueryEnchants(9999,1,"",{})
		for _, enchant in pairs(enchantList) do
      local quality = Enum.EnchantQualityEnum[enchant.Quality]
			if quality == qualityValue[qualityName] and not enchant.IsWorldforged then
				table.insert(enchants, enchant.SpellID)
				enchants[enchant.SpellID] = true
			end
		end
		table.sort(enchants,
      function(k1, k2)
        local enchant1 = C_MysticEnchant.GetEnchantInfoBySpell(k1)
        local enchant2 = C_MysticEnchant.GetEnchantInfoBySpell(k2)
        return MM:Compare(enchant1.SpellName,enchant2.SpellName,"<")
      end
    )
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end

function MM:Clone(orig)
  -- Clone for simple table copy
  local copy
  if type(orig) == 'table' then
    return {table.unpack(orig)}
  else
    copy = orig
  end
  return copy
end

function MM:DeepClone(orig, copies)
  -- Deep clone for complex table copy
  -- Only use orig param, 2nd param for internal use
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[MM:DeepClone(orig_key, copies)] = MM:DeepClone(orig_value, copies)
          end
          setmetatable(copy, MM:DeepClone(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function MM:CombineListsLimited(l1,l2,maximum)
  -- combine two number lists, limit by a maximum value
	local list = {}
	for k, v in next, l1 do
		if not maximum or maximum and type(v) == 'number' and v <= maximum then
			table.insert(list, v)
		end
	end
	for k, v in next, l2 do
		if not maximum or maximum and type(v) == 'number' and v <= maximum then
			table.insert(list, v)
		end
	end
	return list
end

function MM:Lowest(a,b)
	local lowest
	if a and b then
		lowest = a < b and a or b
	elseif a then
		lowest = a
	elseif b then
		lowest = b
	end
	return lowest
end

-- returns the price stats for a given enchant
function MM:StatObj(reID)
  local stats = self.data.RE_AH_STATISTICS[reID]
  return stats and stats.current
end


local colors = {
  ["gold"] = "|cffffd700",
  ["green"] = "|cff00ff00",
  ["red"] = "|cffff0000",
  ["yellow"] = "|cffffff00",
  ["white"] = "|cffffffff",
  ["min"] = "|cff03fffb",
  ["med"] = "|cff00c25e",
  ["mean"] = "|cffc29e00",
  ["max"] = "|cffff0000",
  ["2"] = "|cff1eff00",
  ["3"] = "|cff0070dd",
  ["4"] = "|cffa335ee",
  ["5"] = "|cffff8000",
  ["RE_QUALITY_UNCOMMON"] = "|cff1eff00",
  ["RE_QUALITY_RARE"] = "|cff0070dd",
  ["RE_QUALITY_EPIC"] = "|cffa335ee",
  ["RE_QUALITY_LEGENDARY"] = "|cffff8000",
  ["RE_QUALITY_ARTIFACT"] = "|cffff8000",
  ["RE_QUALITY_HEIRLOOM"] = "|cffff8000",
}
-- Color text using the above table
function MM:cTxt(text, color)
  return (colors[color] or "|cffffffff") .. text .. "|r"
end

function MM:IsREKnown(SpellID)
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
  return enchant and enchant.Known or false
end

function MM:COMMENTATOR_SKIRMISH_QUEUE_REQUEST(this, event, entry, data)
  if event ~= "ASCENSION_REFORGE_ENCHANTMENT_LEARNED" 
    and event ~= "ASCENSION_REFORGE_ENCHANT_RESULT"
    and event ~= "ASCENSION_REFORGE_PROGRESS_UPDATE" then return end
  MM:ASCENSION_REFORGE_ENCHANT_RESULT(this, event, entry, data)
  MM:ASCENSION_REFORGE_PROGRESS_UPDATE(this, event, entry, data)
end

-- Notification function for the LEARNED event
function MM:MYSTIC_ENCHANT_LEARNED(this, SpellID)
  if not self.db.realm.OPTIONS.notificationLearned then return end
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
  if not enchant then return end
  local icon = select(3, GetSpellInfo(SpellID))
  local texture = CreateTextureMarkup(icon, 64, 64, 64, 64, 0, 1, 0, 1)
  local enchantColor = colors[enchant.Quality]
  MM:Print(format("|Hspell:%s|h%s[%s]|r|h%s", SpellID, enchantColor, enchant.SpellName, " RE has been unlocked!"))
  DEFAULT_CHAT_FRAME:AddMessage(texture)
end

-- determine the count of Mystic Orbs
function MM:GetOrbCurrency()
  return GetItemCount(98570)
end

function MM:IsUntarnished(itemName)
  if not itemName then return false end
  return itemName:find("Untarnished Mystic Scroll")
end

-- itemLink, enchantData, buyoutPrice, seller, duration, icon
function MM:GetAuctionMysticEnchantInfo(listingType, index)
  local itemLink = GetAuctionItemLink(listingType, index)
  local itemID = GetItemInfoFromHyperlink(itemLink)
  local enchantData = C_MysticEnchant.GetEnchantInfoByItem(itemID)
  local buyoutPrice, _, _, seller = select(9, GetAuctionItemInfo(listingType, index))
  local duration = GetAuctionItemTimeLeft(listingType, index)
  local icon = select(2, GetAuctionItemInfo(listingType, index))
  return itemLink, enchantData, buyoutPrice, seller, duration, icon
end