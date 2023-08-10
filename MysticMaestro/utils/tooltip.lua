local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local function addLinesTooltip(tt, spellID)
  if not MM.db.realm.OPTIONS.ttEnable then return end
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
  if not enchant then return end
  local stats = MM:StatObj(spellID)
  if MM.db.realm.OPTIONS.ttKnownIndicator and enchant then
    local indicator
    if enchant.Known then
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_green", 64, 64, 16, 16, 0, 1, 0, 1)
    else
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_red", 64, 64, 16, 16, 0, 1, 0, 1)
    end
    tt:AppendText("   "..indicator)
  end
  tt:AddDoubleLine(MM:cTxt(enchant.SpellName, enchant.Quality), MM:DaysAgoString(stats and stats.Last or 0),1,1,0,1,1,1)
  if stats ~= nil and stats.Last ~= nil then
    local temp
    if MM.db.realm.OPTIONS.ttMin then
      temp = GetCoinTextureString(MM:Round(stats.Min or 0.0))
      tt:AddDoubleLine("Current Min", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMed then
      temp = GetCoinTextureString(MM:Round(stats.Med or 0.0))
      tt:AddDoubleLine("Current Median", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMean then
      temp = GetCoinTextureString(MM:Round(stats.Mean or 0.0))
      tt:AddDoubleLine("Current Mean", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttMax then
      temp = GetCoinTextureString(MM:Round(stats.Max or 0.0))
      tt:AddDoubleLine("Current Max", temp,1,1,0,1,1,1)
    end
    if MM.db.realm.OPTIONS.ttGPO then
      temp = MM:OrbValue(reID)
      tt:AddDoubleLine("Current GPO", MM:cTxt(GetCoinTextureString(temp), temp > 10000 and "gold" or "red"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMin then
      temp = GetCoinTextureString(MM:Round(stats["10d_Min"] or 0.0))
      tt:AddDoubleLine("10-Day Min", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMed then
      temp = GetCoinTextureString(MM:Round(stats["10d_Med"] or 0.0))
      tt:AddDoubleLine("10-Day Median", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMean then
      temp = GetCoinTextureString(MM:Round(stats["10d_Mean"] or 0.0))
      tt:AddDoubleLine("10-Day Mean", MM:cTxt(temp,"min"),1,1,0)
    end
    if MM.db.realm.OPTIONS.ttTENMax then
      temp = GetCoinTextureString(MM:Round(stats["10d_Max"] or 0.0))
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
  local _,link = tooltip:GetItem()
  if not link then return end
  local itemID = GetItemInfoFromHyperlink(link)
  if not itemID then return end
  local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
  if not enchant then return end
  addLinesTooltip(tooltip, enchant.SpellID)
end

function MM:TooltipHandlerSpell(tooltip)
  local spellID = select(3 , tooltip:GetSpell())
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
  if not enchant then return end
  addLinesTooltip(tooltip, spellID)
end
