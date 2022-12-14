local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local scanInProgress, lastScanTime
local function remainingTime()
  if lastScanTime then
    local secondsRemaining = lastScanTime + 900 - time()
    return math.floor(secondsRemaining / 60) .. ":" .. string.format("%02d", secondsRemaining % 60)
  else
    return "Unknown"
  end
end

function MM:HandleGetAllScan()
  if not self:ValidateAHIsOpen() then
    return
  end
  if select(2, CanSendAuctionQuery()) then
    MM:Print("Initiating GetAll Scan")
    scanInProgress = true
    lastScanTime = time()
    QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
  else
    MM:Print("Get All scan not available. Time remaining: " .. remainingTime())
  end
end

function MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  if scanInProgress == true then
    scanInProgress = false
    self:CollectAllREData(lastScanTime)
    self:CalculateAllStats()
  end
end
