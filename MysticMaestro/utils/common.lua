local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:MatchTooltipRE(TT)
  for i=1, TT:NumLines() do
    local line = _G[TT:GetName() .. "TextLeft" .. i]:GetText()
    if line and line ~= "" then
      name, description = line:match("Equip: (.-) %- (.+)")
      if name then
        return self.RE_LOOKUP[name]
      end
    end
  end
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

local qualityCost = {
  [2] = 2,
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