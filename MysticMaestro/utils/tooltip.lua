local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local function cTxt(text, color)
  colors = {
    ["red"] = "|cffff0000",
    ["green"] = "|cff00ff00",
    ["blue"] = "|cff0000ff",
    ["gold"] = "|cffffd700",
    ["white"] = "|cffffffff",
  }
  return (colors[color] or "|cffffffff") .. text .. "|r"
end

local tGold = cTxt("g","gold")

local function getNameAndID(input)
  local nameRE, idRE
  if type(input) == "number" then
    idRE = input
    nameRE = GetSpellInfo(input)
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
  local mmText = "MM: "
  if dataRE then
    mmText = cTxt("MM: ", dataRE.known and "green" or "red")
  end
  tt:AddDoubleLine(mmText..name, (stats and stats.listed or "None" ) .. " Listed")
  if stats ~= nil then
    local ttMin = MM:round((stats.minVal or 0.0) / 10000)
    local ttMed = MM:round((stats.medVal or 0.0) / 10000)
    local ttAvg = MM:round((stats.avgVal or 0.0) / 10000)
    local ttTop = MM:round((stats.topVal or 0.0) / 10000)
    tt:AddDoubleLine("Min (Med/Avg/Top)", cTxt(ttMin)..tGold.." ("..cTxt(ttMed)..tGold.."/"..cTxt(ttAvg)..tGold.."/"..cTxt(ttTop)..tGold..")")
  end
end

function MM:TooltipHandler(tooltip, event)
  local enchant
  -- Handle Item Tooltips
  if event == "OnTooltipSetItem" then
    enchant = MM:MatchTooltipRE(tooltip)
  -- Handle Spell Tooltips
  elseif event == "OnTooltipSetSpell" then
    enchant = select(3 , tooltip:GetSpell())
    if MYSTIC_ENCHANTS[enchant] == nil then
      return
    end
  end
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end

GameTooltip:HookScript(
  "OnTooltipSetItem",
  function(self)
    MM:TooltipHandler(self, "OnTooltipSetItem")
  end
)

GameTooltip:HookScript(
  "OnTooltipSetSpell",
  function(self)
    MM:TooltipHandler(self, "OnTooltipSetSpell")
  end
)
