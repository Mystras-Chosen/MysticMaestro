local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

-- API for other addons to get information about an RE
function Maestro(reID)
  return MM:DeepClone(MM:StatObj(reID))
end

function MM:round(num, numDecimalPlaces, alwaysDown)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + (alwaysDown and 0 or 0.5)) / mult
end

function MM:Compare(a,b,comparitor)
  a = a or math.huge
  b = b or math.huge
  if a == math.huge or b == math.huge then
    return a < b
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

function MM:ItemLinkRE(reID)
  local RE = MYSTIC_ENCHANTS[reID]
  local color = AscensionUI.MysticEnchant.EnchantQualitySettings[RE.quality][1]
  return color .. "\124Hspell:" .. RE.spellID .. "\124h[" .. RE.spellName .. "]\124h\124r"
end

function MM:FindBlankInsignia()
  -- Find a valid insignia to use for crafting
  for i=0, 4 do
    for j=1, GetContainerNumSlots(i) do
      local item = select(7, GetContainerItemInfo(i, j))
      if item and item:find("Insignia of the") then
        local re = GetREInSlot(i, j)
        local reObj = MYSTIC_ENCHANTS[re]
        if reObj == nil then
          return {bag=i,index=j}
        end
      end
    end
  end
end

function MM:InventoryInsignia()
  local insignia = {blank={},re={}}
  local tallyRE = {}
  for i=0, 4 do
    for j=1, GetContainerNumSlots(i) do
      local item = select(7, GetContainerItemInfo(i, j))
      if item and item:find("Insignia of the") then
        local re = GetREInSlot(i, j)
        local reObj = MYSTIC_ENCHANTS[re]
        if reObj == nil then
          table.insert(insignia.blank, {bag=i,index=j})
        else
          table.insert(insignia.re, {bag=i,index=j,enchant=re})
          if tallyRE[re] == nil then tallyRE[re] = 0 end
          tallyRE[re] = tallyRE[re] + 1
        end
      end
    end
  end
  if #insignia.blank > 0 or #insignia.re > 0 then
    return true, insignia, tallyRE
  else
    return false
  end
end

function MM:IsSoulbound(bag, slot)
  local TT = MysticMaestroTT
  TT:ClearLines()  
  TT:SetBagItem(bag, slot)
  for i = 1,TT:NumLines() do
    if(_G[TT:GetName().."TextLeft"..i]:GetText()==ITEM_SOULBOUND) then
      return true
    end
  end
  return false
end

local MMSetting_IlvlLimit,MMSetting_GoldLimit,MMSetting_QualityLimit=115,8,3
function MM:InventoryRE()
  local tallyRE = {}
  for i=0, 4 do
    for j=1, GetContainerNumSlots(i) do
      local _,_,_,quality,_,_,item = GetContainerItemInfo(i, j)
      if item and quality >= 3 and not MM:IsSoulbound(i, j) then
        local re = GetREInSlot(i, j)
        local _,_,_,iLevel,_,_,_,_,_,_,vendorPrice = GetItemInfo(item)
        local withinLimits = iLevel <= MMSetting_IlvlLimit and vendorPrice <= MMSetting_GoldLimit * 10000 and quality <= MMSetting_QualityLimit
        if re ~= nil and withinLimits then
          if tallyRE[re] == nil then tallyRE[re] = 0 end
          tallyRE[re] = tallyRE[re] + 1
        end
      end
    end
  end
  return #tallyRE > 0, tallyRE
end

function MM:ApplyRE(slot,reID)
  -- Craft onto the inventory slot with the specified Random Enchant
  RequestSlotReforgeEnchantment(slot.bag, slot.index, reID)
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
  return time({year=d.year, month=d.month, day=d.day})
end

function MM:BeyondDays(stamp,limitNum)
  local todayDate = MM:TimeToDate(time())
  local compareDate = MM:TimeToDate(stamp)
  local values = MM:CompareTime(todayDate,compareDate)
  local limit = limitNum and limitNum or 10
  return values.day and values.day > limit and true or false
end

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

function MM:variance(tbl,mean)
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

function MM:StdDev(tbl,mean)
  local variance = MM:variance(tbl,mean)
  return math.sqrt(variance)
end

local qualityCost = {
  [2] = 3,
  [3] = 6,
  [4] = 10,
  [5] = 25
}

function MM:OrbCost(reID)
	return qualityCost[MYSTIC_ENCHANTS[reID].quality]
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

function MM:StatObj(reID)
  local stats = self.db.realm.RE_AH_STATISTICS[reID]
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
  ["5"] = "|cffff8000"
}

function MM:cTxt(text, color)
  return (colors[color] or "|cffffffff") .. text .. "|r"
end


function MM:COMMENTATOR_SKIRMISH_QUEUE_REQUEST(this, event, entry)
  if event == "ASCENSION_REFORGE_ENCHANTMENT_LEARNED" then
    RE = GetREData(entry)
    if RE and RE.enchantID > 0 then
      local message = MM.RE_KNOWN[RE.enchantID] and " was already a known RE!" or " RE has been unlocked!"
      local name, _, icon = GetSpellInfo(RE.spellID)
      texture = CreateTextureMarkup(icon, 64, 64, 64, 64, 0, 1, 0, 1)
      local enchantColor = colors[tostring(RE.quality)]
      MM:Print(format("|Hspell:%s|h%s[%s]|r|h%s", RE.spellID, enchantColor, name, message))
      DEFAULT_CHAT_FRAME:AddMessage(texture)
    end
  end
end