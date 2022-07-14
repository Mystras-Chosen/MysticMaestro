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

function MM:Dump(data,index)
  return DevTools_Dump(data,index ~= nil and index or 0)
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
