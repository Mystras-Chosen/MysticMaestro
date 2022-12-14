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
  if not MM.db.realm.OPTIONS.ttEnable then return end
  local name, reID = getNameAndID(input)
  if name == nil or reID == nil then return end
  local stats = MM:StatObj(reID)
  local known = IsReforgeEnchantmentKnown(reID)
  local dataRE = MYSTIC_ENCHANTS[reID]
  if MM.db.realm.OPTIONS.ttKnownIndicator and dataRE then
    local indicator
    if known then
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_green", 64, 64, 16, 16, 0, 1, 0, 1)
    else
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_red", 64, 64, 16, 16, 0, 1, 0, 1)
    end
    tt:AppendText("   "..indicator)
  end
  tt:AddDoubleLine(dataRE and MM:cTxt(name, tostring(dataRE.quality)) or "Mystic Maestro:",MM:DaysAgoString(stats and stats.Last or 0),1,1,0,1,1,1)
  if stats ~= nil and stats.Last ~= nil then
    local temp
    if MM.db.realm.OPTIONS.ttMin then
      temp = GetCoinTextureString(MM:round(stats.Min or 0.0))
      tt:AddDoubleLine("Current Min", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMed then
      temp = GetCoinTextureString(MM:round(stats.Med or 0.0))
      tt:AddDoubleLine("Current Median", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMean then
      temp = GetCoinTextureString(MM:round(stats.Mean or 0.0))
      tt:AddDoubleLine("Current Mean", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMax then
      temp = GetCoinTextureString(MM:round(stats.Max or 0.0))
      tt:AddDoubleLine("Current Max", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttGPO then
      temp = MM:OrbValue(reID)
      tt:AddDoubleLine("Current GPO", MM:cTxt(GetCoinTextureString(temp), temp > 10000 and "gold" or "red"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMin then
      temp = GetCoinTextureString(MM:round(stats["10d_Min"] or 0.0))
      tt:AddDoubleLine("10-Day Min", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMed then
      temp = GetCoinTextureString(MM:round(stats["10d_Med"] or 0.0))
      tt:AddDoubleLine("10-Day Median", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMean then
      temp = GetCoinTextureString(MM:round(stats["10d_Mean"] or 0.0))
      tt:AddDoubleLine("10-Day Mean", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMax then
      temp = GetCoinTextureString(MM:round(stats["10d_Max"] or 0.0))
      tt:AddDoubleLine("10-Day Max", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENGPO then
      temp = MM:OrbValue(reID,"10d_Min")
      tt:AddDoubleLine("10-Day GPO", MM:cTxt(GetCoinTextureString(temp), temp > 10000 and "gold" or "red"),1,1,0)
    end
  end
  tt:AddLine(" ")
end

function MM:TooltipHandlerItem(tooltip)
  local enchant, name
  enchant = tooltip:GetItemMysticEnchant()
  if enchant and not MYSTIC_ENCHANTS[enchant] and MM.RE_ID[enchant] then
    enchant = MM.RE_ID[enchant]
  end
  if enchant then
    addLinesTooltip(tooltip, enchant)
  else
    name = tooltip:GetItem()
    if name ~= nil then
      enchant = MM.RE_LOOKUP[name:match("Mystic Scroll: (.+)")]
      if enchant then
        addLinesTooltip(tooltip, enchant)
      end
    end
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
