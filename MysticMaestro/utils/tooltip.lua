local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local WHITE = "|cffFFFFFF"

local function addLinesTooltip(tt, SpellID)
  if not MM.db.realm.OPTIONS.ttEnable then return end
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
  if not enchant then return end
  local stats = MM:StatObj(SpellID)
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
      temp = MM:OrbValue(SpellID)
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
      temp = MM:OrbValue(SpellID,"10d_Min")
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

-- adds to a spells tooltip what rare worldforged enchants you are missing for it
-- lable for the type is removed if you have it unlearned in your inventory as well
function MM:WorldforgedTooltips(SpellName)
  local worldForgedList = ""
  -- get list of scrolls and turn it into a keyd table to make it eaiser to check
  local scrolls = {}
  for _, scroll in pairs(C_MysticEnchant.GetMysticScrolls()) do
    scrolls[scroll.Entry] = true
  end
  -- query enchant by spell name only returns if there rare/worldforged and unlearned
  local enchants = C_MysticEnchant.QueryEnchants(9999, 1, SpellName, {Enum.ECFilters.RE_FILTER_UNKNOWN ,Enum.ECFilters.RE_FILTER_WORLDFORGED,Enum.ECFilters.RE_FILTER_RARE})
  if #enchants == 0 then return end
    for _, enchant in pairs(enchants) do
      if not scrolls[enchant.ItemID] then
        worldForgedList = worldForgedList..gsub(enchant.SpellName, " "..SpellName, "")..", "
      end
    end
    return "Missing WorldForged Enchants: "..WHITE..worldForgedList
end

function MM:TooltipHandlerSpell(tooltip)
  local SpellName, _, SpellID = tooltip:GetSpell()
  local worldForgedTip = MM:WorldforgedTooltips(SpellName)
  local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
  if enchant then
    addLinesTooltip(tooltip, SpellID)
  elseif MM.db.realm.OPTIONS.worldforgedTooltip and worldForgedTip then
    tooltip:AddLine(" ")
    tooltip:AddLine(worldForgedTip)
  end
end
