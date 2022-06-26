local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

MM.tooltip = CreateFrame("GameTooltip")

local scanInProgress, lastScanTime
local function remainingTime()
  if lastScanTime then
    local secondsRemaining = lastScanTime + 900 - time()
    return math.floor(secondsRemaining / 60) .. ":" .. string.format("%02d", secondsRemaining % 60)
  else
    return "Unknown"
  end
end

function MM:HandleFullScan()
  if not self:ValidateAHIsOpen() then
    return
  end
  if select(2, CanSendAuctionQuery()) then
    self:UpdateDatabase()
    scanInProgress = true
    lastScanTime = time()
    QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
  else
    MM:Print("Full scan not available. Time remaining: " .. remainingTime())
  end
end

local function getAHItemEnchantName(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  local result = GameTooltip:Match("Equip: (.- %- %w+) %- .+") or GameTooltip:Match("Equip: (.-) %- .+")
  return result
end

function MM:Fullscan_AUCTION_ITEM_LIST_UPDATE()
  if scanInProgress == true then
    scanInProgress = false
    local listings = self.db.realm.RE_AH_LISTINGS
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
    if numBatchAuctions > 0 then
      for i = 1, numBatchAuctions do
        local name, _, _, _, _, level, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
        if name and name:find("Insignia") and level == 15 and buyoutPrice and buyoutPrice ~= 0 then
          local enchantName = getAHItemEnchantName(i)
          if enchantName then
            listings[enchantName][lastScanTime] = listings[enchantName][lastScanTime] or {}
            table.insert(listings[enchantName][lastScanTime], buyoutPrice)
          end
        end
      end
    end
  end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Fullscan_AUCTION_ITEM_LIST_UPDATE")
