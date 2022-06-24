local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local scanInProgress, lastScanTime
local function remainingTime()
  if lastScanTime then
    local secondsRemaining = lastScanTime + 900 - GetTime()
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
        lastScanTime = GetTime()
        QueryAuctionItems ("", nil, nil, 0, 0, 0, 0, 0, 0, true)
      else
        MM:Print("Full scan not available. Time remaining: " .. remainingTime())
      end
    else
      MM:Print("Auction house window must be open to perform scan")
    end
  end