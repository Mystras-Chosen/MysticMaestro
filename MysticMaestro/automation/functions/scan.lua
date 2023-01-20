local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Scan"

local isPaused

local automationTable = {}

function automationTable.GetName()
  return automationName
end

local options

function automationTable.ShowInitPrompt()
  print("showinitprompt called")
  options = options or MM.db.realm.OPTIONS
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end

local currentIndex
local running

local enchantQueue

local scanQualityFilters = {
  { rarityLegendary = "legendary" },
  { rarityEpic = "epic" },
  { rarityRare = "rare" },
  { rarityMagic = "uncommon" }
}

local function prepareEnchantQueue()
  enchantQueue = {}
  for _, filter in ipairs(scanQualityFilters) do
    local optionKey, quality = next(filter)
    if options[optionKey] then
      local enchants = MM:GetAlphabetizedEnchantList(quality)
      for _, enchant in ipairs(enchants) do
        table.insert(enchantQueue, enchant)
      end
    end
  end
end

local currentIndex

local function handleQueueScan()
  if not isPaused then
    prepareEnchantQueue()
    currentIndex = 0
  end
  isPaused = false
  MM.AutomationUtil.SetProgressBarMinMax(0, #enchantQueue)
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  running = true
end

local function queueScan_OnUpdate()
  if running and not isPaused then
    if currentIndex < #enchantQueue and CanSendAuctionQuery() and not MM:AwaitingSingleScanResults() then
      currentIndex = currentIndex + 1
      MM:InitializeSingleScan(enchantQueue[currentIndex])
      MM.AutomationUtil.SetProgressBarValues(currentIndex-1, #enchantQueue)
    elseif currentIndex == #enchantQueue and not MM:AwaitingSingleScanResults() then
      MM.AutomationUtil.SetProgressBarValues(currentIndex, #enchantQueue)
      MM.AutomationManager:Inform(automationTable, "finished")
      running = false
      isPaused = false
    end
  end
end

-- put get all scan "private" functions here

function automationTable.Start()
  print("start called")
  handleQueueScan()
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    queueScan_OnUpdate()
  end
)

function automationTable.PostProcessing()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "noPostProcessing")
end

function automationTable.Pause()
  print("pause called")
  if running then
    isPaused = true
    MM.AutomationUtil.HideAutomationPopup()
    MM:CancelDisplayEnchantAuctions()
    currentIndex = currentIndex - 1
  else
    MM:Print("ERROR: Scan paused when not running")
  end
end

function automationTable.IsPaused()
  return isPaused
end

function automationTable.Stop()
  print("stop called")
  MM.AutomationUtil.HideAutomationPopup()
  MM:CancelDisplayEnchantAuctions()
  isPaused = false
  running = false
  lastUpdate = nil
  currentIndex = nil
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)