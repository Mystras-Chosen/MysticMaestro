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
    return enchantFound
  end
  return false
end
