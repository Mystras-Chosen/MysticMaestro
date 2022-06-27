local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
  local AuctionFrame = _G["AuctionFrame"]
  if not AuctionFrame or not AuctionFrame:IsShown() then
    MM:Print("Auction house window must be open to perform scan")
    return false
  end
  return true
end

function MM:UpdateDatabase()
  local listings = self.db.realm.RE_AH_LISTINGS or {}
  local stats = self.db.realm.RE_AH_STATISTICS or {}
  for _, enchantData in pairs(MYSTIC_ENCHANTS) do
    local spellID = enchantData.spellID
    if spellID ~= 0 then
      local spellName = GetSpellInfo(spellID)
      if listings[spellName] == nil then
        listings[spellName] = {}
        statistics[spellName] = {}
      end
    end
  end
  self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS = listings, stats
  setmetatable(self.db.realm.RE_AH_LISTINGS, enchantMT)
  setmetatable(self.db.realm.RE_AH_STATISTICS, enchantMT)
end

function MM:GetAHItemEnchantName(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  local result = GameTooltip:Match("Equip: (.- %- %w+) %- .+") or GameTooltip:Match("Equip: (.-) %- .+")
  return result
end

function MM:CollectAuctionData(scanTime, expectedEnchantName)
  local listings = self.db.realm.RE_AH_LISTINGS
  local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
  if numBatchAuctions > 0 then
    for i = 1, numBatchAuctions do
      local name, _, _, _, _, level, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
      if name and name:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0 then
        local enchantName = self:GetAHItemEnchantName(i)
        if enchantName and (not expectedEnchantName or enchantName == expectedEnchantName) then
          listings[enchantName][scanTime] = listings[enchantName][scanTime] or {}
          table.insert(listings[enchantName][scanTime], buyoutPrice)
        end
      end
    end
    return true
  end
  return false
end
