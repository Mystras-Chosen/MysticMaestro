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
  local AuctionFrame = _G["AuctionFrame"]
  if AuctionFrame and AuctionFrame:IsShown() then
    if select(2, CanSendAuctionQuery()) then
      scanInProgress = true
      lastScanTime = time()
      QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
    else
      MM:Print("Full scan not available. Time remaining: " .. remainingTime())
    end
  else
    MM:Print("Auction house window must be open to perform scan")
  end
end

local function getAHItemEnchantName(index)
  GameTooltip:SetOwner(_G["BrowseButton1Item"], "ANCHOR_NONE") -- not sure why this makes it work.  should look into it.
  GameTooltip:SetAuctionItem("list", index)
  local result = GameTooltip:Match("Equip: (.- %- %w+) %- .+") or GameTooltip:Match("Equip: (.-) %- .+")
  return result
end

function MM:AUCTION_ITEM_LIST_UPDATE()
  if scanInProgress == true then
    scanInProgress = false
    local listings = self.db.realm.RE_AH_LISTINGS
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
    print(numBatchAuctions)
    if numBatchAuctions > 0 then
      for i=1, numBatchAuctions do
        local name, _, _, _, _, level, _, _, buyoutPrice, _, seller = GetAuctionItemInfo("list", i);
        if name:find("Insignia") and level == 15 and buyoutPrice then
          local enchantName = getAHItemEnchantName(i)
          print("enchantName = " .. (enchantName or "nil"))
          if enchantName then
            listings[enchantName][time] = listings[enchantName][time] or {}
            table.insert(listings[enchantName][time], {
              seller = seller,
              timeLeft = GetAuctionItemTimeLeft("list", i),
              buyoutPrice = buyoutPrice
            })
          end
        end
      end
    end
  end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")