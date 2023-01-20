local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "GetAll Scan"

local automationTable = {}

function automationTable.GetName()
  return automationName
end

function automationTable.ShowInitPrompt()
  print("showinitprompt called")
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end

local running

local scanInProgress, lastScanTime
local function remainingTime()
  if lastScanTime then
    local secondsRemaining = lastScanTime + 900 - time()
    return math.floor(secondsRemaining / 60) .. ":" .. string.format("%02d", secondsRemaining % 60)
  else
    return "Unknown"
  end
end

-- local function handleGetAllScan()
  -- MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "getAllScan")
  -- when the scan is complete, MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  -- set min max of progress bar to 0 and 100
  -- set value of progress bar to 0
  -- tell progress bar to show progress bar text as percent (new method required)
  -- enable OnUpdate handler for getAll scan to calculate stats (specify throttle fps above getAll OnUpdate handler)
-- end

local fps = 20
local spf = 1 / fps
local function getAllScan_OnUpdate()

end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    getAllScan_OnUpdate()
  end
)


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
    MM.AutomationManager:Inform(automationTable, "finished")
  end
end


function automationTable.Start()
  print("start called")
  MM.AutomationUtil.SetProgressBarMinMax(0, 100)
  MM.AutomationUtil.SetProgressBarValues(100)
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  running = true
  MM:HandleGetAllScan()
end

function automationTable.PostProcessing()
  scanInProgress = false
  MM:CollectAllREData(lastScanTime)
  MM:CalculateAllStats()
  MM:Print("GetAll scan Complete!")
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "noPostProcessing")
end

function automationTable.Stop()
  print("stop called")
  MM.AutomationUtil.HideAutomationPopup()
  MM:CancelDisplayEnchantAuctions()
  running = false
  lastUpdate = nil
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)