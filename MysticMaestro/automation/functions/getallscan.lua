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
local calculateRunning, calculateFinished, lastBreak, currentIndex, REQueue
local function getAllScan_OnUpdate()
  if calculateRunning then
    local listings = MM.data.RE_AH_LISTINGS
    -- Set up the queue of all enchants in listings
    if not REQueue then
      MM:Print("GetAll results processing")
      REQueue = {}
      for reID, _ in pairs(listings) do
        table.insert(REQueue, reID)
      end
      lastBreak = GetTime()
    end
    if not currentIndex then
      currentIndex = 1
    end
    -- If we have finished the list, move to finished section
    if currentIndex > #REQueue then
      calculateRunning = nil
      calculateFinished = true
    else
      -- Process as many as possible within the alloted time
      while currentIndex <= #REQueue and GetTime() - lastBreak < spf do
        MM:CalculateREStats(REQueue[currentIndex],listings[REQueue[currentIndex]])
        currentIndex = currentIndex + 1
      end
      -- Mark the time when we break out from our loop
      lastBreak = GetTime()
    end
  -- Clean up variables and inform finished
  elseif calculateFinished then
    REQueue = nil
    calculateFinished = nil
    currentIndex = nil
    lastBreak = nil
    MM.AutomationManager:Inform(automationTable, "finished")
  end
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
    MM:CollectAllREData(lastScanTime)
    scanInProgress = false
    calculateRunning = true
    -- MM:CalculateAllStats()
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