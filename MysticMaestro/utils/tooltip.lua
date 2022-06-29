local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local function cTxt(text, color)
  local colors = {
    ["red"] = "|cffff0000",
    ["green"] = "|cff00ff00",
    ["blue"] = "|cff0000ff",
    ["gold"] = "|cffffd700",
    ["white"] = "|cffffffff",
    ["min"] = "|cff03fffb",
    ["med"] = "|cff00c25e",
    ["avg"] = "|cffc29e00",
    ["top"] = "|cffff0000",
    ["2"] = "|cff1eff00",
    ["3"] = "|cff0070dd",
    ["4"] = "|cffa335ee",
    ["5"] = "|cffff8000"
  }
  return (colors[color] or "|cffffffff") .. text .. "|r"
end

local tGold = cTxt("g","gold")

local function getNameAndID(input)
  local nameRE, idRE
  if type(input) == "number" then
    idRE = input
    nameRE = GetSpellInfo(MYSTIC_ENCHANTS[input].spellID)
  else
    idRE = MM.RE_LOOKUP[input]
    nameRE = input
  end
  return nameRE, idRE
end

local function addLinesTooltip(tt, input)
  local name, reID = getNameAndID(input)
  local stats = MM.db.realm.RE_AH_STATISTICS[name]["current"]
  local dataRE = MYSTIC_ENCHANTS[reID]
  if dataRE then
    mmText = cTxt(dataRE.known and "Known " or "Unknown " , dataRE.known and "green" or "red")
    name = cTxt(name, tostring(dataRE.quality))
  end
  tt:AddLine("")
  tt:AddDoubleLine((mmText and mmText or "") .. "RE: " ..name, (stats and stats.listed or "None" ) .. " Listed")
  if stats ~= nil then
    local ttMin = MM:round((stats.minVal or 0.0) / 10000)
    local ttMed = MM:round((stats.medVal or 0.0) / 10000)
    local ttAvg = MM:round((stats.avgVal or 0.0) / 10000)
    local ttTop = MM:round((stats.topVal or 0.0) / 10000)
    tt:AddDoubleLine(cTxt("Min","min").."("..cTxt("Med","med").."/"..cTxt("Avg","avg").."/"..cTxt("Top","top")..")", cTxt(ttMin,"min")..tGold.." ("..cTxt(ttMed,"med")..tGold.."/"..cTxt(ttAvg,"avg")..tGold.."/"..cTxt(ttTop,"top")..tGold..")")
  end
end

-- function MM:TooltipHandler(tooltip, event)
--   local enchant
--   -- Handle Item Tooltips
--   if event == "OnTooltipSetItem" then
--     enchant = MM:MatchTooltipRE(tooltip)
--   -- Handle Spell Tooltips
--   elseif event == "OnTooltipSetSpell" then
--     enchant = select(3 , tooltip:GetSpell())
--     if MYSTIC_ENCHANTS[enchant] == nil then
--       local swapID = MM.RE_ID[enchant]
--       if swapID and MYSTIC_ENCHANTS[swapID] ~= nil then
--         enchant = swapID
--       else
--         return
--       end
--     end
--   end
--   if enchant then
--     addLinesTooltip(tooltip, enchant)
--   end
-- end

-- GameTooltip:HookScript(
--   "OnTooltipSetItem",
--   function(self)
--     MM:TooltipHandler(self, "OnTooltipSetItem")
--   end
-- )

-- GameTooltip:HookScript(
--   "OnTooltipSetSpell",
--   function(self)
--     MM:TooltipHandler(self, "OnTooltipSetSpell")
--   end
-- )

function MM:TooltipHandlerItem(tooltip)
  local enchant
  enchant = MM:MatchTooltipRE(tooltip)
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end

function MM:TooltipHandlerSpell(tooltip)
  local enchant
  enchant = select(3 , tooltip:GetSpell())
  if MYSTIC_ENCHANTS[enchant] == nil then
    local swapID = MM.RE_ID[enchant]
    if swapID and MYSTIC_ENCHANTS[swapID] ~= nil then
      enchant = swapID
    else
      return
    end
  end
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end