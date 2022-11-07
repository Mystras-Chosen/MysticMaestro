local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local function getNameAndID(input)
  local nameRE, idRE
  if type(input) == "number" then
    idRE = input
    nameRE = MM.RE_NAMES[input]
  else
    idRE = MM.RE_LOOKUP[input]
    nameRE = input
  end
  return nameRE, idRE
end

local function addLinesTooltip(tt, input)
  local name, reID = getNameAndID(input)
  if name == nil or reID == nil then return end
  local stats = MM.db.realm.RE_AH_STATISTICS[reID]["current"]
  local known = IsReforgeEnchantmentKnown(reID)
  local dataRE = MYSTIC_ENCHANTS[reID]
  local indicator
  if dataRE then
    if known then
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_green", 64, 64, 16, 16, 0, 1, 0, 1)
    else
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_red", 64, 64, 16, 16, 0, 1, 0, 1)
    end
    tt:AppendText("   "..indicator)
  end
  tt:AddDoubleLine(dataRE and MM:cTxt(name, tostring(dataRE.quality)) or "Mystic Maestro:",MM:DaysAgoString(stats and stats.Last or 0),1,1,0,1,1,1)
  if stats ~= nil then
    if stats.Last ~= nil then
      local ttMin = GetCoinTextureString(MM:round(stats.Min or 0.0))
      tt:AddDoubleLine("Last Scan Value", ttMin,1,1,0,1,1,1)
      ttMin = GetCoinTextureString(MM:round(stats["10d_Min"] or 0.0))
      tt:AddDoubleLine("10-Day Value", MM:cTxt(ttMin,"min"),1,1,0)
      local orbval = MM:OrbValue(reID)
      tt:AddDoubleLine("Gold Per Mystic Orb", MM:cTxt(GetCoinTextureString(orbval), orbval > 10000 and "gold" or "red"),1,1,0)
    end
  end
  -- tt:AddLine(" ")
end

function MM:TooltipHandlerItem(tooltip)
  local enchant
  enchant = tooltip:GetItemMysticEnchant()
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
