local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end

function MM:GetAHItemEnchantName(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  return MM:MatchTooltipRE(GameTooltip)
end

function MM:MatchTooltipRE(TT)
  return TT:Match("Equip: (.- %- %w+) %- .+") or TT:Match("Equip: (.-) %- .+")
end

function MM:CollectAuctionData(scanTime, expectedEnchantName)
  local listings = self.db.realm.RE_AH_LISTINGS
  local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    local enchantFound = false
    for i = 1, numBatchAuctions do
      local name, _, _, _, _, level, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
      if name and name:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0 then
        local enchantName = self:GetAHItemEnchantName(i)
        if enchantName and (not expectedEnchantName or enchantName == expectedEnchantName) then
          enchantFound = true
          listings[enchantName][scanTime] = listings[enchantName][scanTime] or {}
          table.insert(listings[enchantName][scanTime], buyoutPrice)
        end
      end
    end
    if enchantFound then MM:CalculateStats(enchantName,scanTime) end
    return enchantFound
  end
  return false
end

function MM:CalculateStats(nameRE,sTime)
  local listings = self.db.realm.RE_AH_LISTINGS[nameRE]
  local listing = listings[sTime]
  local statistics = self.db.realm.RE_AH_STATISTICS[nameRE]
  local stats = statistics[sTime]
  local minVal, topVal, count, tally = 0, 0, 0, 0
  for k, v in pairs(listing) do
    if v > 0 and (v < minVal or minVal == 0) then
      minVal = v
    end
    if v > topVal then
      topVal = v
    end
    if v ~= nil then
      tally = tally + v
      count = count + 1
    end
  end
  if count then
    local midKey = floor(count/2)
    stats.medVal = listing[midKey]
    stats.avgVal = round(tally/count)
    stats.minVal = minVal
    stats.topVal = topVal
    stats.listed = count
  end
end

local qualityValue = {
  uncommon = 2,
  rare = 3,
  epic = 4,
  legendary = 5
}

function MM:GetAlphabetizedEnchantList(qualityName)
	local enchants = MM[qualityName:upper() .. "_ENCHANTS"]
	if not enchants then
		enchants = {}
		for _, enchantData in pairs(MYSTIC_ENCHANTS) do
			if enchantData.quality == qualityValue[qualityName] then
				local enchantName = GetSpellInfo(enchantData.spellID)
				table.insert(enchants, enchantName)
				enchants[enchantName] = true
			end
		end
		table.sort(enchants)
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end