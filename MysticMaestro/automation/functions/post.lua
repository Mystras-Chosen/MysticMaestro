local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Post"

local isPaused

local automationTable = {}

function automationTable.GetName()
  return automationName
end

local options

function automationTable.ShowInitPrompt()
  options = options or MM.db.realm.OPTIONS
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end

local running

local enchantScanList, sellableEnchants

local function collectSellableEnchantItems()
  sellableEnchants = MM:GetSellableREs()
  enchantScanList = {}
  for enchantID in pairs(sellableEnchants) do
    table.insert(enchantScanList, enchantID)
  end
end

local running, currentIndex, scanResultSet

function automationTable.Start()
  collectSellableEnchantItems()
  MM.AutomationUtil.SetProgressBarDisplayMode("value")
  MM.AutomationUtil.SetProgressBarMinMax(0, #enchantScanList)
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  running = true
  currentIndex = 0
  scanResultSet = {}
end

local function postScan_OnUpdate()
  if running and not MM:AwaitingSingleScanResults() then
    if currentIndex ~= 0 then
      scanResultSet[enchantScanList[currentIndex]] = MM:GetSingleScanResults()
    end
    if currentIndex < #enchantScanList and CanSendAuctionQuery() then
      currentIndex = currentIndex + 1
      MM:InitializeSingleScan(enchantScanList[currentIndex])
      MM.AutomationUtil.SetProgressBarValues(currentIndex-1, #enchantScanList)
    elseif currentIndex == #enchantScanList then
      MM.AutomationUtil.SetProgressBarValues(currentIndex, #enchantScanList)
      MM.AutomationManager:Inform(automationTable, "finished")
      running = false
    end
  end
end

MM.OnUpdateFrame:HookScript("OnUpdate", postScan_OnUpdate)

function automationTable.Stop()
  MM.AutomationUtil.HideAutomationPopup()
  running = false
end

function automationTable.PostProcessing()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "noPostProcessing")
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)