local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local GetTime = GetTime

local automationName = "GetAll Scan"

local automationTable = {}

function automationTable.GetName()
  return automationName
end

local listings

function automationTable.ShowInitPrompt()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
  listings = MM.data.RE_AH_LISTINGS
end

local awaitingResults, scanTime, collectTime

function MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  if awaitingResults then
    awaitingResults = nil
    scanTime = time()
    collectTime = GetTime() + 2
  end
end

local function startGetAllScan()
  QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
  awaitingResults = true
end

local scannedEnchantIDs
local function collectScannedEnchantIDs()
  scannedEnchantIDs = {}
  for _, quality in ipairs({"legendary", "epic", "rare", "uncommon"}) do
    local enchants = MM:GetAlphabetizedEnchantList(quality)
    for _, enchant in ipairs(enchants) do
      table.insert(scannedEnchantIDs, enchant)
    end
  end
end

function automationTable.Start()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "getAllScan")
  startGetAllScan()
  collectScannedEnchantIDs() -- collect enchant IDs in table while we wait
end

local function recordListingData(index)
  local itemName, level, buyoutPrice, quality = MM:getAuctionInfo(index)
  local itemFound, enchantID, trinketFound = MM:isEnchantItemFound(itemName, quality, level, buyoutPrice, index)
  if itemFound then
    local temp = listings[enchantID][scanTime] or ":"
    listings[enchantID][scanTime] = trinketFound and buyoutPrice .. "," .. temp or temp .. buyoutPrice .. ","
  end
end

local function calculateStatistics(index)
  local enchantID = scannedEnchantIDs[index]
  MM:CalculateREStats(enchantID, listings[enchantID])
end

local recordingStartTime, calcStartTime
local fps = 20
local currentIndex, numAuctions, numEnchants

local function nilGetAllScanVariables()
  awaitingResults = nil
  scanTime = nil
  collectTime = nil
  scannedEnchantIDs = nil
  recordingStartTime = nil
  calcStartTime = nil
  currentIndex = nil
  numAuctions = nil
  numEnchants = nil
end

local function initRecording()
  collectTime = nil
  recordingStartTime = GetTime()
  currentIndex = 1
  numAuctions = GetNumAuctionItems("list")
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  MM.AutomationUtil.SetProgressBarDisplayMode("percent")
  MM.AutomationUtil.SetProgressBarMinMax(0, numAuctions)
  MM.AutomationUtil.SetProgressBarValues(0, numAuctions)
  MM.AutomationUtil.AppendProgressBarText("Archiving: ", true)
end

local function throttledRecording()
  while GetTime() - recordingStartTime < 1 / fps and currentIndex <= numAuctions do
    recordListingData(currentIndex)
    currentIndex = currentIndex + 1
  end
  if currentIndex > numAuctions then
    calcStartTime = recordingStartTime
    recordingStartTime = nil
    currentIndex = 1
    numEnchants = #scannedEnchantIDs
    MM.AutomationUtil.SetProgressBarMinMax(0, numEnchants)
    MM.AutomationUtil.SetProgressBarValues(0, numEnchants)
    MM.AutomationUtil.AppendProgressBarText("Calculating: ", true)
  else
    recordingStartTime = recordingStartTime + 1 / fps
    MM.AutomationUtil.SetProgressBarValues(currentIndex, numAuctions)
    MM.AutomationUtil.AppendProgressBarText("Archiving: ", true)
  end
end

local function throttledCalculating()
  while GetTime() - calcStartTime < 1 / fps and currentIndex <= numEnchants do
    calculateStatistics(currentIndex)
    currentIndex = currentIndex + 1
  end
  if currentIndex > numEnchants then
    MM.AutomationUtil.SetProgressBarValues(numEnchants, numEnchants)
    MM.AutomationUtil.AppendProgressBarText("Calculating: ", true)
    nilGetAllScanVariables()
    MM.AutomationManager:Inform(automationTable, "finished")
  else
    calcStartTime = calcStartTime + 1 / fps
    MM.AutomationUtil.SetProgressBarValues(currentIndex, numEnchants)
    MM.AutomationUtil.AppendProgressBarText("Calculating: ", true)
  end
end

local function getAllScan_OnUpdate()
  if collectTime and GetTime() >= collectTime then
    initRecording()
  elseif recordingStartTime then
    throttledRecording()
  end
  if calcStartTime then
    throttledCalculating()
  end
end

MM.OnUpdateFrame:HookScript("OnUpdate", getAllScan_OnUpdate)

function automationTable.PostProcessing()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "noPostProcessing")
end

function automationTable.Stop()
  nilGetAllScanVariables()
  MM.AutomationUtil.HideAutomationPopup()
  MM:CancelDisplayEnchantAuctions()
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)